import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/speed_test_history_entry.dart';

class SpeedTestHistoryRepository {
  SpeedTestHistoryRepository(this._prefs);

  static const String _key = 'speed_test_history';
  static const int _maxEntries = 30;

  final SharedPreferences _prefs;

  List<SpeedTestHistoryEntry> getEntries() {
    final String? raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(SpeedTestHistoryEntry.tryParse)
          .whereType<SpeedTestHistoryEntry>()
          .toList();
    } on FormatException {
      return const [];
    }
  }

  Future<void> addEntry(SpeedTestHistoryEntry entry) {
    final List<SpeedTestHistoryEntry> entries = [
      entry,
      ...getEntries(),
    ].take(_maxEntries).toList();
    return _save(entries);
  }

  Future<void> clear() => _prefs.remove(_key);

  Future<void> _save(List<SpeedTestHistoryEntry> entries) {
    return _prefs.setString(
      _key,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }
}
