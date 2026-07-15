// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'সুরক্ষা';

  @override
  String get sosButtonLabel => 'এসওএস (SOS)';

  @override
  String get sosButtonSubtitle => 'জরুরী মুহূর্তে টিপুন এবং ধরে রাখুন';

  @override
  String countdownActive(int seconds) {
    return '$seconds সেকেন্ডের মধ্যে এসওএস চালু হচ্ছে...';
  }

  @override
  String get sosCancelled => 'এসওএস সতর্কতা বাতিল করা হয়েছে';

  @override
  String get trustedContacts => 'বিশ্বস্ত পরিচিতি';

  @override
  String get addContact => 'পরিচিতি যোগ করুন';

  @override
  String get nearbySafePlaces => 'নিকটবর্তী নিরাপদ স্থান';

  @override
  String get calculatorTitle => 'ক্যালকুলেটর';

  @override
  String get loginTitle => 'সুরক্ষায় আপনাকে স্বাগতম';

  @override
  String get phoneLabel => 'ফোন নম্বর';

  @override
  String get emailLabel => 'ইমেল ঠিকানা';

  @override
  String get passwordLabel => 'পাসওয়ার্ড';

  @override
  String get signIn => 'সাইন ইন করুন';

  @override
  String get signUp => 'নিবন্ধন করুন';

  @override
  String get otpSent => 'ফোনে ওটিপি পাঠানো হয়েছে';

  @override
  String get verifyOtp => 'ওটিপি যাচাই করুন';

  @override
  String get forgotPassword => 'পাসওয়ার্ড ভুলে গেছেন?';

  @override
  String get forgotPasswordSent => 'পাসওয়ার্ড রিসেট ইমেল পাঠানো হয়েছে।';

  @override
  String get permissionRationaleTitle => 'অনুমতি কেন প্রয়োজন';

  @override
  String get permissionRationaleBody =>
      'সুরক্ষার জন্য অবস্থান (এসওএস চলাকালীন লাইভ লোকেশন ট্র্যাক করতে), মাইক্রোফোন (অডিও রেকর্ড করতে), এবং এসএমএস (silent ব্যাকগ্রাউন্ড এসএমএস পাঠাতে) প্রয়োজন। অনুগ্রহ করে এই অনুমতিগুলো দিন।';

  @override
  String get iUnderstand => 'আমি বুঝতে পেরেছি';

  @override
  String get cancelButton => 'বাতিল';

  @override
  String get settingsTitle => 'সেটিংস';

  @override
  String get customSosMessage => 'কাস্টম এসওএস বার্তা';

  @override
  String get saveSettings => 'সেটিংস সংরক্ষণ করুন';

  @override
  String get sosAlertSent =>
      'এসওএস সতর্কতা বিশ্বস্ত পরিচিতিদের কাছে সফলভাবে পাঠানো হয়েছে!';

  @override
  String get sosAlertFailed => 'এসওএস সতর্কতা পাঠাতে ব্যর্থ হয়েছে।';

  @override
  String directionsTo(String name) {
    return '$name এর দিকনির্দেশ';
  }

  @override
  String get addFromContacts => 'কন্টাক্ট তালিকা থেকে যোগ করুন';

  @override
  String get enterManually => 'ম্যানুয়ালি প্রবেশ করুন';

  @override
  String get darkMode => 'ডার্ক মোড';

  @override
  String get language => 'ভাষা';

  @override
  String get selectLanguage => 'ভাষা নির্বাচন করুন';

  @override
  String get sosHistory => 'এসওএস ইতিহাস';

  @override
  String get eventHistory => 'জরুরী ইভেন্টের ইতিহাস';

  @override
  String get noEventsYet => 'এখনো কোনো এসওএস ইভেন্ট রেকর্ড করা হয়নি।';

  @override
  String get statusActive => 'সক্রিয়';

  @override
  String get statusCancelled => 'বাতিল';

  @override
  String get statusResolved => 'সমাধান করা';

  @override
  String eventStarted(String time) {
    return 'শুরু: $time';
  }

  @override
  String eventEnded(String time) {
    return 'সমাপ্ত: $time';
  }

  @override
  String get audioRecording => 'অডিও রেকর্ডিং';

  @override
  String get viewOnMap => 'মানচিত্রে দেখুন';

  @override
  String get enableDisguise => 'ছদ্মবেশী মোড সক্রিয় করুন';

  @override
  String get disguiseMode => 'ছদ্মবেশী মোড';

  @override
  String get volumeTrigger => 'ভলিউম বোতাম ট্রিগার';

  @override
  String get volumeTriggerDesc =>
      'এসওএস চালু করতে দ্রুত ৩ বার ভলিউম-ডাউন টিপুন';
}
