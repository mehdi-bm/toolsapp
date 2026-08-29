import 'package:intl/intl.dart';

String toPersianNumber(num value, {int decimalDigits = 0}) {
  final String pattern = decimalDigits > 0
      ? '#,##0.${'0' * decimalDigits}'
      : '#,##0';
  return NumberFormat(pattern, 'fa').format(value);
}
