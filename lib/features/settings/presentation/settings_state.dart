import 'package:flutter/material.dart';

class SettingsState {
  const SettingsState({required this.themeMode, required this.showRecent});

  final ThemeMode themeMode;
  final bool showRecent;

  SettingsState copyWith({ThemeMode? themeMode, bool? showRecent}) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      showRecent: showRecent ?? this.showRecent,
    );
  }
}
