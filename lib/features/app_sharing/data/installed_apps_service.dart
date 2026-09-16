import 'dart:io';

import 'package:flutter/services.dart';

import '../domain/installed_app.dart';

class InstalledAppsService {
  static const MethodChannel _channel = MethodChannel(
    'com.parsik.toolbax/apps',
  );

  Future<List<InstalledApp>> listApps() async {
    // Enumerating every installed app (plus a PackageInfo lookup per app)
    // can take a few seconds on a phone with many apps — bound it so a
    // slow/stuck platform call can't hang the UI forever.
    final List<dynamic>? raw = await _channel
        .invokeMethod<List<dynamic>>('listApps')
        .timeout(const Duration(seconds: 20));
    if (raw == null) return const [];

    final List<InstalledApp?> converted = await Future.wait(
      raw.map(
        (entry) => _toInstalledApp(Map<Object?, Object?>.from(entry as Map)),
      ),
    );
    return converted.whereType<InstalledApp>().toList();
  }

  Future<Uint8List?> getAppIcon(String packageName) async {
    try {
      return await _channel.invokeMethod<Uint8List>('getAppIcon', {
        'packageName': packageName,
      });
    } catch (_) {
      return null;
    }
  }

  Future<InstalledApp?> _toInstalledApp(Map<Object?, Object?> map) async {
    final String? packageName = map['packageName'] as String?;
    final String? appName = map['appName'] as String?;
    final String? apkPath = map['apkPath'] as String?;
    if (packageName == null || appName == null || apkPath == null) {
      return null;
    }

    final List<String> splitApkPaths =
        (map['splitApkPaths'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];

    final List<int> sizes = await Future.wait([
      _fileSizeOrZero(apkPath),
      for (final String path in splitApkPaths) _fileSizeOrZero(path),
    ]);
    final int sizeBytes = sizes.fold(0, (a, b) => a + b);

    return InstalledApp(
      packageName: packageName,
      appName: appName,
      versionName: (map['versionName'] as String?) ?? '',
      versionCode: (map['versionCode'] as num?)?.toInt() ?? 0,
      firstInstallTime: DateTime.fromMillisecondsSinceEpoch(
        (map['firstInstallTime'] as num?)?.toInt() ?? 0,
      ),
      lastUpdateTime: DateTime.fromMillisecondsSinceEpoch(
        (map['lastUpdateTime'] as num?)?.toInt() ?? 0,
      ),
      apkPath: apkPath,
      splitApkPaths: splitApkPaths,
      sizeBytes: sizeBytes,
    );
  }

  Future<int> _fileSizeOrZero(String path) async {
    try {
      return await File(path).length();
    } catch (_) {
      return 0;
    }
  }
}
