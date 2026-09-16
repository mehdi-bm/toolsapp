import 'connection_quality.dart';
import 'connection_type.dart';

class SpeedTestResult {
  const SpeedTestResult({
    required this.downloadMbps,
    required this.uploadMbps,
    required this.pingMs,
    required this.connectionType,
    required this.carrierName,
    required this.testedAt,
  });

  final double downloadMbps;
  final double uploadMbps;
  final int pingMs;
  final ConnectionType connectionType;
  final String? carrierName;
  final DateTime testedAt;

  ConnectionQuality get quality =>
      ConnectionQuality.fromDownloadMbps(downloadMbps);
}
