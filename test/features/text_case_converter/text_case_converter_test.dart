import 'package:flutter_test/flutter_test.dart';
import 'package:toolbax/features/text_case_converter/domain/text_case_converter.dart';

void main() {
  test('uppercases Latin letters and leaves Persian letters unchanged', () {
    expect(toUpperCaseSafe('hello سلام'), 'HELLO سلام');
  });

  test('lowercases Latin letters and leaves Persian letters unchanged', () {
    expect(toLowerCaseSafe('HELLO سلام'), 'hello سلام');
  });

  test('title-cases each word while preserving original spacing', () {
    expect(toTitleCase('hello   world'), 'Hello   World');
  });

  test('title case leaves Persian words unchanged (no case mapping) but '
      'still walks over them safely', () {
    expect(toTitleCase('سلام دنیا'), 'سلام دنیا');
  });

  test('title case works on mixed Persian/English text', () {
    expect(toTitleCase('سلام hello دنیا'), 'سلام Hello دنیا');
  });
}
