import 'package:light_compressor_v2/light_compressor_v2.dart';

/// How aggressively to compress the video. Named by compression intensity
/// (not output quality), which is the inverse: a "high" compression level
/// maps to a *lower* [VideoQuality] preset.
enum CompressionLevel {
  low,
  medium,
  high;

  String get label => switch (this) {
    CompressionLevel.low => 'کم',
    CompressionLevel.medium => 'متوسط',
    CompressionLevel.high => 'زیاد',
  };

  VideoQuality get videoQuality => switch (this) {
    CompressionLevel.low => VideoQuality.high,
    CompressionLevel.medium => VideoQuality.medium,
    CompressionLevel.high => VideoQuality.low,
  };
}
