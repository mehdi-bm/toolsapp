import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Generates and persists a random, anonymous per-install identifier used
/// only for ad-click attribution. Never derived from Android ID, IMEI,
/// phone number, or any other hardware/user identifier.
class InstallIdRepository {
  InstallIdRepository(this._prefs);

  static const String _key = 'ads_install_id';

  final SharedPreferences _prefs;
  Future<String>? _pendingCreate;

  Future<String> getOrCreateId() {
    final String? existing = _prefs.getString(_key);
    if (existing != null && existing.isNotEmpty) return Future.value(existing);
    return _pendingCreate ??= _create();
  }

  Future<String> _create() async {
    final Random random = Random.secure();
    final List<int> bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final String id = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    await _prefs.setString(_key, id);
    _pendingCreate = null;
    return id;
  }
}
