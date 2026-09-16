import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbax/features/speed_test/data/speed_test_history_repository.dart';
import 'package:toolbax/features/speed_test/domain/connection_type.dart';
import 'package:toolbax/features/speed_test/domain/speed_test_history_entry.dart';

SpeedTestHistoryEntry _entry({required DateTime testedAt, String? carrier}) =>
    SpeedTestHistoryEntry(
      downloadMbps: 42.5,
      uploadMbps: 12.3,
      pingMs: 28,
      connectionType: ConnectionType.wifi,
      carrierName: carrier,
      testedAt: testedAt,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns an empty list before any test has run', () async {
    SharedPreferences.setMockInitialValues(const {});
    final repository = SpeedTestHistoryRepository(
      await SharedPreferences.getInstance(),
    );

    expect(repository.getEntries(), isEmpty);
  });

  test('newest entry is added first and round-trips through JSON', () async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    final repository = SpeedTestHistoryRepository(prefs);
    final DateTime first = DateTime(2026, 9, 1);
    final DateTime second = DateTime(2026, 9, 2);

    await repository.addEntry(_entry(testedAt: first, carrier: 'Irancell'));
    await repository.addEntry(_entry(testedAt: second));

    final entries = SpeedTestHistoryRepository(prefs).getEntries();
    expect(entries, hasLength(2));
    expect(entries.first.testedAt, second);
    expect(entries.last.testedAt, first);
    expect(entries.last.carrierName, 'Irancell');
    expect(entries.first.carrierName, isNull);
    expect(entries.first.connectionType, ConnectionType.wifi);
  });

  test('caps stored history at 30 entries, keeping the newest', () async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    final repository = SpeedTestHistoryRepository(prefs);

    for (int i = 0; i < 35; i++) {
      await repository.addEntry(
        _entry(testedAt: DateTime(2026, 1, 1).add(Duration(days: i))),
      );
    }

    final entries = repository.getEntries();
    expect(entries, hasLength(30));
    expect(entries.first.testedAt, DateTime(2026, 1, 1).add(const Duration(days: 34)));
  });

  test('clear removes every entry', () async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    final repository = SpeedTestHistoryRepository(prefs);
    await repository.addEntry(_entry(testedAt: DateTime(2026, 9, 1)));

    await repository.clear();

    expect(repository.getEntries(), isEmpty);
  });
}
