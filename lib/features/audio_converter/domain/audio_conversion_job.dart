enum AudioConversionStatus { pending, running, success, failed, cancelled }

/// One file within a batch conversion, tracked through its lifecycle.
class AudioConversionJob {
  AudioConversionJob({
    required this.sourcePath,
    required this.sourceName,
    required this.sourceSizeBytes,
  });

  final String sourcePath;
  final String sourceName;
  final int sourceSizeBytes;

  AudioConversionStatus status = AudioConversionStatus.pending;
  double progress = 0;
  String? outputPath;
  int? outputSizeBytes;
  String? errorMessage;
}
