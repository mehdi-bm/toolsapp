import 'package:flutter_test/flutter_test.dart';
import 'package:toolbax/features/app_support/domain/phone_number_validator.dart';

void main() {
  test('accepts a plain Latin-digit phone number', () {
    expect(isValidPhoneNumber('09123456789'), isTrue);
  });

  test('accepts Persian digits', () {
    expect(isValidPhoneNumber('۰۹۱۲۳۴۵۶۷۸۹'), isTrue);
  });

  test('accepts Arabic-Indic digits', () {
    expect(isValidPhoneNumber('٠٩١٢٣٤٥٦٧٨٩'), isTrue);
  });

  test('accepts a number with +, spaces, dashes and parentheses', () {
    expect(isValidPhoneNumber('+98 (912) 345-6789'), isTrue);
  });

  test('rejects a number with too few digits', () {
    expect(isValidPhoneNumber('12345'), isFalse);
  });

  test('rejects a number with too many digits', () {
    expect(isValidPhoneNumber('1' * 21), isFalse);
  });

  test('counts only digit characters, ignoring separators', () {
    expect(countPhoneDigits('09-123-456-789'), 11);
  });
}
