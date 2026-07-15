import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../domain/safe_place_model.dart';

class PlacesRepository {
  static const String _boxName = 'safe_places_cache';

  Future<List<SafePlace>> getNearbySafePlaces({
    required double latitude,
    required double longitude,
    String? apiKey,
  }) async {
    final box = await Hive.openBox<SafePlace>(_boxName);

    if (apiKey == null || apiKey.isEmpty) {
      debugPrint("No API Key provided. Returning cached/mock locations.");
      if (box.isNotEmpty) {
        return box.values.toList();
      }
      // Populate defaults (e.g. Dhaka main offices / centers as default mocks)
      final mocks = [
        SafePlace(
          id: '1',
          name: 'Tejgaon Police Station',
          type: 'Police Station',
          latitude: 23.7594,
          longitude: 90.3995,
          address: 'Tejgaon, Dhaka',
        ),
        SafePlace(
          id: '2',
          name: 'Dhaka Medical College Hospital',
          type: 'Hospital',
          latitude: 23.7258,
          longitude: 90.3976,
          address: 'Ramna, Dhaka',
        ),
        SafePlace(
          id: '3',
          name: 'Women Support & Investigation Division',
          type: 'Support Center',
          latitude: 23.7516,
          longitude: 90.4143,
          address: 'Tejgaon, Dhaka',
        ),
      ];
      await box.putAll({for (var place in mocks) place.id: place});
      return mocks;
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$latitude,$longitude'
        '&radius=3000'
        '&type=police|hospital'
        '&key=$apiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        final List<SafePlace> places = [];

        for (final item in results) {
          final loc = item['geometry']['location'];
          final place = SafePlace(
            id: item['place_id'] ?? '',
            name: item['name'] ?? '',
            type: (item['types'] as List).contains('police') ? 'Police Station' : 'Hospital',
            latitude: (loc['lat'] as num).toDouble(),
            longitude: (loc['lng'] as num).toDouble(),
            address: item['vicinity'] ?? '',
          );
          places.add(place);
        }

        // Cache locally
        await box.clear();
        await box.putAll({for (var place in places) place.id: place});
        return places;
      }
    } catch (e) {
      debugPrint("Failed to fetch places from Google API: $e");
    }

    return box.values.toList();
  }
}
