import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:telephony/telephony.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/connectivity_service.dart';
import 'alert_queue_service.dart';

class SmsService {
  final Telephony? _telephony = Platform.isAndroid ? Telephony.instance : null;
  final ConnectivityService _connectivityService = ConnectivityService();
  final AlertQueueService _alertQueueService = AlertQueueService();

  Future<bool> requestPermissions() async {
    final telephony = _telephony;
    if (Platform.isAndroid && telephony != null) {
      final status = await telephony.requestPhoneAndSmsPermissions;
      return status ?? false;
    }
    return true;
  }

  Future<void> sendSmsAlert({
    required List<String> recipients,
    required String message,
  }) async {
    if (recipients.isEmpty) return;

    // Check connectivity first
    final isConnected = await _connectivityService.isConnected();
    if (!isConnected) {
      debugPrint("Offline. Enqueuing SMS alert for later transmission.");
      await _alertQueueService.enqueue(AlertPayload(
        recipients: recipients,
        message: message,
        queuedAt: DateTime.now(),
      ));
      return;
    }

    final telephony = _telephony;
    if (Platform.isAndroid && telephony != null) {
      final permissionGranted = await telephony.requestPhoneAndSmsPermissions;
      if (permissionGranted == true) {
        for (final recipient in recipients) {
          try {
            await telephony.sendSms(
              to: recipient,
              message: message,
            );
            debugPrint("Direct background SMS sent successfully to $recipient");
          } catch (e) {
            debugPrint("Failed to send silent SMS to $recipient: $e");
            await _fallbackToUrlLauncher(recipient, message);
          }
        }
      } else {
        // Fallback to url_launcher if permission denied
        for (final recipient in recipients) {
          await _fallbackToUrlLauncher(recipient, message);
        }
      }
    } else {
      // iOS doesn't support background/silent SMS
      for (final recipient in recipients) {
        await _fallbackToUrlLauncher(recipient, message);
      }
    }
  }

  Future<void> retryPendingAlerts() async {
    final isConnected = await _connectivityService.isConnected();
    if (!isConnected) return;

    final pending = await _alertQueueService.dequeueAll();
    if (pending.isEmpty) return;

    debugPrint("Reconnected. Retrying ${pending.length} pending SMS alerts.");
    await _alertQueueService.clearAll();

    for (final payload in pending) {
      // Re-send each enqueued alert
      await sendSmsAlert(
        recipients: payload.recipients,
        message: payload.message,
      );
    }
  }

  Future<void> _fallbackToUrlLauncher(String recipient, String message) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: recipient,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      debugPrint("Could not launch SMS compose window for $recipient");
    }
  }
}
