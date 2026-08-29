import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:toolbax/core/utils/compass_math.dart';

void main() {
  test('device flat, magnetic north along the device Y axis -> azimuth 0', () {
    final double? azimuth = computeAzimuthRadians(
      gravityX: 0,
      gravityY: 0,
      gravityZ: 1,
      magneticX: 0,
      magneticY: 1,
      magneticZ: 0,
    );

    expect(azimuth, isNotNull);
    expect(azimuth, closeTo(0, 1e-9));
  });

  test(
    'device flat, magnetic north along the device X axis -> azimuth -90deg '
    '(device is facing west, since north is to its right)',
    () {
      final double? azimuth = computeAzimuthRadians(
        gravityX: 0,
        gravityY: 0,
        gravityZ: 1,
        magneticX: 1,
        magneticY: 0,
        magneticZ: 0,
      );

      expect(azimuth, isNotNull);
      expect(azimuth, closeTo(-math.pi / 2, 1e-9));
    },
  );

  test('device flat, magnetic north behind the device -> azimuth ±180deg', () {
    final double? azimuth = computeAzimuthRadians(
      gravityX: 0,
      gravityY: 0,
      gravityZ: 1,
      magneticX: 0,
      magneticY: -1,
      magneticZ: 0,
    );

    expect(azimuth, isNotNull);
    expect(azimuth!.abs(), closeTo(math.pi, 1e-9));
  });

  test('returns null when the magnetic field is degenerate (parallel to '
      'gravity, e.g. faulty sensor)', () {
    final double? azimuth = computeAzimuthRadians(
      gravityX: 0,
      gravityY: 0,
      gravityZ: 1,
      magneticX: 0,
      magneticY: 0,
      magneticZ: 1,
    );

    expect(azimuth, isNull);
  });

  test('returns null when gravity is degenerate (e.g. device in free fall)', () {
    final double? azimuth = computeAzimuthRadians(
      gravityX: 0,
      gravityY: 0,
      gravityZ: 0,
      magneticX: 0,
      magneticY: 1,
      magneticZ: 0,
    );

    expect(azimuth, isNull);
  });
}
