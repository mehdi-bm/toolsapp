import '../../../core/utils/persian_numbers.dart';

/// Formats [dateTime] relative to [now] as a short Persian phrase, e.g.
/// `"۵ دقیقه پیش"`. Avoids needing a Jalali calendar library — comparisons
/// for history entries only need a rough sense of recency, not exact dates.
String formatRelativeTime(DateTime dateTime, {DateTime? now}) {
  final DateTime reference = now ?? DateTime.now();
  final Duration diff = reference.difference(dateTime);

  if (diff.inSeconds < 60) return 'چند لحظه پیش';
  if (diff.inMinutes < 60) {
    return '${toPersianNumber(diff.inMinutes)} دقیقه پیش';
  }
  if (diff.inHours < 24) return '${toPersianNumber(diff.inHours)} ساعت پیش';
  if (diff.inDays == 1) return 'دیروز';
  if (diff.inDays < 30) return '${toPersianNumber(diff.inDays)} روز پیش';
  if (diff.inDays < 365) {
    return '${toPersianNumber(diff.inDays ~/ 30)} ماه پیش';
  }
  return '${toPersianNumber(diff.inDays ~/ 365)} سال پیش';
}
