import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:toolbax/features/level/data/level_calibration_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults both offsets to zero before calibration', () async {
    SharedPreferences.setMockInitialValues(const {});
    final repository = LevelCalibrationRepository(
      await SharedPreferences.getInstance(),
    );

    expect(repository.getRollOffset(), 0);
    expect(repository.getPitchOffset(), 0);
  });

  test('persists calibrated offsets across repository instances', () async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    final repository = LevelCalibrationRepository(prefs);

    await repository.saveOffsets(roll: 3.5, pitch: -2.1);

    final reloaded = LevelCalibrationRepository(prefs);
    expect(reloaded.getRollOffset(), 3.5);
    expect(reloaded.getPitchOffset(), -2.1);
  });
}
