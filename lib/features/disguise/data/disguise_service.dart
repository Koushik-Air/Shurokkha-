import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DisguiseService {
  static const MethodChannel _channel = MethodChannel('com.shurokkha/disguise');

  Future<bool> enableDisguise() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool? success = await _channel.invokeMethod<bool>('enableDisguise');
      return success ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to enable disguise: ${e.message}");
      return false;
    }
  }

  Future<bool> disableDisguise() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool? success = await _channel.invokeMethod<bool>('disableDisguise');
      return success ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to disable disguise: ${e.message}");
      return false;
    }
  }

  Future<bool> isDisguiseEnabled() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool? enabled = await _channel.invokeMethod<bool>('isDisguiseEnabled');
      return enabled ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to check disguise status: ${e.message}");
      return false;
    }
  }
}

final disguiseServiceProvider = Provider<DisguiseService>((ref) {
  return DisguiseService();
});
