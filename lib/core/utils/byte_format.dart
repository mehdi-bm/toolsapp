import 'persian_numbers.dart';

/// Formats a byte count as a human-readable Persian string, e.g. `"۱۲.۴ مگابایت"`.
String formatFileSize(int bytes) {
  const int kb = 1024;
  const int mb = kb * 1024;
  const int gb = mb * 1024;

  if (bytes >= gb) return '${toPersianNumber(bytes / gb, decimalDigits: 2)} گیگابایت';
  if (bytes >= mb) return '${toPersianNumber(bytes / mb, decimalDigits: 1)} مگابایت';
  if (bytes >= kb) return '${toPersianNumber(bytes / kb, decimalDigits: 0)} کیلوبایت';
  return '${toPersianNumber(bytes)} بایت';
}
