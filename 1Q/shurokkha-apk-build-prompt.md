# Shurokkha APK Build Prompt — Gemini 3.5 Flash

## ROLE
You are a senior Android DevOps engineer with deep expertise in Flutter release builds, Firebase configuration, and Google Play signing.

## GOAL
Build a signed release APK for the **Shurokkha** Flutter safety app located at:
```
/home/koushik/Desktop/Projects/Thesis/
```

## PROJECT CONTEXT

| Detail | Value |
|---|---|
| App Name | Shurokkha (সুরক্ষা) |
| Package ID | `com.shurokkha.shurokkha` |
| Flutter SDK | `>=3.0.0 <4.0.0` |
| Build system | Gradle (Kotlin DSL) |
| Min SDK | Flutter default (`flutter.minSdkVersion`) |
| Release signing | Currently using debug keys — must be upgraded for production |

**Key dependencies that need platform config before building:**
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage` → requires `google-services.json`
- `google_maps_flutter` → requires Google Maps API key in `AndroidManifest.xml`
- `telephony` → requires `SEND_SMS` permission (already in manifest)

---

## PLAN (Do this before running any build commands)

In your first response only, produce:
1. A checklist of all pre-build steps (Firebase config, signing keystore, API keys)
2. The exact commands you will run (in order)
3. Flag any missing files or environment variables you need the user to provide

Wait for confirmation before proceeding.

---

## BUILD STEPS (execute after user confirms)

### Step 1 — Verify environment
```bash
cd /home/koushik/Desktop/Projects/Thesis
flutter doctor -v
flutter --version
```

### Step 2 — Install dependencies & generate code
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

### Step 3 — Firebase configuration
Place `google-services.json` (downloaded from Firebase Console for package `com.shurokkha.shurokkha`) at:
```
android/app/google-services.json
```
Then apply the plugin in `android/app/build.gradle.kts`:
```kotlin
plugins {
    id("com.google.gms.google-services") // Add this line
}
```
And in `android/build.gradle.kts`:
```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.1" apply false
}
```

### Step 4 — Add Google Maps API key
In `android/app/src/main/AndroidManifest.xml`, inside `<application>`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

### Step 5 — Create release signing keystore (if not exists)
```bash
keytool -genkey -v \
  -keystore android/app/shurokkha-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias shurokkha \
  -dname "CN=Shurokkha, OU=Safety, O=Shurokkha, L=Dhaka, S=Dhaka, C=BD"
```

Then add signing config to `android/app/build.gradle.kts`:
```kotlin
android {
    signingConfigs {
        create("release") {
            storeFile = file("shurokkha-release.jks")
            storePassword = System.getenv("KEYSTORE_PASS") ?: "changeit"
            keyAlias = "shurokkha"
            keyPassword = System.getenv("KEY_PASS") ?: "changeit"
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

### Step 6 — Build release APK
```bash
flutter build apk --release --target-platform android-arm64
```

For a universal APK (all architectures):
```bash
flutter build apk --release
```

For split APKs per ABI (smaller size, recommended for Play Store):
```bash
flutter build apk --release --split-per-abi
```

### Step 7 — Verify output
```bash
ls -lh build/app/outputs/flutter-apk/
```
APK location: `build/app/outputs/flutter-apk/app-release.apk`

---

## TROUBLESHOOTING GUIDE

| Error | Fix |
|---|---|
| `google-services.json not found` | Download from Firebase Console → Project Settings → Android app |
| `Execution failed for task ':app:processReleaseGoogleServices'` | Check `google-services.json` package name matches `com.shurokkha.shurokkha` |
| `minSdkVersion < 19` (telephony plugin) | Set `minSdk = 21` in `android/app/build.gradle.kts` |
| `Keystore file not found` | Run the `keytool` command in Step 5 |
| `AAPT2 error: missing Google Maps API key` | Add the `<meta-data>` tag in Step 4 |
| Build cache issues | Run `flutter clean && flutter pub get` then retry |

---

## OUTPUT FORMAT
- Show each command's output before proceeding to the next step
- If any step fails, explain the root cause and the fix before retrying
- At the end, confirm APK path, file size, and SHA-256 checksum:
  ```bash
  sha256sum build/app/outputs/flutter-apk/app-release.apk
  ```
