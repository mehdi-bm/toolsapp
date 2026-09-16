import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbax/features/video_compressor/data/compression_history_repository.dart';
import 'package:toolbax/features/video_compressor/domain/compression_history_entry.dart';

const CompressionHistoryEntry _kEntryA = CompressionHistoryEntry(
  sourceName: 'a.mp4',
  outputPath: '/tmp/a-compressed.mp4',
  originalSize: 2000,
  compressedSize: 500,
);

const CompressionHistoryEntry _kEntryB = CompressionHistoryEntry(
  sourceName: 'b.mp4',
  outputPath: '/tmp/b-compressed.mp4',
  originalSize: 3000,
  compressedSize: 900,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns an empty list before anything is compressed', () async {
    SharedPreferences.setMockInitialValues(const {});
    final repository = CompressionHistoryRepository(
      await SharedPreferences.getInstance(),
    );

    expect(repository.getEntries(), isEmpty);
  });

  test('newest entry is added first and persists across instances', () async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    final repository = CompressionHistoryRepository(prefs);

    await repository.addEntry(_kEntryA);
    await repository.addEntry(_kEntryB);

    final List<CompressionHistoryEntry> entries =
        CompressionHistoryRepository(prefs).getEntries();
    expect(entries, hasLength(2));
    expect(entries.first.sourceName, 'b.mp4');
    expect(entries.last.sourceName, 'a.mp4');
  });

  test('removeAt drops only the targeted entry', () async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    final repository = CompressionHistoryRepository(prefs);
    await repository.addEntry(_kEntryA);
    await repository.addEntry(_kEntryB);

    await repository.removeAt(0);

    final List<CompressionHistoryEntry> entries = repository.getEntries();
    expect(entries, hasLength(1));
    expect(entries.single.sourceName, 'a.mp4');
  });

  test('clear removes every entry', () async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    final repository = CompressionHistoryRepository(prefs);
    await repository.addEntry(_kEntryA);

    await repository.clear();

    expect(repository.getEntries(), isEmpty);
  });

  test('caps stored history at 20 entries, keeping the newest', () async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    final repository = CompressionHistoryRepository(prefs);

    for (int i = 0; i < 25; i++) {
      await repository.addEntry(
        CompressionHistoryEntry(
          sourceName: 'video_$i.mp4',
          outputPath: '/tmp/$i.mp4',
          originalSize: 1000,
          compressedSize: 100,
        ),
      );
    }

    final List<CompressionHistoryEntry> entries = repository.getEntries();
    expect(entries, hasLength(20));
    expect(entries.first.sourceName, 'video_24.mp4');
  });
}
