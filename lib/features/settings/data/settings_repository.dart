import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage.dart';
import '../domain/app_settings_model.dart';

class SettingsRepository {
  final SecureStorageService _secureStorage = SecureStorageService();

  static const String _messageKey = 'sos_message';
  static const String _pinKey = 'disguise_pin';
  static const String _darkModeKey = 'dark_mode';
  static const String _localeKey = 'locale';
  static const String _volumeTriggerKey = 'volume_trigger_enabled';
  static const String _disguiseEnabledKey = 'disguise_enabled';

  static const String _defaultMessage = 'I am in danger. Please help me! My live location: {link}';
  static const String _defaultPin = '9876';

  Future<AppSettings> getSettings() async {
    final message = await _secureStorage.read(_messageKey) ?? _defaultMessage;
    final pin = await _secureStorage.read(_pinKey) ?? _defaultPin;
    final darkModeVal = await _secureStorage.read(_darkModeKey) ?? 'false';
    final localeVal = await _secureStorage.read(_localeKey) ?? 'en';
    final volumeTriggerVal = await _secureStorage.read(_volumeTriggerKey) ?? 'false';
    final disguiseEnabledVal = await _secureStorage.read(_disguiseEnabledKey) ?? 'false';

    return AppSettings(
      customSosMessage: message,
      disguisePin: pin,
      isDarkMode: darkModeVal == 'true',
      locale: localeVal,
      isVolumeTriggerEnabled: volumeTriggerVal == 'true',
      isDisguiseEnabled: disguiseEnabledVal == 'true',
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _secureStorage.write(_messageKey, settings.customSosMessage);
    await _secureStorage.write(_pinKey, settings.disguisePin);
    await _secureStorage.write(_darkModeKey, settings.isDarkMode ? 'true' : 'false');
    await _secureStorage.write(_localeKey, settings.locale);
    await _secureStorage.write(_volumeTriggerKey, settings.isVolumeTriggerEnabled ? 'true' : 'false');
    await _secureStorage.write(_disguiseEnabledKey, settings.isDisguiseEnabled ? 'true' : 'false');
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final settingsFutureProvider = FutureProvider<AppSettings>((ref) async {
  return ref.watch(settingsRepositoryProvider).getSettings();
});
