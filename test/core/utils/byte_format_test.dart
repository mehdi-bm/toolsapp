import 'package:flutter_test/flutter_test.dart';
import 'package:toolbax/core/utils/byte_format.dart';

void main() {
  group('formatFileSize', () {
    test('formats bytes below 1 KB', () {
      expect(formatFileSize(500), '۵۰۰ بایت');
    });

    test('formats kilobytes', () {
      expect(formatFileSize(2048), '۲ کیلوبایت');
    });

    test('formats megabytes with one decimal', () {
      expect(formatFileSize(5 * 1024 * 1024), '۵٫۰ مگابایت');
    });

    test('formats gigabytes with two decimals', () {
      expect(formatFileSize(2 * 1024 * 1024 * 1024), '۲٫۰۰ گیگابایت');
    });
  });
}
