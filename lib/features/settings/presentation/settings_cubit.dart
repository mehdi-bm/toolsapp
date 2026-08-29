import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/settings_repository.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repository)
    : super(
        SettingsState(
          themeMode: _repository.getThemeMode(),
          showRecent: _repository.getShowRecent(),
        ),
      );

  final SettingsRepository _repository;

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    await _repository.saveThemeMode(mode);
  }

  Future<void> setShowRecent(bool value) async {
    emit(state.copyWith(showRecent: value));
    await _repository.saveShowRecent(value);
  }

  Future<void> resetToDefaults() async {
    await _repository.resetToDefaults();
    emit(const SettingsState(themeMode: ThemeMode.system, showRecent: true));
  }
}
