import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbax/features/favorites/data/favorites_repository.dart';

void main() {
  test('returns an empty set before any favorite is saved', () async {
    SharedPreferences.setMockInitialValues(const {});
    final repository = FavoritesRepository(
      await SharedPreferences.getInstance(),
    );

    expect(repository.getFavoriteIds(), isEmpty);
  });

  test('persists favorite ids across repository instances', () async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    final repository = FavoritesRepository(prefs);

    await repository.saveFavoriteIds({'ruler', 'compass'});

    expect(FavoritesRepository(prefs).getFavoriteIds(), {'ruler', 'compass'});
  });
}
