import 'package:flutter_test/flutter_test.dart';
import 'package:toolbax/features/video_compressor/domain/output_resolution.dart';

void main() {
  group('OutputResolution.resolve', () {
    test('original never overrides the source resolution', () {
      expect(OutputResolution.original.resolve(1920, 1080), isNull);
      expect(OutputResolution.original.resolve(120, 90), isNull);
    });

    test('scales a landscape source down, preserving aspect ratio', () {
      final (int, int)? result = OutputResolution.p720.resolve(1920, 1080);
      expect(result, (1280, 720));
    });

    test('scales a portrait source down, keeping width as the short side', () {
      final (int, int)? result = OutputResolution.p720.resolve(1080, 1920);
      expect(result, (720, 1280));
    });

    test('never upscales when the source is already smaller than the target', () {
      expect(OutputResolution.p1080.resolve(640, 360), isNull);
    });

    test('treats a source exactly at the target short side as already fine', () {
      expect(OutputResolution.p720.resolve(1280, 720), isNull);
    });

    test('rounds both output dimensions down to even numbers', () {
      final (int, int)? result = OutputResolution.p480.resolve(1921, 1081);
      expect(result, isNotNull);
      expect(result!.$1.isEven, isTrue);
      expect(result.$2.isEven, isTrue);
    });

    test('a square source resolves without throwing', () {
      final (int, int)? result = OutputResolution.p480.resolve(1000, 1000);
      expect(result, isNotNull);
      expect(result!.$1, 480);
      expect(result.$2, 480);
    });
  });
}
