import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/audio_conversion_history_entry.dart';

class AudioConversionHistoryRepository {
  AudioConversionHistoryRepository(this._prefs);

  static const String _key = 'audio_conversion_history';
  static const int _maxEntries = 20;

  final SharedPreferences _prefs;

  List<AudioConversionHistoryEntry> getEntries() {
    final String? raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(AudioConversionHistoryEntry.tryParse)
          .whereType<AudioConversionHistoryEntry>()
          .toList();
    } on FormatException {
      return const [];
    }
  }

  Future<void> addEntry(AudioConversionHistoryEntry entry) {
    final List<AudioConversionHistoryEntry> entries = [
      entry,
      ...getEntries(),
    ].take(_maxEntries).toList();
    return _save(entries);
  }

  Future<void> removeAt(int index) {
    final List<AudioConversionHistoryEntry> entries = getEntries();
    if (index < 0 || index >= entries.length) return Future.value();
    entries.removeAt(index);
    return _save(entries);
  }

  Future<void> clear() => _prefs.remove(_key);

  Future<void> _save(List<AudioConversionHistoryEntry> entries) {
    return _prefs.setString(
      _key,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }
}
