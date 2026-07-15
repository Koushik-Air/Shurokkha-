import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shurokkha/core/localization/l10n/app_localizations.dart';
import 'package:shurokkha/core/theme/app_theme.dart';
import 'package:shurokkha/core/storage/secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/sos/presentation/sos_button_screen.dart';
import 'features/map/domain/safe_place_model.dart';
import 'features/disguise/presentation/calculator_disguise_screen.dart';
import 'features/settings/data/settings_repository.dart';
import 'features/sos/data/alert_queue_service.dart';
import 'features/sos/data/sms_service.dart';
import 'features/sos/data/audio_recorder_service.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'core/network/connectivity_service.dart';

// Notifier providers for live settings changes
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));
final onboardingCompleteProvider = StateProvider<bool>((ref) => false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(SafePlaceAdapter());
  Hive.registerAdapter(AlertPayloadAdapter());

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialization skipped or failed: $e");
  }

  // Load preferences before running app
  final secureStorage = SecureStorageService();
  final settingsRepo = SettingsRepository();
  final settings = await settingsRepo.getSettings();
  final onboardingDone = await secureStorage.read('onboarding_complete') == 'true';

  runApp(
    ProviderScope(
      overrides: [
        // Initialize providers with loaded states
        themeModeProvider.overrideWith((ref) => settings.isDarkMode ? ThemeMode.dark : ThemeMode.light),
        localeProvider.overrideWith((ref) => Locale(settings.locale)),
        onboardingCompleteProvider.overrideWith((ref) => onboardingDone),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  StreamSubscription<bool>? _connectivitySubscription;
  final SmsService _smsService = SmsService();
  final AudioRecorderService _audioRecorderService = AudioRecorderService();

  @override
  void initState() {
    super.initState();
    // Listen for connectivity changes to retry pending alerts and audio uploads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectivitySubscription = ref.read(connectivityServiceProvider)
          .onConnectivityChanged
          .listen((isConnected) {
        if (isConnected) {
          _smsService.retryPendingAlerts();
          _audioRecorderService.retryPendingAudioUploads();
        }
      });
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final onboardingComplete = ref.watch(onboardingCompleteProvider);

    Widget homeWidget;
    if (!onboardingComplete) {
      homeWidget = OnboardingScreen(
        onComplete: () {
          ref.read(onboardingCompleteProvider.notifier).state = true;
        },
      );
    } else {
      homeWidget = authState.when(
        data: (user) {
          final target = user != null ? const SosButtonScreen() : const LoginScreen();
          return CalculatorDisguiseScreen(child: target);
        },
        loading: () => const CalculatorDisguiseScreen(
          child: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        ),
        error: (err, stack) => Scaffold(
          body: Center(child: Text('Initialization Error: $err')),
        ),
      );
    }

    return MaterialApp(
      title: 'Shurokkha',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('bn'),
      ],
      home: homeWidget,
    );
  }
}
