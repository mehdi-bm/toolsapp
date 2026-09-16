import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbax/features/image_compressor/data/image_compression_history_repository.dart';
import 'package:toolbax/features/image_compressor/domain/image_compression_history_entry.dart';

const ImageCompressionHistoryEntry _kEntryA = ImageCompressionHistoryEntry(
  sourceName: 'a.jpg',
  outputPath: '/tmp/a-compressed.jpg',
  originalSize: 8000000,
  compressedSize: 500000,
);

const ImageCompressionHistoryEntry _kEntryB = ImageCompressionHistoryEntry(
  sourceName: 'b.png',
  outputPath: '/tmp/b-compressed.jpg',
  originalSize: 5000000,
  compressedSize: 400000,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns an empty list before anything is compressed', () async {
    SharedPreferences.setMockInitialValues(const {});
    final repository = ImageCompressionHistoryRepository(
      await SharedPreferences.getInstance(),
    );

    expect(repository.getEntries(), isEmpty);
  });

  test('newest entry is added first and persists across instances', () async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    final repository = ImageCompressionHistoryRepository(prefs);

    await repository.addEntry(_kEntryA);
    await repository.addEntry(_kEntryB);

    final entries = ImageCompressionHistoryRepository(prefs).getEntries();
    expect(entries, hasLength(2));
    expect(entries.first.sourceName, 'b.png');
    expect(entries.last.sourceName, 'a.jpg');
  });

  test('removeAt drops only the targeted entry', () async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    final repository = ImageCompressionHistoryRepository(prefs);
    await repository.addEntry(_kEntryA);
    await repository.addEntry(_kEntryB);

    await repository.removeAt(0);

    final entries = repository.getEntries();
    expect(entries, hasLength(1));
    expect(entries.single.sourceName, 'a.jpg');
  });

  test('clear removes every entry', () async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    final repository = ImageCompressionHistoryRepository(prefs);
    await repository.addEntry(_kEntryA);

    await repository.clear();

    expect(repository.getEntries(), isEmpty);
  });
}
