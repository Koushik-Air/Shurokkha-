# Shurokkha (সুরক্ষা) — Women's Safety & SOS Emergency App

Shurokkha is a production-quality, safety-critical personal safety and SOS emergency application built with Flutter & Riverpod. Designed with Bengali (bn) and English (en) localization, it targets users in Bangladesh and functions reliably even with unstable network connectivity using automated SMS fallbacks.

## Features

1. **Gatekeeper Calculator Disguise**: Launches a fully operational calculator interface. Bypasses and reveals the safety dashboard only upon dialing `9876=`.
2. **One-Touch SOS Alert**: Large high-contrast SOS button with a 3-second cancelable countdown overlay to prevent accidental triggers.
3. **Continuous Location Stream**: Tracks user position in the background (using Geolocator) and broadcasts live coordinate updates to a Firestore tracking link.
4. **Automated SMS Fallback**: Checks connectivity via `connectivity_plus`. Sends direct, background SMS with a Google Maps link to all trusted contacts on Android, and launches a prefilled message composer on iOS.
5. **Silent Emergency Trigger**: Detects device shake forces using `sensors_plus` and initializes countdown automatically.
6. **Background Audio Capture**: Automatically records microphone feed using `record` and pushes to Firebase Storage when connectivity restores.
7. **Nearby Safe Places Map**: Uses Google Maps and Google Places API to showcase nearest police stations and hospitals with direction guides, using Hive storage to cache places offline.

---

## Technical Details

### Platform Differences & Store Guidelines Compliance

Due to platform restrictions and App Store review guidelines, certain safety features operate differently on Android and iOS:

| Feature | Android Support | iOS Support / Workaround | Reason |
| :--- | :--- | :--- | :--- |
| **SOS Alert Mechanism** | Direct silent background SMS | Prefilled native SMS composer sheet | Apple prohibits background SMS sending without user intervention |
| **Launcher Disguise** | Supported via `activity-alias` launcher swaps | Simulated in-app calculator gatekeeper | Apple App Store rules ban dynamic icon renaming disguised as utility apps |
| **Background Audio** | Silent background recording | Background audio indicator (red banner) | iOS highlights running recording sessions for privacy |

---

## Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0 <4.0.0)
- Android SDK (Min API 21)
- iOS Development environment (Xcode)

### Setup & Installation

1. **Clone and Install Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Generate Localization Files**:
   ```bash
   flutter gen-l10n
   ```

3. **Database Adapter Build**:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Configure Platforms APIs**:
   - **Firebase**: Associate your Android package name `com.shurokkha.shurokkha` and iOS Bundle ID with your Firebase Console project. Place the generated `google-services.json` in `android/app/` and `GoogleService-Info.plist` in `ios/Runner/`.
   - **Google Maps API**: Provide your Google Maps SDK & Places API key in the android manifest/info plist configurations.

5. **Run the App**:
   ```bash
   flutter run
   ```
