import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  SettingsRepository(this._prefs);

  static const String _themeModeKey = 'settings_theme_mode';
  static const String _showRecentKey = 'settings_show_recent';

  final SharedPreferences _prefs;

  ThemeMode getThemeMode() {
    switch (_prefs.getString(_themeModeKey)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) {
    final String raw = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    return _prefs.setString(_themeModeKey, raw);
  }

  bool getShowRecent() => _prefs.getBool(_showRecentKey) ?? true;

  Future<void> saveShowRecent(bool value) {
    return _prefs.setBool(_showRecentKey, value);
  }

  Future<void> resetToDefaults() async {
    await _prefs.remove(_themeModeKey);
    await _prefs.remove(_showRecentKey);
  }
}
