import 'package:shared_preferences/shared_preferences.dart';

class RulerCalibrationRepository {
  RulerCalibrationRepository(this._prefs);

  static const String _key = 'ruler_px_per_cm';

  /// Starting guess before the user calibrates: Android's dp-to-inch design
  /// convention (160dp = 1in), not a physically measured value.
  static const double defaultPxPerCm = 160 / 2.54;

  final SharedPreferences _prefs;

  double getPxPerCm() => _prefs.getDouble(_key) ?? defaultPxPerCm;

  Future<void> savePxPerCm(double value) => _prefs.setDouble(_key, value);
}
