import 'package:flutter_test/flutter_test.dart';
import 'package:toolbax/features/text_cleaner/domain/text_cleaner.dart';

void main() {
  test('collapses repeated horizontal whitespace into a single space', () {
    final String result = cleanText(
      'یک   دو    سه',
      const TextCleanerOptions(
        collapseSpaces: true,
        removeEmptyLines: false,
        normalizeLineBreaks: false,
        trimEdges: false,
        normalizeArabicChars: false,
      ),
    );

    expect(result, 'یک دو سه');
  });

  test('removes empty lines while keeping non-empty ones', () {
    final String result = cleanText(
      'خط اول\n\n   \nخط دوم',
      const TextCleanerOptions(
        collapseSpaces: false,
        removeEmptyLines: true,
        normalizeLineBreaks: false,
        trimEdges: false,
        normalizeArabicChars: false,
      ),
    );

    expect(result, 'خط اول\nخط دوم');
  });

  test('normalizes Windows/Mac line breaks to \\n', () {
    final String result = cleanText(
      'یک\r\nدو\rسه',
      const TextCleanerOptions(
        collapseSpaces: false,
        removeEmptyLines: false,
        normalizeLineBreaks: true,
        trimEdges: false,
        normalizeArabicChars: false,
      ),
    );

    expect(result, 'یک\nدو\nسه');
  });

  test('trims leading and trailing whitespace', () {
    final String result = cleanText(
      '   متن   ',
      const TextCleanerOptions(
        collapseSpaces: false,
        removeEmptyLines: false,
        normalizeLineBreaks: false,
        trimEdges: true,
        normalizeArabicChars: false,
      ),
    );

    expect(result, 'متن');
  });

  test('converts Arabic ي and ك to Persian ی and ک', () {
    final String result = cleanText(
      'علي و كتاب',
      const TextCleanerOptions(
        collapseSpaces: false,
        removeEmptyLines: false,
        normalizeLineBreaks: false,
        trimEdges: false,
        normalizeArabicChars: true,
      ),
    );

    expect(result, 'علی و کتاب');
  });

  test('leaves text unchanged when every option is disabled', () {
    const String messy = '  علي   \r\n\n  كتاب  ';
    final String result = cleanText(
      messy,
      const TextCleanerOptions(
        collapseSpaces: false,
        removeEmptyLines: false,
        normalizeLineBreaks: false,
        trimEdges: false,
        normalizeArabicChars: false,
      ),
    );

    expect(result, messy);
  });
}
