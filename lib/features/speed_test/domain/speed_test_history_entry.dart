import 'connection_type.dart';

class SpeedTestHistoryEntry {
  const SpeedTestHistoryEntry({
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

  Map<String, dynamic> toJson() => {
    'downloadMbps': downloadMbps,
    'uploadMbps': uploadMbps,
    'pingMs': pingMs,
    'connectionType': connectionType.name,
    'carrierName': carrierName,
    'testedAt': testedAt.toIso8601String(),
  };

  static SpeedTestHistoryEntry? tryParse(Map<String, dynamic> json) {
    final double? downloadMbps = (json['downloadMbps'] as num?)?.toDouble();
    final double? uploadMbps = (json['uploadMbps'] as num?)?.toDouble();
    final int? pingMs = (json['pingMs'] as num?)?.toInt();
    final String? connectionTypeName = json['connectionType'] as String?;
    final String? testedAtRaw = json['testedAt'] as String?;
    if (downloadMbps == null ||
        uploadMbps == null ||
        pingMs == null ||
        connectionTypeName == null ||
        testedAtRaw == null) {
      return null;
    }
    final DateTime? testedAt = DateTime.tryParse(testedAtRaw);
    if (testedAt == null) return null;

    final ConnectionType connectionType = ConnectionType.values.firstWhere(
      (t) => t.name == connectionTypeName,
      orElse: () => ConnectionType.other,
    );

    return SpeedTestHistoryEntry(
      downloadMbps: downloadMbps,
      uploadMbps: uploadMbps,
      pingMs: pingMs,
      connectionType: connectionType,
      carrierName: json['carrierName'] as String?,
      testedAt: testedAt,
    );
  }
}
