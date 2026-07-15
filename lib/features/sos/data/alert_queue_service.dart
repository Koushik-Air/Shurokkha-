import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class AlertPayload {
  @HiveField(0)
  final List<String> recipients;

  @HiveField(1)
  final String message;

  @HiveField(2)
  final DateTime queuedAt;

  AlertPayload({
    required this.recipients,
    required this.message,
    required this.queuedAt,
  });
}

class AlertPayloadAdapter extends TypeAdapter<AlertPayload> {
  @override
  final int typeId = 1;

  @override
  AlertPayload read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlertPayload(
      recipients: List<String>.from(fields[0] ?? []),
      message: fields[1] as String,
      queuedAt: DateTime.parse(fields[2] as String),
    );
  }

  @override
  void write(BinaryWriter writer, AlertPayload obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.recipients)
      ..writeByte(1)
      ..write(obj.message)
      ..writeByte(2)
      ..write(obj.queuedAt.toIso8601String());
  }
}

class AlertQueueService {
  static const String _boxName = 'pending_alerts';

  Future<void> enqueue(AlertPayload payload) async {
    final box = await Hive.openBox<AlertPayload>(_boxName);
    await box.add(payload);
  }

  Future<List<AlertPayload>> dequeueAll() async {
    final box = await Hive.openBox<AlertPayload>(_boxName);
    final list = box.values.toList();
    return list;
  }

  Future<void> clearAll() async {
    final box = await Hive.openBox<AlertPayload>(_boxName);
    await box.clear();
  }
}
