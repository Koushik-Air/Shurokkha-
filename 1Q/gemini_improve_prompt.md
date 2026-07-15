# Shurokkha — Improvement Prompt for Gemini Flash 3.5

## How to use this prompt

1. Paste the entire block under **"THE PROMPT"** as your first message to Gemini Flash 3.5.
2. It will reply with a phased plan — **review it** before continuing.
3. Reply `continue phase N` to generate one phase's code at a time.
4. Each phase produces complete, copy-paste-ready files.

---

## THE PROMPT

```
ROLE
You are a senior Flutter/Dart engineer, UX designer, and mobile platform
specialist. You are improving an existing production Flutter safety app called
"Shurokkha" (সুরক্ষা) — a women's personal safety / SOS emergency app targeting
Bangladesh. The app already has working core functionality. Your job is to add
the missing advanced features, polish the UI/UX, and harden it for real-world use.

---

CODEBASE CONTEXT

Package name: com.shurokkha.shurokkha
Flutter SDK: >=3.0.0 <4.0.0
State management: Riverpod (flutter_riverpod ^2.5.1)
Architecture: Clean architecture — presentation / domain / data per feature
Localization: flutter_localizations + intl, ARB files at lib/core/localization/l10n/
l10n.yaml: arb-dir: lib/core/localization/l10n, template: app_en.arb, output-class: AppLocalizations

Current pubspec.yaml dependencies:
  flutter, flutter_localizations, intl, cupertino_icons,
  flutter_riverpod, riverpod_annotation,
  firebase_core, firebase_auth, cloud_firestore, firebase_storage,
  flutter_secure_storage, hive_flutter, hive, path_provider,
  geolocator, google_maps_flutter, http,
  sensors_plus, record, connectivity_plus, url_launcher, uuid,
  telephony, flutter_contacts

Current file tree:
  lib/main.dart
  lib/core/localization/l10n/app_en.arb
  lib/core/localization/l10n/app_bn.arb
  lib/core/localization/l10n/app_localizations.dart       (generated)
  lib/core/localization/l10n/app_localizations_en.dart     (generated)
  lib/core/localization/l10n/app_localizations_bn.dart     (generated)
  lib/core/network/connectivity_service.dart
  lib/core/storage/secure_storage.dart
  lib/features/auth/data/auth_repository.dart
  lib/features/auth/domain/user_model.dart
  lib/features/auth/presentation/login_screen.dart
  lib/features/contacts/data/contact_repository.dart
  lib/features/contacts/domain/contact_model.dart
  lib/features/contacts/presentation/contact_setup_screen.dart
  lib/features/disguise/presentation/calculator_disguise_screen.dart
  lib/features/map/data/places_repository.dart
  lib/features/map/domain/safe_place_model.dart
  lib/features/map/domain/safe_place_model.g.dart          (generated — do not touch)
  lib/features/map/presentation/nearby_places_screen.dart
  lib/features/settings/data/settings_repository.dart
  lib/features/settings/domain/app_settings_model.dart
  lib/features/settings/presentation/settings_screen.dart
  lib/features/sos/data/alert_queue_service.dart
  lib/features/sos/data/audio_recorder_service.dart
  lib/features/sos/data/location_service.dart
  lib/features/sos/data/sms_service.dart
  lib/features/sos/domain/sos_event_model.dart
  lib/features/sos/presentation/sos_button_screen.dart
  lib/features/sos/presentation/sos_countdown_overlay.dart
  android/app/src/main/AndroidManifest.xml
  android/app/src/main/kotlin/com/shurokkha/shurokkha/MainActivity.kt

---

WHAT ALREADY WORKS (do not break these)

1. Firebase Auth (email + phone OTP), with validation and forgot-password
2. Calculator disguise gatekeeper with working arithmetic and SecureStorage PIN
3. SOS button with 3-second cancelable countdown
4. Shake-to-trigger via sensors_plus
5. Contact CRUD (Firestore) + device phonebook picker via flutter_contacts
6. SosEvent Firestore logging (active/cancelled status, timestamps, audio URL)
7. Location stream → Firestore live tracking during SOS
8. SMS dispatch (Android telephony + iOS url_launcher fallback)
9. Offline alert queue with connectivity-based auto-retry (Hive)
10. Nearby safe places map (Google Maps + Places API + Hive cache)
11. Settings screen (custom SOS message, PIN change, recording consent notice)
12. Bengali + English localization
13. Android activity-alias launcher entries (Shurokkha and Calculator aliases declared in manifest)
14. Permission rationale bottom sheet shown once before sign-up

---

WHAT IS MISSING — IMPROVEMENT PLAN

Below are the improvements to implement, grouped into phases. Each phase should
fit within one response. Output FULL, ready-to-paste file contents preceded by:
// FILE: path/to/file.dart
Do NOT output partial snippets or "... rest unchanged" comments.
Wait for "continue phase N" before writing code.

==========================================================================
PHASE 1 — Dark Mode + Theme System + UI Polish
==========================================================================

Files to output:
- lib/core/theme/app_theme.dart [NEW]
  * Create a ThemeData factory class with two static methods:
    lightTheme() and darkTheme()
  * Light theme: background white, primary Colors.redAccent, accent orange,
    card elevation with subtle shadows, rounded corners on all inputs/buttons
  * Dark theme: background Color(0xFF121212), surface Color(0xFF1E1E1E),
    primary redAccent, accent orange, card white10, text white
  * Both themes should use Google Fonts 'Inter' for all text (add google_fonts
    to pubspec.yaml)
  * Use Material 3 design tokens (useMaterial3: true)

- lib/features/settings/presentation/settings_screen.dart (REPLACE)
  * Add a SwitchListTile for "Dark Mode" toggle at the top of the settings page
  * Store the preference in SecureStorage (key: 'dark_mode', values: 'true'/'false')
  * Add a DropdownButton for language selection (English / বাংলা)
  * Store language preference in SecureStorage (key: 'locale', values: 'en'/'bn')

- lib/features/settings/data/settings_repository.dart (REPLACE)
  * Add fields to AppSettings: isDarkMode (bool), locale (String)
  * Add SecureStorage keys and getters/setters for the new fields
  * Update settingsFutureProvider accordingly

- lib/features/settings/domain/app_settings_model.dart (REPLACE)
  * Add isDarkMode and locale fields

- lib/main.dart (REPLACE)
  * Read dark mode and locale preferences at startup using settingsRepository
  * Apply the correct ThemeData based on the preference
  * Apply the correct Locale based on the preference
  * Create a Riverpod StateNotifierProvider<ThemeNotifier, ThemeMode> and
    a StateNotifierProvider<LocaleNotifier, Locale> so that toggling the switch
    or dropdown in settings live-updates the app without a restart

- lib/features/disguise/presentation/calculator_disguise_screen.dart (REPLACE)
  * Make the calculator respect the current theme (dark background in dark mode,
    operator buttons use theme accent color, display text uses theme text color)
  * Keep the same arithmetic engine and PIN logic — only change colors/styling

- pubspec.yaml
  * Add: google_fonts: ^6.2.0

- lib/core/localization/l10n/app_en.arb (ADD new keys, keep all existing)
  New keys: darkMode, language, selectLanguage, sosHistory, eventHistory,
  noEventsYet, statusActive, statusCancelled, statusResolved,
  eventStarted, eventEnded, audioRecording, viewOnMap, enableDisguise,
  disguiseMode, volumeTrigger, volumeTriggerDesc

- lib/core/localization/l10n/app_bn.arb (ADD same new keys in Bengali)

==========================================================================
PHASE 2 — SOS Event History Screen
==========================================================================

Files to output:
- lib/features/sos/presentation/sos_history_screen.dart [NEW]
  * A full-screen page showing a reverse-chronological list of past SosEvent
    documents fetched from Firestore: users/{userId}/sos_events
  * Each item shows:
    - Status badge (colored chip: green=active, orange=cancelled, blue=resolved)
    - startedAt formatted as "dd MMM yyyy, HH:mm"
    - endedAt if present
    - Number of contacts notified
    - Tap to expand: show full contact list, audio URL link (tappable to open),
      and a "View on Map" button that opens the last known lat/lng in Google Maps
  * Empty state: centered icon + text "No SOS events recorded yet."
  * Use Riverpod StreamProvider to listen to the collection in real time

- lib/features/sos/data/sos_event_repository.dart [NEW]
  * Methods: getSosEventsStream(userId) → Stream<List<SosEvent>>,
    updateEventStatus(userId, eventId, status) → Future<void>
  * Riverpod providers: sosEventRepositoryProvider, sosEventsStreamProvider

- lib/features/sos/presentation/sos_button_screen.dart (REPLACE)
  * Add a "History" icon button (Icons.history) to the AppBar that navigates
    to SosHistoryScreen

==========================================================================
PHASE 3 — Android Volume-Button Silent Trigger (Platform Channel)
==========================================================================

Files to output:
- android/app/src/main/kotlin/com/shurokkha/shurokkha/MainActivity.kt (REPLACE)
  * Override dispatchKeyEvent() to detect rapid volume-down presses
  * Track timestamps of volume-down key events in a mutable list
  * If 3 volume-down presses occur within 2 seconds, invoke a Flutter
    MethodChannel call: "com.shurokkha/trigger" → method "volumeTrigger"
  * After firing, clear the timestamp list and set a 5-second cooldown to
    prevent duplicate triggers
  * Register the MethodChannel in configureFlutterEngine()

- lib/features/sos/data/volume_trigger_service.dart [NEW]
  * A Dart class that sets up a MethodChannel listener for "volumeTrigger"
  * Exposes a Stream<void> that emits when the native side fires the trigger
  * Provides a Riverpod provider: volumeTriggerProvider

- lib/features/sos/presentation/sos_button_screen.dart (REPLACE)
  * In initState(), subscribe to volumeTriggerProvider's stream
  * When a volumeTrigger event arrives and the system is armed (contacts exist)
    and not already active/counting down, set _isCountingDown = true
  * Dispose the subscription in dispose()

- lib/features/settings/presentation/settings_screen.dart (REPLACE)
  * Add a SwitchListTile "Volume Button Trigger" with a subtitle explaining
    "Press volume-down 3 times rapidly to trigger SOS"
  * Store preference in SecureStorage (key: 'volume_trigger_enabled')
  * The volume trigger in sos_button_screen should check this preference
    before activating

==========================================================================
PHASE 4 — Launcher Icon Swap (Android Platform Channel)
==========================================================================

Files to output:
- lib/features/disguise/data/disguise_service.dart [NEW]
  * A class that uses a MethodChannel ("com.shurokkha/disguise") to call
    native Android methods:
    - enableDisguise(): swaps the launcher alias from .MainActivityAlias to
      .CalculatorAlias (disabling one, enabling the other via PackageManager)
    - disableDisguise(): swaps back to .MainActivityAlias
    - isDisguiseEnabled(): returns current state
  * Provides a Riverpod provider

- android/app/src/main/kotlin/com/shurokkha/shurokkha/MainActivity.kt (REPLACE)
  * Add a second MethodChannel "com.shurokkha/disguise" in configureFlutterEngine
  * Implement enableDisguise / disableDisguise / isDisguiseEnabled handlers
    using PackageManager.setComponentEnabledSetting() to toggle the
    activity-alias entries already declared in the manifest
  * Keep the volume-button detection from Phase 3

- lib/features/settings/presentation/settings_screen.dart (REPLACE)
  * Add a SwitchListTile "Disguise Mode" with subtitle: "Show app as Calculator
    on home screen (Android only)"
  * On toggle: call disguiseService.enableDisguise() or disableDisguise()
  * Show a SnackBar warning: "The app will briefly disappear from your home
    screen and reappear as Calculator. You may need to re-add it to your
    home screen."
  * On iOS: show the switch as disabled with tooltip "Not available on iOS"
  * Store preference in SecureStorage (key: 'disguise_enabled')

==========================================================================
PHASE 5 — Countdown Animation + SOS Button Pulse Animation
==========================================================================

Files to output:
- lib/features/sos/presentation/sos_countdown_overlay.dart (REPLACE)
  * Add a circular countdown animation using AnimationController +
    CustomPainter that draws a shrinking arc around the warning icon
  * The arc should be red, starting at full circle and depleting clockwise
    over 3 seconds
  * The countdown number should scale-animate (briefly grow larger) on each
    tick using a TweenSequence
  * Add a subtle pulsing red vignette effect on the black background
  * Add haptic feedback (HapticFeedback.heavyImpact()) on each countdown tick

- lib/features/sos/presentation/sos_button_screen.dart (REPLACE)
  * Add a pulsing glow animation on the SOS button when the system is armed:
    - Use AnimationController with repeat(reverse: true), duration 1.5s
    - Animate the boxShadow spreadRadius from 10 to 25 and blurRadius
      from 20 to 40, using redAccent color
    - The button should feel "alive" — breathing in and out
  * When SOS is active, the button should have a rapid red-to-black flash
    animation instead of the slow pulse
  * Keep all existing functionality (settings, history, contacts, map nav,
    volume trigger, shake trigger, SOS workflow)

==========================================================================
PHASE 6 — Audio Upload Retry + Onboarding Flow
==========================================================================

Files to output:
- lib/features/sos/data/audio_recorder_service.dart (REPLACE)
  * After stopRecordingAndUpload(): if the upload fails due to connectivity,
    store the local file path and metadata (userId, eventId) in Hive
    (box: 'pending_audio_uploads')
  * Add a retryPendingAudioUploads() method that checks Hive for pending
    uploads and attempts each one, removing successful entries
  * The connectivity listener in main.dart should also call
    retryPendingAudioUploads() alongside retryPendingAlerts()

- lib/features/onboarding/presentation/onboarding_screen.dart [NEW]
  * A 3-page PageView onboarding walkthrough:
    Page 1: "Welcome to Shurokkha" — shield icon, brief description of the app
    Page 2: "How it works" — icons showing: SOS button, shake trigger, volume
      trigger, with one-line descriptions
    Page 3: "Stay Safe" — explanation that the app disguises as a calculator,
      with a "Get Started" button
  * Each page should have a dot indicator at the bottom and a "Skip" button
  * On completion, store 'onboarding_complete' = 'true' in SecureStorage
  * Use smooth page transition animations

- lib/main.dart (REPLACE)
  * Check SecureStorage for 'onboarding_complete' before showing the main app
  * If not complete, show OnboardingScreen first; on completion, navigate
    to the calculator disguise / auth flow
  * Keep dark mode, locale, and connectivity retry logic from previous phases

- lib/main.dart: also call audioRecorderService.retryPendingAudioUploads()
  in the connectivity listener alongside smsService.retryPendingAlerts()

---

OUTPUT FORMAT RULES
1. Precede every file with: // FILE: path/to/file.dart (exact project-relative path)
2. Output the FULL file content — never partial snippets or "... unchanged" comments
3. Add concise inline comments for non-obvious logic
4. At the end of Phase 6, output:
   - A VERIFICATION CHECKLIST:
     * flutter pub get
     * flutter gen-l10n
     * List any new runtime secrets or configs needed
   - An updated summary of ALL features now available in the app

START
Respond with your phased plan (phase titles, files changed per phase, one
sentence per phase describing what it adds). Do NOT write any code yet.
Wait for "continue phase 1" to begin.
```
