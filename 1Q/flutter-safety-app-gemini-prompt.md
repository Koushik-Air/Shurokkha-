# Flutter Women's Safety App — Master Prompt for Gemini 3.5 Flash

## Quick facts (why this prompt is structured the way it is)

| Fact | Detail |
|---|---|
| Model | `gemini-3.5-flash` (GA since May 19, 2026) |
| Input context | ~1,048,576 tokens |
| **Output cap** | **65,536 tokens per response** — a full app's code cannot fit in one reply |
| Strengths | Tuned for agentic, multi-step coding and long-horizon tasks |
| Prompting style | Prefers concise, direct instructions over verbose chain-of-thought; responds well to a `GOAL / CONTEXT / PLAN / OUTPUT` structure |
| If using the API (not chat) | Set `thinking_level: "high"` for the planning turn, `thinking_level: "low"` for code-generation turns (Google specifically retuned "low" for coding/agentic work) |

Because of the 65K output limit, the prompt below is written to make Gemini **plan first, then build in phases** across multiple turns — asking for the whole app at once will just get you a truncated file.

One technical note baked into the prompt: a few of your requested features (silent power-button trigger, background SMS, home-screen icon disguise) are realistic on Android but restricted or against App Store policy on iOS. Rather than let the model quietly invent a fake implementation, the prompt tells it to target Android as the primary platform and explicitly document each iOS gap instead of pretending it works.

---

## How to use this

1. Paste the entire block under **"The Prompt"** as your first message to Gemini 3.5 Flash (Gemini app, AI Studio, or Antigravity).
2. It will reply with an architecture plan, file structure, and a numbered list of build phases — **review this before continuing**, this is your chance to catch a bad tech choice early.
3. Reply `continue` (or `proceed to Phase 3`, etc.) to have it generate one phase's code at a time.
4. Replace `[APP_NAME]` in the prompt with your chosen name before pasting — e.g. "Shurokkha" (সুরক্ষা, Bengali for "protection") is a natural fit if you want a localized name, but any name works.

---

## The Prompt

```
ROLE
You are a senior Flutter/Dart engineer and mobile security architect with 10+ years
building production safety-critical apps for Android and iOS.

GOAL
Design and build, from scratch, a complete, production-quality Flutter application
called "[APP_NAME]" — a personal safety / SOS emergency app for women, primarily
targeting users in Bangladesh. Assume unreliable mobile internet is the norm, so SMS
fallback is a first-class feature, not an afterthought.

CONTEXT
- Target platforms: Android (primary, full feature set) and iOS (secondary —
  implement everything that is technically possible under Apple's App Store
  guidelines; where a feature cannot be implemented on iOS due to platform/App
  Store restrictions, implement the closest safe equivalent and clearly flag the
  limitation in code comments and the README instead of silently faking it).
- Backend: Firebase (Authentication, Cloud Firestore, Cloud Messaging, Cloud
  Storage, Cloud Functions) unless a specific requirement genuinely needs
  something else — justify any deviation before using it.
- State management: Riverpod.
- Architecture: layered/clean architecture (presentation / domain / data),
  null-safe Dart, current stable Flutter 3.x APIs.
- Localization: Bengali (bn) and English (en) from day one via
  flutter_localizations + intl. The SOS flow specifically must work fully in
  Bengali.
- The user base may be in physical danger. Every design decision should default
  to reliability and low-friction operation under stress over visual polish.

FUNCTIONAL REQUIREMENTS (build all of these)

1. Registration & Login
   - Sign up with phone number, email, and password. Firebase Auth with phone OTP
     verification plus email/password.
   - Secure local credential/session storage (flutter_secure_storage), a
     forgot-password flow, and input validation.

2. Emergency Contact Setup
   - Add/edit/delete trusted contacts (name, relationship, phone, optional
     email). Support picking from device contacts or manual entry.
   - Require at least 1 contact, recommend 3+, before the SOS button is fully
     "armed." Sync contacts to Firestore per user.

3. SOS Emergency Button
   - A large, high-contrast, always-reachable button on the home screen,
     operable one-handed.
   - On press: a 3-second cancelable countdown (to prevent accidental triggers)
     → capture GPS → send the alert (see #4/#5) to every emergency contact →
     start audio recording (#7) → log the event with a timestamp.
   - Default alert text: "I am in danger. Please help me. My live location:
     [link]" — must be editable by the user in settings.

4. Live Location Sharing
   - Use `geolocator` to get GPS coordinates and generate a Google Maps link
     (https://maps.google.com/?q=lat,lng).
   - During an active SOS session, keep sending updated locations (every
     30-60s) via a lightweight live-tracking mechanism (a Firestore-backed link
     contacts can open and watch update in near-real time), not just one static
     pin.

5. SMS Alert System
   - Detect connectivity with `connectivity_plus`. If data/wifi is unavailable
     or the primary send fails, fall back to SMS automatically.
   - On Android, send SMS directly via the `telephony` plugin using the
     SEND_SMS permission.
   - On iOS, Apple does not allow silent/background SMS sending — implement the
     closest available equivalent (a pre-filled `url_launcher` SMS compose
     screen that still needs one tap to send) and document this constraint
     clearly in the README and during onboarding.

6. Silent Emergency Trigger
   - Shake-to-trigger via `sensors_plus` as the primary method (works on both
     platforms).
   - Rapid volume-button-press trigger on Android via a platform channel /
     foreground service.
   - Power-button multi-press on Android only, via an Accessibility Service —
     note that this needs a separate permission grant from the user. Document
     that iOS does not allow intercepting hardware button events for this
     purpose, so shake-to-trigger is the iOS equivalent.

7. Emergency Audio Recording
   - Use `record` (or `flutter_sound`) to record audio during an active SOS
     session. Store locally first, then upload to Firebase Storage in the
     background once connectivity returns.
   - On iOS, background audio recording requires the Audio background mode and
     will show the system recording indicator — it cannot be fully hidden.
     Document this honestly.
   - Include a short in-app disclosure that recording-consent laws vary by
     jurisdiction.

8. Nearby Safe Places
   - Use `google_maps_flutter` plus the Places API to show the nearest police
     stations, hospitals, and women's support centers, both on a map and as a
     list sorted by distance with one-tap directions.
   - Cache the last successful results locally (e.g. Hive) so the list still
     works with no connectivity.

9. Fake Exit / Hidden Mode
   - Build a fully functional in-app disguise screen (e.g. a working
     calculator) that unlocks the real app via a specific input sequence or
     PIN.
   - On Android, additionally support swapping the launcher icon/label via
     `activity-alias` so the app appears as something else on the home screen.
   - Flag explicitly in the README that Apple's guidelines generally prohibit
     apps that intentionally disguise their function, so the icon-swap part of
     this feature is Android-only — confirm that trade-off rather than
     building something that gets the app rejected on iOS.

NON-FUNCTIONAL REQUIREMENTS
- Security: encrypt sensitive local data at rest, never log or store plaintext
  passwords, use HTTPS everywhere, apply least-privilege to every permission.
- Privacy: show a clear, plain-language rationale dialog before requesting each
  sensitive permission (location "always," microphone, SMS, contacts).
- Offline-first: queue failed alerts/SMS and retry automatically once
  connectivity returns. The core SOS flow must never hard-fail just because the
  network is down.
- Accessibility: large touch targets, high color contrast, full screen-reader
  labels on the SOS flow specifically.
- Battery: use the least aggressive location-polling strategy that still meets
  the live-tracking requirement.

PLAN (do this before writing any code)
In this first response only, produce:
1. A one-paragraph architecture summary and your chosen package list, as a
   draft pubspec.yaml.
2. The full project folder/file structure.
3. The core data models (User, EmergencyContact, SosEvent, etc.).
4. A numbered list of build phases you propose (e.g. Phase 2 = Auth, Phase 3 =
   Contacts + Home/SOS button, Phase 4 = Location + SMS, Phase 5 = Silent
   trigger + Recording, Phase 6 = Safe places, Phase 7 = Disguise mode, Phase 8
   = polish/tests/README), sized so each phase's code fits in one response.
Wait for my confirmation ("continue" or edits) before writing implementation
code for Phase 2 onward.

OUTPUT FORMAT
- Precede each code block with a clear file-path comment, e.g.
  // lib/features/sos/sos_button.dart
- Add concise comments explaining any non-obvious platform-specific
  workaround.
- At the end of the final phase, produce a README covering setup, required
  permissions per platform, third-party services to configure (Firebase
  project, Google Maps/Places API keys), and a plain list of the known
  Android-vs-iOS feature differences called out above.
```
