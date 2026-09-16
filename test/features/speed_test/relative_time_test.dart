import 'package:flutter_test/flutter_test.dart';
import 'package:toolbax/features/speed_test/domain/relative_time.dart';

void main() {
  final DateTime now = DateTime(2026, 9, 15, 12, 0, 0);

  group('formatRelativeTime', () {
    test('under a minute reads as "چند لحظه پیش"', () {
      expect(
        formatRelativeTime(now.subtract(const Duration(seconds: 10)), now: now),
        'چند لحظه پیش',
      );
    });

    test('minutes ago', () {
      expect(
        formatRelativeTime(now.subtract(const Duration(minutes: 5)), now: now),
        '۵ دقیقه پیش',
      );
    });

    test('hours ago', () {
      expect(
        formatRelativeTime(now.subtract(const Duration(hours: 3)), now: now),
        '۳ ساعت پیش',
      );
    });

    test('exactly one day ago reads as "دیروز"', () {
      expect(
        formatRelativeTime(now.subtract(const Duration(days: 1)), now: now),
        'دیروز',
      );
    });

    test('days ago', () {
      expect(
        formatRelativeTime(now.subtract(const Duration(days: 5)), now: now),
        '۵ روز پیش',
      );
    });

    test('months ago', () {
      expect(
        formatRelativeTime(now.subtract(const Duration(days: 60)), now: now),
        '۲ ماه پیش',
      );
    });
  });
}
