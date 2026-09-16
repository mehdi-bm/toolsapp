import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbax/features/audio_converter/data/audio_conversion_history_repository.dart';
import 'package:toolbax/features/audio_converter/domain/audio_conversion_history_entry.dart';

const AudioConversionHistoryEntry _kEntryA = AudioConversionHistoryEntry(
  sourceName: 'a.m4a',
  outputPath: '/tmp/a.mp3',
  originalSize: 4000,
  convertedSize: 1200,
);

const AudioConversionHistoryEntry _kEntryB = AudioConversionHistoryEntry(
  sourceName: 'b.wav',
  outputPath: '/tmp/b.mp3',
  originalSize: 9000,
  convertedSize: 2200,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns an empty list before anything is converted', () async {
    SharedPreferences.setMockInitialValues(const {});
    final repository = AudioConversionHistoryRepository(
      await SharedPreferences.getInstance(),
    );

    expect(repository.getEntries(), isEmpty);
  });

  test('newest entry is added first and persists across instances', () async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    final repository = AudioConversionHistoryRepository(prefs);

    await repository.addEntry(_kEntryA);
    await repository.addEntry(_kEntryB);

    final entries = AudioConversionHistoryRepository(prefs).getEntries();
    expect(entries, hasLength(2));
    expect(entries.first.sourceName, 'b.wav');
    expect(entries.last.sourceName, 'a.m4a');
  });

  test('removeAt drops only the targeted entry', () async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    final repository = AudioConversionHistoryRepository(prefs);
    await repository.addEntry(_kEntryA);
    await repository.addEntry(_kEntryB);

    await repository.removeAt(0);

    final entries = repository.getEntries();
    expect(entries, hasLength(1));
    expect(entries.single.sourceName, 'a.m4a');
  });

  test('clear removes every entry', () async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    final repository = AudioConversionHistoryRepository(prefs);
    await repository.addEntry(_kEntryA);

    await repository.clear();

    expect(repository.getEntries(), isEmpty);
  });
}
