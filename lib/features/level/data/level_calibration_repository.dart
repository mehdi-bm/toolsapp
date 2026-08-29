import 'package:shared_preferences/shared_preferences.dart';

class LevelCalibrationRepository {
  LevelCalibrationRepository(this._prefs);

  static const String _rollKey = 'level_roll_offset';
  static const String _pitchKey = 'level_pitch_offset';

  final SharedPreferences _prefs;

  double getRollOffset() => _prefs.getDouble(_rollKey) ?? 0;

  double getPitchOffset() => _prefs.getDouble(_pitchKey) ?? 0;

  Future<void> saveOffsets({required double roll, required double pitch}) async {
    await _prefs.setDouble(_rollKey, roll);
    await _prefs.setDouble(_pitchKey, pitch);
  }
}
