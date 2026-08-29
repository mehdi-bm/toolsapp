import 'dart:math' as math;

/// Computes compass azimuth (radians, 0 = north, increasing clockwise
/// toward east) from raw accelerometer (gravity) and magnetometer readings.
///
/// This is a direct port of the algorithm behind Android's
/// `SensorManager.getRotationMatrix` + `getOrientation`, the reference
/// implementation used by native Android compass apps. Returns null when
/// the readings are degenerate (e.g. device in free fall).
double? computeAzimuthRadians({
  required double gravityX,
  required double gravityY,
  required double gravityZ,
  required double magneticX,
  required double magneticY,
  required double magneticZ,
}) {
  final double hxRaw = magneticY * gravityZ - magneticZ * gravityY;
  final double hyRaw = magneticZ * gravityX - magneticX * gravityZ;
  final double hzRaw = magneticX * gravityY - magneticY * gravityX;

  final double normH = math.sqrt(hxRaw * hxRaw + hyRaw * hyRaw + hzRaw * hzRaw);
  if (normH < 0.1) return null;
  final double hx = hxRaw / normH;
  final double hy = hyRaw / normH;
  final double hz = hzRaw / normH;

  final double normA = math.sqrt(
    gravityX * gravityX + gravityY * gravityY + gravityZ * gravityZ,
  );
  if (normA < 1e-6) return null;
  final double ax = gravityX / normA;
  final double az = gravityZ / normA;

  final double northY = az * hx - ax * hz;

  return math.atan2(hy, northY);
}
