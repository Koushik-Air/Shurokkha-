import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/settings_repository.dart';
import '../domain/app_settings_model.dart';
import '../../disguise/data/disguise_service.dart';
import '../../../main.dart';
import 'package:shurokkha/core/localization/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _messageController;
  late TextEditingController _pinController;
  bool _isSaving = false;

  bool _isDarkMode = false;
  String _selectedLocale = 'en';
  bool _isVolumeTriggerEnabled = false;
  bool _isDisguiseEnabled = false;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _pinController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsFutureProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: settingsAsync.when(
        data: (settings) {
          if (!_initialized) {
            _messageController.text = settings.customSosMessage;
            _pinController.text = settings.disguisePin;
            _isDarkMode = settings.isDarkMode;
            _selectedLocale = settings.locale;
            _isVolumeTriggerEnabled = settings.isVolumeTriggerEnabled;
            _isDisguiseEnabled = settings.isDisguiseEnabled;
            _initialized = true;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchListTile(
                    title: Text(l10n.darkMode),
                    value: _isDarkMode,
                    onChanged: (val) {
                      setState(() {
                        _isDarkMode = val;
                      });
                    },
                    secondary: const Icon(Icons.brightness_6),
                  ),
                  const Divider(),
                  ListTile(
                    title: Text(l10n.language),
                    subtitle: Text(l10n.selectLanguage),
                    leading: const Icon(Icons.language),
                    trailing: DropdownButton<String>(
                      value: _selectedLocale,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedLocale = val;
                          });
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: 'en',
                          child: Text('English'),
                        ),
                        DropdownMenuItem(
                          value: 'bn',
                          child: Text('বাংলা'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text(l10n.volumeTrigger),
                    subtitle: Text(l10n.volumeTriggerDesc),
                    value: _isVolumeTriggerEnabled,
                    onChanged: (val) {
                      setState(() {
                        _isVolumeTriggerEnabled = val;
                      });
                    },
                    secondary: const Icon(Icons.volume_down),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text(l10n.disguiseMode),
                    subtitle: Text(Platform.isAndroid
                        ? "Show app as Calculator on home screen"
                        : "Not available on iOS"),
                    value: Platform.isAndroid ? _isDisguiseEnabled : false,
                    onChanged: Platform.isAndroid
                        ? (val) {
                            setState(() {
                              _isDisguiseEnabled = val;
                            });
                          }
                        : null,
                    secondary: const Icon(Icons.app_shortcut),
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    l10n.customSosMessage,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _messageController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter custom SOS message. Use {link} for coordinates.',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Disguise Calculator PIN',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter a 4-digit numeric PIN',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 4) return 'PIN must be at least 4 digits';
                      if (int.tryParse(v) == null) return 'PIN must be numeric only';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  if (_isSaving)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton(
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        setState(() {
                          _isSaving = true;
                        });
                        try {
                          // Handle launcher icon disguise triggers
                          if (Platform.isAndroid) {
                            final disguiseService = ref.read(disguiseServiceProvider);
                            if (_isDisguiseEnabled) {
                              final success = await disguiseService.enableDisguise();
                              if (success) {
                                _showSnackBar('Disguise alias activated! The app icon will change shortly.');
                              }
                            } else {
                              await disguiseService.disableDisguise();
                              _showSnackBar('Disguise alias deactivated. Original icon restored.');
                            }
                          }

                          final newSettings = AppSettings(
                            customSosMessage: _messageController.text.trim(),
                            disguisePin: _pinController.text.trim(),
                            isDarkMode: _isDarkMode,
                            locale: _selectedLocale,
                            isVolumeTriggerEnabled: _isVolumeTriggerEnabled,
                            isDisguiseEnabled: _isDisguiseEnabled,
                          );

                          await ref.read(settingsRepositoryProvider).saveSettings(newSettings);

                          // Live-update state providers immediately
                          ref.read(themeModeProvider.notifier).state = _isDarkMode ? ThemeMode.dark : ThemeMode.light;
                          ref.read(localeProvider.notifier).state = Locale(_selectedLocale);

                          ref.invalidate(settingsFutureProvider);
                          _showSnackBar('Settings saved successfully');
                        } catch (e) {
                          _showSnackBar('Failed to save settings: $e', isError: true);
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isSaving = false;
                            });
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(l10n.saveSettings),
                    ),
                  const SizedBox(height: 40),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'About Recording Consent',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This app records audio to capture evidence during a triggered SOS alert. Recording-consent laws vary by country and state. Ensure you use this feature responsibly and in compliance with your local regulations.',
                    style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading settings: $e')),
      ),
    );
  }
}
