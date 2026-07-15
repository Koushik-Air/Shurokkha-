// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Shurokkha';

  @override
  String get sosButtonLabel => 'SOS';

  @override
  String get sosButtonSubtitle => 'Press & hold or tap in emergency';

  @override
  String countdownActive(int seconds) {
    return 'Triggering SOS in ${seconds}s...';
  }

  @override
  String get sosCancelled => 'SOS Alert Cancelled';

  @override
  String get trustedContacts => 'Trusted Contacts';

  @override
  String get addContact => 'Add Contact';

  @override
  String get nearbySafePlaces => 'Nearby Safe Places';

  @override
  String get calculatorTitle => 'Calculator';

  @override
  String get loginTitle => 'Welcome to Shurokkha';

  @override
  String get phoneLabel => 'Phone Number';

  @override
  String get emailLabel => 'Email Address';

  @override
  String get passwordLabel => 'Password';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get otpSent => 'OTP Sent to Phone';

  @override
  String get verifyOtp => 'Verify OTP';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get forgotPasswordSent => 'Password reset email sent.';

  @override
  String get permissionRationaleTitle => 'Why we need permissions';

  @override
  String get permissionRationaleBody =>
      'Shurokkha requires Location (to track your live coordinates during SOS), Microphone (to record audio evidence), and SMS (to send silent background alerts to contacts). Please grant these when prompted.';

  @override
  String get iUnderstand => 'I Understand';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get customSosMessage => 'Custom SOS Alert Message';

  @override
  String get saveSettings => 'Save Settings';

  @override
  String get sosAlertSent => 'SOS Alert successfully sent to trusted contacts!';

  @override
  String get sosAlertFailed => 'Failed to send SOS alert.';

  @override
  String directionsTo(String name) {
    return 'Directions to $name';
  }

  @override
  String get addFromContacts => 'Add from Contacts';

  @override
  String get enterManually => 'Enter Manually';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get sosHistory => 'SOS History';

  @override
  String get eventHistory => 'Emergency Event History';

  @override
  String get noEventsYet => 'No SOS events recorded yet.';

  @override
  String get statusActive => 'Active';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusResolved => 'Resolved';

  @override
  String eventStarted(String time) {
    return 'Started: $time';
  }

  @override
  String eventEnded(String time) {
    return 'Ended: $time';
  }

  @override
  String get audioRecording => 'Audio Recording';

  @override
  String get viewOnMap => 'View on Map';

  @override
  String get enableDisguise => 'Enable Disguise Mode';

  @override
  String get disguiseMode => 'Disguise Mode';

  @override
  String get volumeTrigger => 'Volume Button Trigger';

  @override
  String get volumeTriggerDesc =>
      'Press volume-down 3 times rapidly to trigger SOS';
}
