import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../contacts/data/contact_repository.dart';
import '../../contacts/presentation/contact_setup_screen.dart';
import '../../auth/data/auth_repository.dart';
import '../../settings/data/settings_repository.dart';
import '../../settings/presentation/settings_screen.dart';
import '../domain/sos_event_model.dart';
import '../data/location_service.dart';
import '../data/sms_service.dart';
import '../data/audio_recorder_service.dart';
import '../data/volume_trigger_service.dart';
import 'sos_countdown_overlay.dart';
import 'sos_history_screen.dart';
import '../../map/presentation/nearby_places_screen.dart';
import 'package:shurokkha/core/localization/l10n/app_localizations.dart';

class SosButtonScreen extends ConsumerStatefulWidget {
  const SosButtonScreen({super.key});

  @override
  ConsumerState<SosButtonScreen> createState() => _SosButtonScreenState();
}

class _SosButtonScreenState extends ConsumerState<SosButtonScreen> with TickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  final SmsService _smsService = SmsService();
  final AudioRecorderService _audioRecorderService = AudioRecorderService();

  bool _isCountingDown = false;
  bool _isSosActive = false;
  String? _currentEventId;
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<UserAccelerometerEvent>? _sensorSubscription;

  late AnimationController _pulseController;
  late AnimationController _flashController;

  @override
  void initState() {
    super.initState();
    _startShakeDetection();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _sensorSubscription?.cancel();
    _pulseController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  void _startShakeDetection() {
    _sensorSubscription = userAccelerometerEventStream().listen((event) {
      final force = event.x * event.x + event.y * event.y + event.z * event.z;
      if (force > 200) {
        if (!_isSosActive && !_isCountingDown) {
          final contacts = ref.read(contactsStreamProvider).value ?? [];
          if (contacts.isNotEmpty) {
            setState(() {
              _isCountingDown = true;
            });
          }
        }
      }
    });
  }

  Future<void> _triggerSos() async {
    final eventId = const Uuid().v4();
    setState(() {
      _isCountingDown = false;
      _isSosActive = true;
      _currentEventId = eventId;
    });

    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final hasLocPermission = await _locationService.handlePermission();
    if (!hasLocPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required for SOS')),
        );
      }
      return;
    }

    try {
      await _audioRecorderService.startRecording();

      final position = await _locationService.getCurrentLocation();
      final mapsLink = "https://maps.google.com/?q=${position.latitude},${position.longitude}";

      final settings = await ref.read(settingsRepositoryProvider).getSettings();
      final template = settings.customSosMessage;
      String message = template;
      if (template.contains('{link}')) {
        message = template.replaceAll('{link}', mapsLink);
      } else {
        message = "$template $mapsLink";
      }

      final contacts = ref.read(contactsStreamProvider).value ?? [];
      final recipients = contacts.map((c) => c.phoneNumber).toList();

      final event = SosEvent(
        id: eventId,
        userId: user.uid,
        status: SosEvent.kStatusActive,
        startedAt: DateTime.now(),
        contactsNotified: recipients,
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sos_events')
          .doc(eventId)
          .set(event.toMap());

      await _smsService.sendSmsAlert(
        recipients: recipients,
        message: message,
      );

      _locationSubscription = _locationService.getLocationStream().listen((pos) async {
        if (_currentEventId != null) {
          await _locationService.updateLiveLocation(
            userId: user.uid,
            eventId: _currentEventId!,
            latitude: pos.latitude,
            longitude: pos.longitude,
          );
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.sosAlertSent),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error triggering SOS: $e");
    }
  }

  Future<void> _cancelSos() async {
    _locationSubscription?.cancel();
    final eventId = _currentEventId;
    final user = ref.read(authStateProvider).value;

    setState(() {
      _isCountingDown = false;
      _isSosActive = false;
      _currentEventId = null;
    });

    if (eventId != null && user != null) {
      final audioUrl = await _audioRecorderService.stopRecordingAndUpload(
        userId: user.uid,
        eventId: eventId,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sos_events')
          .doc(eventId)
          .update({
        'status': SosEvent.kStatusCancelled,
        'endedAt': DateTime.now().toIso8601String(),
        'audioUrl': audioUrl,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to native volume button trigger events
    ref.listen(volumeTriggerStreamProvider, (previous, next) async {
      final settings = await ref.read(settingsRepositoryProvider).getSettings();
      if (settings.isVolumeTriggerEnabled && !_isSosActive && !_isCountingDown) {
        final contacts = ref.read(contactsStreamProvider).value ?? [];
        if (contacts.isNotEmpty) {
          setState(() {
            _isCountingDown = true;
          });
        }
      }
    });

    final contactsState = ref.watch(contactsStreamProvider);
    final l10n = AppLocalizations.of(context)!;

    if (_isCountingDown) {
      return SosCountdownOverlay(
        onTrigger: _triggerSos,
        onCancel: _cancelSos,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SosHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NearbyPlacesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ContactSetupScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authRepositoryProvider).signOut();
            },
          ),
        ],
      ),
      body: contactsState.when(
        data: (contacts) {
          final isArmed = contacts.isNotEmpty;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isArmed) ...[
                  const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      'SOS is disarmed. Please add at least 1 emergency contact to enable emergency triggers.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ContactSetupScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Configure Contacts'),
                  ),
                ] else ...[
                  Text(
                    _isSosActive ? "SOS ACTIVE" : "SYSTEM ARMED",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _isSosActive ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 48),
                  GestureDetector(
                    onLongPress: () {
                      setState(() {
                        _isCountingDown = true;
                      });
                    },
                    child: AnimatedBuilder(
                      animation: _isSosActive ? _flashController : _pulseController,
                      builder: (context, child) {
                        final val = _isSosActive ? _flashController.value : _pulseController.value;
                        final pulseRadius = _isSosActive ? (10.0 + val * 30.0) : (10.0 + val * 15.0);
                        final blurRadius = _isSosActive ? (20.0 + val * 40.0) : (20.0 + val * 20.0);
                        final flashColor = _isSosActive
                            ? Color.lerp(Colors.red, Colors.black, val)!
                            : Colors.red;

                        return Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: flashColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.5),
                                spreadRadius: pulseRadius,
                                blurRadius: blurRadius,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              l10n.sosButtonLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.sosButtonSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  if (_isSosActive) ...[
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _cancelSos,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: const Text('STOP SOS ALERT'),
                    ),
                  ]
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loaded: $e')),
      ),
    );
  }
}
