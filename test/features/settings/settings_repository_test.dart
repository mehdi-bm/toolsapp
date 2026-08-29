import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbax/features/settings/data/settings_repository.dart';

void main() {
  test('defaults to system theme mode and show-recent = true', () async {
    SharedPreferences.setMockInitialValues(const {});
    final repository = SettingsRepository(
      await SharedPreferences.getInstance(),
    );

    expect(repository.getThemeMode(), ThemeMode.system);
    expect(repository.getShowRecent(), isTrue);
  });

  test('persists theme mode and show-recent across repository instances', () async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    final repository = SettingsRepository(prefs);

    await repository.saveThemeMode(ThemeMode.dark);
    await repository.saveShowRecent(false);

    final reloaded = SettingsRepository(prefs);
    expect(reloaded.getThemeMode(), ThemeMode.dark);
    expect(reloaded.getShowRecent(), isFalse);
  });

  test('resetToDefaults clears both persisted values', () async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    final repository = SettingsRepository(prefs);

    await repository.saveThemeMode(ThemeMode.light);
    await repository.saveShowRecent(false);

    await repository.resetToDefaults();

    expect(repository.getThemeMode(), ThemeMode.system);
    expect(repository.getShowRecent(), isTrue);
  });
}
