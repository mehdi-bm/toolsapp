class CompressionHistoryEntry {
  const CompressionHistoryEntry({
    required this.sourceName,
    required this.outputPath,
    required this.originalSize,
    required this.compressedSize,
  });

  final String sourceName;
  final String outputPath;
  final int originalSize;
  final int compressedSize;

  Map<String, dynamic> toJson() => {
    'sourceName': sourceName,
    'outputPath': outputPath,
    'originalSize': originalSize,
    'compressedSize': compressedSize,
  };

  static CompressionHistoryEntry? tryParse(Map<String, dynamic> json) {
    final String? sourceName = json['sourceName'] as String?;
    final String? outputPath = json['outputPath'] as String?;
    final int? originalSize = (json['originalSize'] as num?)?.toInt();
    final int? compressedSize = (json['compressedSize'] as num?)?.toInt();
    if (sourceName == null ||
        outputPath == null ||
        originalSize == null ||
        compressedSize == null) {
      return null;
    }
    return CompressionHistoryEntry(
      sourceName: sourceName,
      outputPath: outputPath,
      originalSize: originalSize,
      compressedSize: compressedSize,
    );
  }
}
