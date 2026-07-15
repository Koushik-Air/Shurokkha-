import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';

class AudioRecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _localPath;
  static const String _pendingUploadsBox = 'pending_audio_uploads';

  Future<void> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        _localPath = '${directory.path}/sos_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: _localPath!,
        );
        debugPrint("Recording started at: $_localPath");
      }
    } catch (e) {
      debugPrint("Failed to start audio recording: $e");
    }
  }

  Future<String?> stopRecordingAndUpload({
    required String userId,
    required String eventId,
  }) async {
    try {
      final path = await _audioRecorder.stop();
      if (path == null || _localPath == null) return null;

      final file = File(_localPath!);
      if (!await file.exists()) return null;

      // Try uploading to Firebase Storage
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('users')
            .child(userId)
            .child('sos_recordings')
            .child('$eventId.m4a');

        final uploadTask = ref.putFile(file);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        
        debugPrint("Audio upload completed. URL: $downloadUrl");
        return downloadUrl;
      } catch (e) {
        debugPrint("Upload failed, enqueuing audio file for retry: $e");
        final box = await Hive.openBox(_pendingUploadsBox);
        await box.add({
          'userId': userId,
          'eventId': eventId,
          'filePath': _localPath,
        });
        return null;
      }
    } catch (e) {
      debugPrint("Failed to stop recording: $e");
      return null;
    }
  }

  Future<void> retryPendingAudioUploads() async {
    try {
      final box = await Hive.openBox(_pendingUploadsBox);
      if (box.isEmpty) return;

      debugPrint("Reconnected. Retrying ${box.length} pending audio uploads.");
      final keys = List.from(box.keys);

      for (final key in keys) {
        final data = box.get(key) as Map?;
        if (data == null) continue;

        final userId = data['userId'] as String?;
        final eventId = data['eventId'] as String?;
        final filePath = data['filePath'] as String?;

        if (userId != null && eventId != null && filePath != null) {
          final file = File(filePath);
          if (await file.exists()) {
            final ref = FirebaseStorage.instance
                .ref()
                .child('users')
                .child(userId)
                .child('sos_recordings')
                .child('$eventId.m4a');

            await ref.putFile(file);
            final downloadUrl = await ref.getDownloadURL();

            // Update Firestore document with audioUrl
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('sos_events')
                .doc(eventId)
                .update({'audioUrl': downloadUrl});

            debugPrint("Delayed audio upload completed for event $eventId");
            await box.delete(key);
          } else {
            // Local file doesn't exist, remove invalid entry
            await box.delete(key);
          }
        }
      }
    } catch (e) {
      debugPrint("Error retrying pending audio uploads: $e");
    }
  }
}
