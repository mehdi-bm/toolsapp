import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbax/features/home/data/recent_tools_repository.dart';

void main() {
  test('returns an empty list before anything is saved', () async {
    SharedPreferences.setMockInitialValues(const {});
    final repository = RecentToolsRepository(
      await SharedPreferences.getInstance(),
    );

    expect(repository.getRecentIds(), isEmpty);
  });

  test('persists the recent-id order across repository instances', () async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    final repository = RecentToolsRepository(prefs);

    await repository.saveRecentIds(['ruler', 'compass', 'level']);

    expect(RecentToolsRepository(prefs).getRecentIds(), [
      'ruler',
      'compass',
      'level',
    ]);
  });
}
