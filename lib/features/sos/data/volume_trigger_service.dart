import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VolumeTriggerService {
  static const MethodChannel _channel = MethodChannel('com.shurokkha/trigger');
  final _controller = StreamController<void>.broadcast();

  VolumeTriggerService() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'volumeTrigger') {
        _controller.add(null);
      }
    });
  }

  Stream<void> get onVolumeTrigger => _controller.stream;
}

final volumeTriggerServiceProvider = Provider<VolumeTriggerService>((ref) {
  return VolumeTriggerService();
});

final volumeTriggerStreamProvider = StreamProvider<void>((ref) {
  return ref.watch(volumeTriggerServiceProvider).onVolumeTrigger;
});
