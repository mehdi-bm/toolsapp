import 'package:flutter_test/flutter_test.dart';
import 'package:toolbax/features/image_compressor/domain/target_size_compressor.dart';

/// Simulates a monotonic quality->size relationship: size scales linearly
/// with quality, from ~5% of [maxSize] at quality 1 up to [maxSize] at
/// quality 100.
Future<int> Function(int) _fakeCompressor(int maxSize) {
  return (int quality) async => (maxSize * quality / 100).round();
}

void main() {
  group('findQualityForTargetSize', () {
    test('finds the highest quality that still fits under the target', () async {
      // maxSize=1,000,000 bytes at quality 100 -> quality q gives q*10,000
      // bytes. Target 550,000 should land on quality 55 (550,000 exactly
      // fits; 56 would be 560,000, over target).
      final int quality = await findQualityForTargetSize(
        compressAt: _fakeCompressor(1000000),
        targetBytes: 550000,
      );
      expect(quality, 55);
    });

    test('returns minQuality when even the lowest quality exceeds the target', () async {
      final int quality = await findQualityForTargetSize(
        compressAt: _fakeCompressor(1000000),
        targetBytes: 100, // far below what quality 5 (50,000 bytes) can hit
      );
      expect(quality, 5);
    });

    test('returns maxQuality when the smallest output is already under target', () async {
      final int quality = await findQualityForTargetSize(
        compressAt: _fakeCompressor(100), // quality 95 -> 95 bytes
        targetBytes: 1000000,
      );
      expect(quality, 95);
    });

    test('respects custom minQuality/maxQuality bounds', () async {
      final int quality = await findQualityForTargetSize(
        compressAt: _fakeCompressor(1000000),
        targetBytes: 1000000,
        minQuality: 20,
        maxQuality: 60,
      );
      expect(quality, 60);
    });
  });
}
