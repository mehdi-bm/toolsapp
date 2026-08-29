import 'dart:math';

const String kUppercaseChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const String kLowercaseChars = 'abcdefghijklmnopqrstuvwxyz';
const String kNumberChars = '0123456789';
const String kSymbolChars = '!@#\$%^&*()-_=+[]{}<>?';

String buildPasswordCharacterPool({
  required bool useUppercase,
  required bool useLowercase,
  required bool useNumbers,
  required bool useSymbols,
}) {
  final StringBuffer buffer = StringBuffer();
  if (useUppercase) buffer.write(kUppercaseChars);
  if (useLowercase) buffer.write(kLowercaseChars);
  if (useNumbers) buffer.write(kNumberChars);
  if (useSymbols) buffer.write(kSymbolChars);
  return buffer.toString();
}

String generatePassword({
  required int length,
  required bool useUppercase,
  required bool useLowercase,
  required bool useNumbers,
  required bool useSymbols,
  required Random random,
}) {
  final String pool = buildPasswordCharacterPool(
    useUppercase: useUppercase,
    useLowercase: useLowercase,
    useNumbers: useNumbers,
    useSymbols: useSymbols,
  );
  if (pool.isEmpty || length <= 0) return '';
  return List.generate(
    length,
    (_) => pool[random.nextInt(pool.length)],
  ).join();
}
