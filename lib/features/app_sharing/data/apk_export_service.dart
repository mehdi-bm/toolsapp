import 'dart:io';

import 'package:archive/archive_io.dart';

import '../domain/installed_app.dart';

/// Prepares a single shareable/saveable file for an installed app: the raw
/// APK directly when there's just one, or a ZIP bundling the base + every
/// split APK when the app was installed as an Android App Bundle.
class ApkExportService {
  Future<File> prepareExportFile(InstalledApp app) async {
    if (!app.isSplitApk) {
      return File(app.apkPath);
    }

    final String outputPath =
        '${Directory.systemTemp.path}/${_safeFileName(app.appName)}_'
        '${DateTime.now().millisecondsSinceEpoch}.zip';
    final ZipFileEncoder encoder = ZipFileEncoder();
    encoder.create(outputPath);
    try {
      await encoder.addFile(File(app.apkPath), 'base.apk');
      for (final String splitPath in app.splitApkPaths) {
        final File splitFile = File(splitPath);
        if (!splitFile.existsSync()) continue;
        await encoder.addFile(splitFile, splitFile.uri.pathSegments.last);
      }
    } finally {
      await encoder.close();
    }
    return File(outputPath);
  }

  String suggestedFileName(InstalledApp app) {
    final String base = _safeFileName(app.appName);
    return app.isSplitApk ? '$base.zip' : '$base.apk';
  }

  String _safeFileName(String name) {
    final String cleaned = name.replaceAll(RegExp(r'[^\w\s\-]'), '_').trim();
    return cleaned.isEmpty ? 'app' : cleaned;
  }
}
