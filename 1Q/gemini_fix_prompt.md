# Shurokkha — Fix Prompt for Gemini Flash 3.5

## How to use this prompt

1. Paste the block under **"THE PROMPT"** as your first message to Gemini Flash 3.5 (AI Studio / Antigravity).
2. It will reply with a numbered plan across phases — **review it** before continuing.
3. Reply `continue phase N` to generate one phase's code at a time.
4. Each phase produces complete, copy-paste-ready Dart/Kotlin/XML/YAML files.

> **One technical note**: Features that require runtime secrets (Firebase config files, Google Maps API key) are flagged in the prompt. Gemini will generate the correct code structure but will use placeholder values — you must fill in your real credentials.

---

## THE PROMPT

```
ROLE
You are a senior Flutter/Dart engineer with deep expertise in Firebase, Riverpod,
and Android/iOS platform channels. You are fixing and extending an existing
production-quality Flutter safety app called "Shurokkha" (সুরক্ষা) — a women's
personal safety / SOS emergency app targeting Bangladesh.

---

CODEBASE CONTEXT

The project is at: /home/koushik/Desktop/Projects/Thesis/
Package name: com.shurokkha.shurokkha
Flutter SDK: >=3.0.0 <4.0.0
State management: Riverpod (flutter_riverpod ^2.5.1)
Architecture: Clean architecture — presentation / domain / data per feature
Localization: flutter_localizations + intl, ARB files at lib/core/localization/l10n/

pubspec.yaml dependencies already include:
  firebase_core, firebase_auth, cloud_firestore, firebase_storage,
  flutter_secure_storage, hive_flutter, hive, path_provider,
  geolocator, google_maps_flutter, http, sensors_plus, record,
  connectivity_plus, url_launcher, uuid, telephony, flutter_riverpod,
  riverpod_annotation, intl, flutter_localizations

l10n.yaml config:
  arb-dir: lib/core/localization/l10n
  template-arb-file: app_en.arb
  output-class: AppLocalizations

Current file tree (all existing .dart files):
  lib/main.dart
  lib/core/localization/l10n/app_en.arb
  lib/core/localization/l10n/app_bn.arb
  lib/core/localization/l10n/app_localizations.dart   (generated)
  lib/core/localization/l10n/app_localizations_en.dart (generated)
  lib/core/localization/l10n/app_localizations_bn.dart (generated)
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
  lib/features/map/domain/safe_place_model.g.dart  (generated — do not touch)
  lib/features/map/presentation/nearby_places_screen.dart
  lib/features/sos/data/audio_recorder_service.dart
  lib/features/sos/data/location_service.dart
  lib/features/sos/data/sms_service.dart
  lib/features/sos/presentation/sos_button_screen.dart
  lib/features/sos/presentation/sos_countdown_overlay.dart
  android/app/src/main/AndroidManifest.xml
  android/app/src/main/kotlin/com/shurokkha/shurokkha/MainActivity.kt

---

EXISTING CODE THAT NEEDS TO BE FIXED OR EXTENDED

// lib/features/disguise/presentation/calculator_disguise_screen.dart
// PROBLEM: No arithmetic engine — pressing = on any input other than the
// secret code shows "Error". The disguise fails immediately.
// Also: _display and _inputBuffer are the same variable; the secret code
// check sees the full raw string (e.g. "9+876") not just digits.
// Also: the secret PIN '9876' is hardcoded — users cannot change it.
class _CalculatorDisguiseScreenState ... {
  String _display = '';
  String _inputBuffer = '';
  final String _secretCode = '9876'; // hardcoded!
  void _onKeyPress(String value) {
    if (value == 'C') { ... }
    else if (value == '=') {
      if (_inputBuffer == _secretCode) { _unlocked = true; }
      else { _display = 'Error'; } // breaks when doing real math
    }
  }
  // Missing: operators (+, -, *, /), decimal point, actual evaluation
  // Missing: button for decimal point '.'
}

// lib/features/sos/presentation/sos_button_screen.dart
// PROBLEM 1: hardcoded SOS message
final message = "I am in danger. Please help me! My live location: $mapsLink";
// PROBLEM 2: no SosEvent document is written to Firestore at trigger time
// PROBLEM 3: connectivity is never checked before SMS — no offline queue
// PROBLEM 4: no permission rationale dialogs before requesting location/mic

// lib/features/map/presentation/nearby_places_screen.dart
// PROBLEM: directions button just shows a SnackBar instead of launching maps
IconButton(
  icon: const Icon(Icons.directions, color: Colors.green),
  onPressed: () {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Directions to ${place.name}')),
    );
  },
),

// lib/features/auth/presentation/login_screen.dart
// PROBLEM 1: no "Forgot Password" button/flow
// PROBLEM 2: no input validation beyond "Required" (no email format, no phone format)
// PROBLEM 3: password strength check missing (min 8 chars)

// lib/core/storage/secure_storage.dart
// PROBLEM: fully written but never used anywhere in the codebase

// lib/features/sos/data/sms_service.dart + connectivity_service.dart
// PROBLEM: SMS is sent without checking connectivity first.
// If the network call fails AND SMS fails, the alert is silently dropped.
// Need: an offline queue that stores failed alerts and retries on reconnect.

// lib/features/contacts/presentation/contact_setup_screen.dart
// PROBLEM: contacts can only be entered manually — no device phonebook picker

// lib/core/localization/l10n/app_en.arb  (current — needs new keys)
{
  "appTitle": "Shurokkha",
  "sosButtonLabel": "SOS",
  "sosButtonSubtitle": "Press & hold or tap in emergency",
  "countdownActive": "Triggering SOS in {seconds}s...",
  "sosCancelled": "SOS Alert Cancelled",
  "trustedContacts": "Trusted Contacts",
  "addContact": "Add Contact",
  "nearbySafePlaces": "Nearby Safe Places",
  "calculatorTitle": "Calculator",
  "loginTitle": "Welcome to Shurokkha",
  "phoneLabel": "Phone Number",
  "emailLabel": "Email Address",
  "passwordLabel": "Password",
  "signIn": "Sign In",
  "signUp": "Sign Up",
  "otpSent": "OTP Sent to Phone",
  "verifyOtp": "Verify OTP"
}

// android/app/src/main/AndroidManifest.xml (current)
// PROBLEM: missing INTERNET, READ_CONTACTS, FOREGROUND_SERVICE permissions
// PROBLEM: Google Maps meta-data key is a dummy placeholder
<meta-data android:name="com.google.android.geo.API_KEY"
           android:value="AIzaSyDummyKeyForBuildVerification"/>

// android/app/src/main/kotlin/com/shurokkha/shurokkha/MainActivity.kt (current)
// Just a bare stub — no platform channels for volume button detection
package com.shurokkha.shurokkha
import io.flutter.embedding.android.FlutterActivity
class MainActivity : FlutterActivity()

// lib/main.dart (current)
// PROBLEM: auth loading state renders a CircularProgressIndicator INSIDE
// the calculator disguise screen, breaking the cover before buttons appear.
home: CalculatorDisguiseScreen(
  child: authState.when(
    data: ...,
    loading: () => Scaffold(body: Center(child: CircularProgressIndicator())),
    ...
  ),
),

---

WHAT TO FIX — BUILD PLAN

Plan your work as the following phases. For each phase, output only that
phase's complete, ready-to-paste files. Precede each file with a clear
comment: // FILE: lib/path/to/file.dart
Do NOT output partial snippets — output the full file content every time.
Wait for "continue phase N" before writing code for the next phase.

PHASE 1 — Calculator Arithmetic Engine + PIN Hardening
  Files to output:
  - lib/features/disguise/presentation/calculator_disguise_screen.dart (REPLACE)
    * Implement a proper infix arithmetic evaluator supporting +, -, *, /, decimal
    * Separate the digit-accumulation buffer (for PIN check) from the display string
    * The PIN check should compare ONLY the pure numeric digit string (ignore operators)
      against the stored PIN — so typing "9876=" still unlocks, but "9+876=" does not
    * Read the current PIN from SecureStorageService (key: 'disguise_pin')
    * If no PIN is stored yet, fall back to the hardcoded default '9876'
    * Add a decimal point '.' button to the keypad
    * Do NOT show any loading indicator — if SecureStorageService.read() is async,
      handle it in initState() using a _pinLoaded flag so the calculator renders
      immediately with a default and silently updates when the future resolves
  - lib/core/storage/secure_storage.dart (no changes needed, but output it so context is clear)

PHASE 2 — Auth Screen Fixes
  Files to output:
  - lib/features/auth/presentation/login_screen.dart (REPLACE)
    * Add email format validation (RegExp)
    * Add Bangladesh phone number validation (+880 prefix, 11 digits total)
    * Add password minimum length validation (>= 8 characters)
    * Add a "Forgot Password?" TextButton that calls authRepo.sendPasswordResetEmail()
      and shows a SnackBar confirming the reset email was sent
    * Add a clear, plain-language permission rationale BottomSheet (using showModalBottomSheet)
      that is shown ONCE (use SecureStorageService key: 'permissions_rationale_shown')
      before the user first signs up, explaining why location, microphone, and SMS
      permissions are needed. This is NOT a system permission dialog — it is an in-app
      explanation screen with an "I Understand" button.
  - lib/core/localization/l10n/app_en.arb (ADD new keys, keep existing ones)
    New keys to add: forgotPassword, forgotPasswordSent, permissionRationaleTitle,
    permissionRationaleBody, iUnderstand, cancelButton, settingsTitle,
    customSosMessage, saveSettings, sosAlertSent, sosAlertFailed,
    directionsTo, addFromContacts, enterManually
  - lib/core/localization/l10n/app_bn.arb (ADD same new keys in Bengali)

PHASE 3 — SosEvent Firestore Model + Settings Screen
  Files to output:
  - lib/features/sos/domain/sos_event_model.dart [NEW]
    * Fields: id (String), userId (String), status (String: 'active'/'cancelled'/'resolved'),
      startedAt (DateTime), endedAt (DateTime?), audioUrl (String?), contactsNotified (List<String>)
    * toMap() and fromMap() methods
    * Static status constants: kStatusActive, kStatusCancelled, kStatusResolved
  - lib/features/settings/domain/app_settings_model.dart [NEW]
    * Fields: customSosMessage (String), disguisePin (String)
    * Defaults: customSosMessage = "I am in danger. Please help me! My live location: {link}"
    *           disguisePin = '9876'
  - lib/features/settings/data/settings_repository.dart [NEW]
    * Uses SecureStorageService to persist customSosMessage (key: 'sos_message')
      and disguisePin (key: 'disguise_pin')
    * Methods: getSettings() → Future<AppSettings>, saveSettings(AppSettings) → Future<void>
  - lib/features/settings/presentation/settings_screen.dart [NEW]
    * TextField for editable SOS message (pre-filled from SecureStorage)
    * TextField for changing the disguise PIN (min 4 digits, only numbers)
    * Save button that calls settingsRepository.saveSettings() and shows a SnackBar
    * A section titled "About Permissions" with plain-text explanation (recording consent notice)
  - lib/features/sos/presentation/sos_button_screen.dart (REPLACE)
    * Import and use settingsRepositoryProvider to read customSosMessage
    * Replace hardcoded message string with the value from settings
    * On _triggerSos(): BEFORE sending SMS, write a SosEvent document to Firestore
      at path: users/{userId}/sos_events/{eventId}
      with status: kStatusActive, startedAt: DateTime.now(), contactsNotified: recipients
    * On _cancelSos(): update the SosEvent document status to kStatusCancelled,
      set endedAt: DateTime.now(), set audioUrl: from stopRecordingAndUpload()
    * Add a Settings icon to the AppBar that navigates to SettingsScreen

PHASE 4 — Offline Alert Queue + Connectivity Integration
  Files to output:
  - lib/features/sos/data/alert_queue_service.dart [NEW]
    * Stores failed alert payloads using Hive (box name: 'pending_alerts')
    * AlertPayload model: recipients (List<String>), message (String), queuedAt (DateTime)
    * Methods: enqueue(AlertPayload), dequeueAll() → List<AlertPayload>, clearAll()
    * Uses HiveType typeId: 1, AlertPayload fields as HiveFields
  - lib/features/sos/data/sms_service.dart (REPLACE)
    * Before sending SMS, use ConnectivityService to check connectivity
    * If connected: attempt normal SMS flow as before
    * If NOT connected: enqueue the alert via AlertQueueService and return
    * Add a retryPendingAlerts() method that dequeues and re-sends all queued alerts
  - lib/main.dart (REPLACE)
    * Fix the auth loading race condition: wrap the entire root with CalculatorDisguiseScreen
      OUTSIDE the authState.when() — the calculator always shows first, then transitions
      smoothly to the auth check result when ready (no spinner inside the disguise)
    * Register the AlertPayload Hive adapter (typeId: 1) in the Hive init block
    * Set up a ConnectivityService stream listener in the root widget that calls
      smsService.retryPendingAlerts() whenever connectivity changes from false → true
    * Register the new HiveType for AlertPayload
    * Initialize Hive box for pending_alerts

PHASE 5 — Directions Fix + Device Contact Picker
  Files to output:
  - lib/features/map/presentation/nearby_places_screen.dart (REPLACE)
    * Fix the directions button: call url_launcher with:
      Android: 'geo:lat,lng?q=lat,lng(Place+Name)'  or
      fallback: 'https://maps.google.com/maps?daddr=lat,lng'
    * Use canLaunchUrl / launchUrl from url_launcher
  - pubspec.yaml (ADD one dependency)
    * Add: flutter_contacts: ^1.1.8+1  (for phonebook picker)
  - lib/features/contacts/presentation/contact_setup_screen.dart (REPLACE)
    * Add a second FAB or a popup menu on the existing FAB with two options:
      "Add from Contacts" and "Enter Manually"
    * "Add from Contacts": request READ_CONTACTS permission using flutter_contacts,
      show a searchable list of device contacts, let user pick one, pre-fill the dialog
    * "Enter Manually": existing flow unchanged
  - android/app/src/main/AndroidManifest.xml (REPLACE)
    * Add missing permissions: INTERNET, READ_CONTACTS, FOREGROUND_SERVICE,
      RECEIVE_BOOT_COMPLETED (for retry on reboot)
    * Replace the dummy Maps API key comment with a clear TODO placeholder:
      android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"
    * Keep all existing activity-alias entries

PHASE 6 — Input Validation + Forgot Password + SnackBar Strings
  Files to output:
  - lib/features/auth/presentation/login_screen.dart (final polish pass)
    * This is the final replacement — ensure all fixes from Phase 2 are included
    * Add: if login fails with 'wrong-password' or 'user-not-found', show a
      friendly localized message (not the raw Firebase error string)
    * Add: show a SnackBar with l10n.forgotPasswordSent after password reset email
  - lib/features/sos/presentation/sos_countdown_overlay.dart (REPLACE)
    * Replace the brittle `.replaceAll('Cancelled', 'Cancel')` hack:
      use the proper l10n.cancelButton key (added in Phase 2 ARB files)

---

OUTPUT FORMAT RULES
1. Precede every file with: // FILE: lib/path/to/file.dart  (exact project-relative path)
2. Output the FULL file content — never a partial snippet or a "// ... rest unchanged" comment
3. Add concise inline comments for any non-obvious logic (especially platform-specific workarounds)
4. At the end of the FINAL phase (Phase 6), output a short VERIFICATION CHECKLIST:
   - flutter pub get  (if new deps were added)
   - dart run build_runner build --delete-conflicting-outputs  (for new Hive adapters)
   - flutter gen-l10n  (after ARB changes)
   - List any runtime secrets the developer must fill in before testing

START
Respond with your phased plan (phase titles, list of files changed per phase, one
sentence describing what each phase fixes). Do NOT write any code yet. Wait for
"continue phase 1" to begin writing code.
```
