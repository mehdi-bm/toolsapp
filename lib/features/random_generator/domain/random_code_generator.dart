import 'dart:math';

const String kNumericChars = '0123456789';
const String kAlphanumericChars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

String generateRandomCode({
  required int length,
  required bool alphanumeric,
  required Random random,
}) {
  if (length <= 0) return '';
  final String pool = alphanumeric ? kAlphanumericChars : kNumericChars;
  return List.generate(length, (_) => pool[random.nextInt(pool.length)]).join();
}
