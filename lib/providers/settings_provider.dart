import 'package:flutter/material.dart';
import '../repositories/settings_repository.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _repo = SettingsRepository();
  bool _hasPinSet = false;
  bool _isLoaded = false;
  ThemeMode _themeMode = ThemeMode.system;

  bool get hasPinSet => _hasPinSet;
  bool get isLoaded => _isLoaded;
  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    _hasPinSet = await _repo.hasPinSet();
    final themeModeString = await _repo.getSetting('theme_mode');
    _themeMode = _themeModeFromString(themeModeString);
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    await _repo.setPin(pin);
    _hasPinSet = true;
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) async {
    return await _repo.verifyPin(pin);
  }

  Future<void> changePin(String newPin) async {
    await _repo.setPin(newPin);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _repo.setSetting('theme_mode', _themeModeToString(mode));
    _themeMode = mode;
    notifyListeners();
  }

  static ThemeMode _themeModeFromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'auto';
    }
  }
}
