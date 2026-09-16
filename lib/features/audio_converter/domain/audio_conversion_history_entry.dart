class AudioConversionHistoryEntry {
  const AudioConversionHistoryEntry({
    required this.sourceName,
    required this.outputPath,
    required this.originalSize,
    required this.convertedSize,
  });

  final String sourceName;
  final String outputPath;
  final int originalSize;
  final int convertedSize;

  Map<String, dynamic> toJson() => {
    'sourceName': sourceName,
    'outputPath': outputPath,
    'originalSize': originalSize,
    'convertedSize': convertedSize,
  };

  static AudioConversionHistoryEntry? tryParse(Map<String, dynamic> json) {
    final String? sourceName = json['sourceName'] as String?;
    final String? outputPath = json['outputPath'] as String?;
    final int? originalSize = (json['originalSize'] as num?)?.toInt();
    final int? convertedSize = (json['convertedSize'] as num?)?.toInt();
    if (sourceName == null ||
        outputPath == null ||
        originalSize == null ||
        convertedSize == null) {
      return null;
    }
    return AudioConversionHistoryEntry(
      sourceName: sourceName,
      outputPath: outputPath,
      originalSize: originalSize,
      convertedSize: convertedSize,
    );
  }
}
