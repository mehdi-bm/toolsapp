import 'package:flutter_test/flutter_test.dart';
import 'package:toolbax/features/speed_test/domain/connection_quality.dart';

void main() {
  group('ConnectionQuality.fromDownloadMbps', () {
    test('under 5 Mbps is weak', () {
      expect(
        ConnectionQuality.fromDownloadMbps(0),
        ConnectionQuality.weak,
      );
      expect(
        ConnectionQuality.fromDownloadMbps(4.9),
        ConnectionQuality.weak,
      );
    });

    test('5 to just under 25 Mbps is medium', () {
      expect(
        ConnectionQuality.fromDownloadMbps(5),
        ConnectionQuality.medium,
      );
      expect(
        ConnectionQuality.fromDownloadMbps(24.9),
        ConnectionQuality.medium,
      );
    });

    test('25 Mbps and above is excellent', () {
      expect(
        ConnectionQuality.fromDownloadMbps(25),
        ConnectionQuality.excellent,
      );
      expect(
        ConnectionQuality.fromDownloadMbps(200),
        ConnectionQuality.excellent,
      );
    });
  });
}
