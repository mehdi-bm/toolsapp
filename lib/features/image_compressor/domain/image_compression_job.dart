enum ImageCompressionStatus { pending, running, success, failed }

/// One image within a batch compression, tracked through its lifecycle.
class ImageCompressionJob {
  ImageCompressionJob({
    required this.sourcePath,
    required this.sourceName,
    required this.sourceSizeBytes,
  });

  final String sourcePath;
  final String sourceName;
  final int sourceSizeBytes;

  ImageCompressionStatus status = ImageCompressionStatus.pending;
  String? outputPath;
  int? outputSizeBytes;
  String? errorMessage;
}
