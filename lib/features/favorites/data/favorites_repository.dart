import 'package:shared_preferences/shared_preferences.dart';

class FavoritesRepository {
  FavoritesRepository(this._prefs);

  static const String _key = 'favorite_tool_ids';

  final SharedPreferences _prefs;

  Set<String> getFavoriteIds() {
    return _prefs.getStringList(_key)?.toSet() ?? <String>{};
  }

  Future<void> saveFavoriteIds(Set<String> ids) {
    return _prefs.setStringList(_key, ids.toList());
  }
}
