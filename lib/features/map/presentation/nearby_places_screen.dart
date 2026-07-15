import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/places_repository.dart';
import '../domain/safe_place_model.dart';
import 'package:shurokkha/core/localization/l10n/app_localizations.dart';

class NearbyPlacesScreen extends StatefulWidget {
  const NearbyPlacesScreen({super.key});

  @override
  State<NearbyPlacesScreen> createState() => _NearbyPlacesScreenState();
}

class _NearbyPlacesScreenState extends State<NearbyPlacesScreen> {
  final PlacesRepository _placesRepository = PlacesRepository();
  LatLng _currentLatLng = const LatLng(23.7594, 90.3995); // Default Dhaka
  List<SafePlace> _safePlaces = [];
  bool _isLoading = true;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocationAndPlaces();
  }

  Future<void> _fetchCurrentLocationAndPlaces() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentLatLng = LatLng(position.latitude, position.longitude);
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(_currentLatLng),
        );
      }
    } catch (e) {
      debugPrint("Failed to get location, using default coords: $e");
    }

    try {
      final places = await _placesRepository.getNearbySafePlaces(
        latitude: _currentLatLng.latitude,
        longitude: _currentLatLng.longitude,
      );
      if (mounted) {
        setState(() {
          _safePlaces = places;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.nearbySafePlaces),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  flex: 3,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentLatLng,
                      zoom: 14.0,
                    ),
                    myLocationEnabled: true,
                    onMapCreated: (controller) => _mapController = controller,
                    markers: _safePlaces.map((place) {
                      return Marker(
                        markerId: MarkerId(place.id),
                        position: LatLng(place.latitude, place.longitude),
                        infoWindow: InfoWindow(
                          title: place.name,
                          snippet: '${place.type} • ${place.address}',
                        ),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          place.type == 'Police Station'
                              ? BitmapDescriptor.hueBlue
                              : BitmapDescriptor.hueRed,
                        ),
                      );
                    }).toSet(),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: ListView.builder(
                    itemCount: _safePlaces.length,
                    itemBuilder: (context, index) {
                      final place = _safePlaces[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: place.type == 'Police Station'
                              ? Colors.blue.shade100
                              : Colors.red.shade100,
                          child: Icon(
                            place.type == 'Police Station'
                                ? Icons.local_police
                                : Icons.local_hospital,
                            color: place.type == 'Police Station' ? Colors.blue : Colors.red,
                          ),
                        ),
                        title: Text(place.name),
                        subtitle: Text(place.address),
                        trailing: IconButton(
                          icon: const Icon(Icons.directions, color: Colors.green),
                          onPressed: () async {
                            final lat = place.latitude;
                            final lng = place.longitude;
                            final urlString = Platform.isAndroid
                                ? 'geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(place.name)})'
                                : 'https://maps.apple.com/?daddr=$lat,$lng&q=${Uri.encodeComponent(place.name)}';

                            final uri = Uri.parse(urlString);
                            final fallbackUri = Uri.parse('https://maps.google.com/maps?daddr=$lat,$lng');

                            try {
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              } else if (await canLaunchUrl(fallbackUri)) {
                                await launchUrl(fallbackUri);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Could not open map navigation for ${place.name}')),
                                  );
                                }
                              }
                            } catch (e) {
                              if (await canLaunchUrl(fallbackUri)) {
                                await launchUrl(fallbackUri);
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
