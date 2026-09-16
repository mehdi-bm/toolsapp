class InstalledApp {
  const InstalledApp({
    required this.packageName,
    required this.appName,
    required this.versionName,
    required this.versionCode,
    required this.firstInstallTime,
    required this.lastUpdateTime,
    required this.apkPath,
    required this.splitApkPaths,
    required this.sizeBytes,
  });

  final String packageName;
  final String appName;
  final String versionName;
  final int versionCode;
  final DateTime firstInstallTime;
  final DateTime lastUpdateTime;
  final String apkPath;
  final List<String> splitApkPaths;
  final int sizeBytes;

  /// Apps installed as an Android App Bundle come as a base APK plus one or
  /// more split APKs (per density/ABI/language) — sharing them meaningfully
  /// means bundling all of them together, not just the base.
  bool get isSplitApk => splitApkPaths.isNotEmpty;
}
