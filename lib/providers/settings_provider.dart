import 'package:flutter/material.dart';
import '../models/color_theme.dart';
import '../repositories/settings_repository.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _repo = SettingsRepository();
  bool _hasPinSet = false;
  bool _isLoaded = false;
  ThemeMode _themeMode = ThemeMode.system;
  ColorTheme _colorTheme = ColorTheme.snazzy;
  bool _playSounds = true;
  bool _requireFullFlashcardView = false;

  bool get hasPinSet => _hasPinSet;
  bool get isLoaded => _isLoaded;
  ThemeMode get themeMode => _themeMode;
  ColorTheme get colorTheme => _colorTheme;
  bool get playSounds => _playSounds;
  bool get requireFullFlashcardView => _requireFullFlashcardView;

  Future<void> load() async {
    _hasPinSet = await _repo.hasPinSet();
    final themeModeString = await _repo.getSetting('theme_mode');
    _themeMode = _themeModeFromString(themeModeString);
    final colorThemeString = await _repo.getSetting('color_theme');
    _colorTheme = ColorTheme.fromStorageString(colorThemeString);
    final playSoundsString = await _repo.getSetting('play_sounds');
    _playSounds = playSoundsString != 'false';
    final requireFullFlashcardViewString =
        await _repo.getSetting('require_full_flashcard_view');
    _requireFullFlashcardView = requireFullFlashcardViewString == 'true';
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

  Future<void> setColorTheme(ColorTheme theme) async {
    await _repo.setSetting('color_theme', theme.toStorageString());
    _colorTheme = theme;
    notifyListeners();
  }

  Future<void> setPlaySounds(bool value) async {
    await _repo.setSetting('play_sounds', value.toString());
    _playSounds = value;
    notifyListeners();
  }

  Future<void> setRequireFullFlashcardView(bool value) async {
    await _repo.setSetting('require_full_flashcard_view', value.toString());
    _requireFullFlashcardView = value;
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
