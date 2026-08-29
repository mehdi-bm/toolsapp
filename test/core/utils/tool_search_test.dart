import 'package:flutter_test/flutter_test.dart';
import 'package:toolbax/core/utils/tool_search.dart';

void main() {
  test('an empty or whitespace-only query returns no results', () {
    expect(filterTools(''), isEmpty);
    expect(filterTools('   '), isEmpty);
  });

  test('matches tools whose title contains the query', () {
    final results = filterTools('رمز');

    expect(results.map((tool) => tool.id), contains('password_generator'));
  });

  test('matching is case-insensitive for Latin substrings like QR', () {
    final lower = filterTools('qr').map((tool) => tool.id).toSet();
    final upper = filterTools('QR').map((tool) => tool.id).toSet();

    expect(lower, upper);
    expect(lower, containsAll(['qr_scanner', 'qr_generator']));
  });

  test('returns an empty list when nothing matches', () {
    expect(filterTools('زززچمقچمق'), isEmpty);
  });

  test('"متن" matches the text cleaner tool by substring', () {
    final results = filterTools('متن');

    expect(results.map((tool) => tool.id), contains('text_cleaner'));
  });
}
