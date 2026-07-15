import 'package:hive/hive.dart';

part 'safe_place_model.g.dart';

@HiveType(typeId: 0)
class SafePlace {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String type; // Police Station, Hospital, support center
  @HiveField(3)
  final double latitude;
  @HiveField(4)
  final double longitude;
  @HiveField(5)
  final String address;

  SafePlace({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      };

  factory SafePlace.fromMap(Map<String, dynamic> map) => SafePlace(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        type: map['type'] ?? '',
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        address: map['address'] ?? '',
      );
}
