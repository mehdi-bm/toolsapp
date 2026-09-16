import 'package:flutter_test/flutter_test.dart';
import 'package:toolbax/features/app_sharing/domain/app_sort_option.dart';
import 'package:toolbax/features/app_sharing/domain/installed_app.dart';

InstalledApp _app({
  required String name,
  required int sizeBytes,
  required DateTime installTime,
}) => InstalledApp(
  packageName: 'com.example.${name.toLowerCase()}',
  appName: name,
  versionName: '1.0',
  versionCode: 1,
  firstInstallTime: installTime,
  lastUpdateTime: installTime,
  apkPath: '/data/app/${name.toLowerCase()}/base.apk',
  splitApkPaths: const [],
  sizeBytes: sizeBytes,
);

void main() {
  final List<InstalledApp> apps = [
    _app(name: 'Charlie', sizeBytes: 2000, installTime: DateTime(2026, 1, 1)),
    _app(name: 'alpha', sizeBytes: 5000, installTime: DateTime(2026, 3, 1)),
    _app(name: 'Bravo', sizeBytes: 1000, installTime: DateTime(2026, 2, 1)),
  ];

  group('AppSortOption.sort', () {
    test('name sorts case-insensitively alphabetically', () {
      final sorted = AppSortOption.name.sort(apps);
      expect(sorted.map((a) => a.appName).toList(), ['alpha', 'Bravo', 'Charlie']);
    });

    test('size sorts largest first', () {
      final sorted = AppSortOption.size.sort(apps);
      expect(sorted.map((a) => a.appName).toList(), ['alpha', 'Charlie', 'Bravo']);
    });

    test('installDate sorts most recently installed first', () {
      final sorted = AppSortOption.installDate.sort(apps);
      expect(sorted.map((a) => a.appName).toList(), ['alpha', 'Bravo', 'Charlie']);
    });

    test('does not mutate the original list', () {
      final List<InstalledApp> original = List.of(apps);
      AppSortOption.size.sort(apps);
      expect(apps, orderedEquals(original));
    });
  });

  group('InstalledApp.isSplitApk', () {
    test('false when there are no split APKs', () {
      expect(apps.first.isSplitApk, isFalse);
    });

    test('true when split APK paths are present', () {
      final split = InstalledApp(
        packageName: 'com.example.split',
        appName: 'Split',
        versionName: '1.0',
        versionCode: 1,
        firstInstallTime: DateTime(2026),
        lastUpdateTime: DateTime(2026),
        apkPath: '/data/app/split/base.apk',
        splitApkPaths: const ['/data/app/split/split_config.arm64_v8a.apk'],
        sizeBytes: 1000,
      );
      expect(split.isSplitApk, isTrue);
    });
  });
}
