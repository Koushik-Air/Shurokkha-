class AppSettings {
  final String customSosMessage;
  final String disguisePin;
  final bool isDarkMode;
  final String locale;
  final bool isVolumeTriggerEnabled;
  final bool isDisguiseEnabled;

  AppSettings({
    required this.customSosMessage,
    required this.disguisePin,
    required this.isDarkMode,
    required this.locale,
    required this.isVolumeTriggerEnabled,
    required this.isDisguiseEnabled,
  });

  AppSettings copyWith({
    String? customSosMessage,
    String? disguisePin,
    bool? isDarkMode,
    String? locale,
    bool? isVolumeTriggerEnabled,
    bool? isDisguiseEnabled,
  }) {
    return AppSettings(
      customSosMessage: customSosMessage ?? this.customSosMessage,
      disguisePin: disguisePin ?? this.disguisePin,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      locale: locale ?? this.locale,
      isVolumeTriggerEnabled: isVolumeTriggerEnabled ?? this.isVolumeTriggerEnabled,
      isDisguiseEnabled: isDisguiseEnabled ?? this.isDisguiseEnabled,
    );
  }
}
