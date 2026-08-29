import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:toolbax/features/ruler/data/ruler_calibration_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns the default px-per-cm before any calibration is saved', () async {
    SharedPreferences.setMockInitialValues(const {});
    final repository = RulerCalibrationRepository(
      await SharedPreferences.getInstance(),
    );

    expect(repository.getPxPerCm(), RulerCalibrationRepository.defaultPxPerCm);
  });

  test('persists a calibrated value across repository instances', () async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    final repository = RulerCalibrationRepository(prefs);

    await repository.savePxPerCm(75.0);

    expect(RulerCalibrationRepository(prefs).getPxPerCm(), 75.0);
  });
}
