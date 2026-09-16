import 'package:flutter_test/flutter_test.dart';
import 'package:light_compressor_v2/light_compressor_v2.dart';
import 'package:toolbax/features/video_compressor/domain/compression_level.dart';

void main() {
  group('CompressionLevel', () {
    test('a higher compression amount maps to a lower output quality', () {
      // "زیاد" (high compression) must shrink the file more than "کم" (low
      // compression) — i.e. it maps to a *lower* VideoQuality preset, the
      // inverse of the enum's own ordering.
      expect(CompressionLevel.low.videoQuality, VideoQuality.high);
      expect(CompressionLevel.medium.videoQuality, VideoQuality.medium);
      expect(CompressionLevel.high.videoQuality, VideoQuality.low);
    });

    test('labels are the expected Persian compression-intensity words', () {
      expect(CompressionLevel.low.label, 'کم');
      expect(CompressionLevel.medium.label, 'متوسط');
      expect(CompressionLevel.high.label, 'زیاد');
    });
  });
}
