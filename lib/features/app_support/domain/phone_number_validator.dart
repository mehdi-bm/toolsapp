/// Matches Latin, Arabic-Indic, and Persian (Extended Arabic-Indic) digits.
final RegExp _digitPattern = RegExp(r'[0-9٠-٩۰-۹]');

int countPhoneDigits(String input) {
  int count = 0;
  for (final int rune in input.runes) {
    if (_digitPattern.hasMatch(String.fromCharCode(rune))) count++;
  }
  return count;
}

bool isValidPhoneNumber(String input) {
  final int digits = countPhoneDigits(input);
  return digits >= 7 && digits <= 20;
}
