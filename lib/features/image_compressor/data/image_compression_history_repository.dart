import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/image_compression_history_entry.dart';

class ImageCompressionHistoryRepository {
  ImageCompressionHistoryRepository(this._prefs);

  static const String _key = 'image_compression_history';
  static const int _maxEntries = 20;

  final SharedPreferences _prefs;

  List<ImageCompressionHistoryEntry> getEntries() {
    final String? raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ImageCompressionHistoryEntry.tryParse)
          .whereType<ImageCompressionHistoryEntry>()
          .toList();
    } on FormatException {
      return const [];
    }
  }

  Future<void> addEntry(ImageCompressionHistoryEntry entry) {
    final List<ImageCompressionHistoryEntry> entries = [
      entry,
      ...getEntries(),
    ].take(_maxEntries).toList();
    return _save(entries);
  }

  Future<void> removeAt(int index) {
    final List<ImageCompressionHistoryEntry> entries = getEntries();
    if (index < 0 || index >= entries.length) return Future.value();
    entries.removeAt(index);
    return _save(entries);
  }

  Future<void> clear() => _prefs.remove(_key);

  Future<void> _save(List<ImageCompressionHistoryEntry> entries) {
    return _prefs.setString(
      _key,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }
}
