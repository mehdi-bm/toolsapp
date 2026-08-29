import 'package:shared_preferences/shared_preferences.dart';

class RecentToolsRepository {
  RecentToolsRepository(this._prefs);

  static const String _key = 'recent_tool_ids';
  static const int maxItems = 10;

  final SharedPreferences _prefs;

  List<String> getRecentIds() => _prefs.getStringList(_key) ?? const [];

  Future<void> saveRecentIds(List<String> ids) {
    return _prefs.setStringList(_key, ids);
  }
}
