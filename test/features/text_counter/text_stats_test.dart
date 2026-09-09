import 'package:flutter_test/flutter_test.dart';
import 'package:toolbax/features/text_counter/domain/text_stats.dart';

void main() {
  test('counts visible Unicode characters rather than UTF-16 units', () {
    expect(computeTextStats('👨‍👩‍👧‍👦 👍🏽 e\u0301').characters, 5);
    expect(computeTextStats('👨‍👩‍👧‍👦 👍🏽 e\u0301').charactersNoSpaces, 3);
  });
  test('empty text has zero of everything', () {
    final TextStats stats = computeTextStats('');

    expect(stats.characters, 0);
    expect(stats.charactersNoSpaces, 0);
    expect(stats.words, 0);
    expect(stats.lines, 0);
  });

  test('counts characters, words and lines for a simple sentence', () {
    final TextStats stats = computeTextStats('سلام دنیا');

    expect(stats.characters, 9);
    expect(stats.charactersNoSpaces, 8);
    expect(stats.words, 2);
    expect(stats.lines, 1);
  });

  test('counts multiple lines and collapses repeated whitespace between '
      'words', () {
    final TextStats stats = computeTextStats('خط اول\nخط   دوم\nخط سوم');

    expect(stats.lines, 3);
    expect(stats.words, 6);
  });

  test('trims leading/trailing whitespace before counting words', () {
    final TextStats stats = computeTextStats('   یک کلمه   ');

    expect(stats.words, 2);
  });
}
