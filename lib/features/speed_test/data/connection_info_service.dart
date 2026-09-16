import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';

import '../domain/connection_type.dart';

class ConnectionInfoService {
  static const MethodChannel _telephonyChannel = MethodChannel(
    'com.parsik.toolbax/telephony',
  );

  final Connectivity _connectivity = Connectivity();

  Future<ConnectionType> getConnectionType() async {
    try {
      final List<ConnectivityResult> results = await _connectivity
          .checkConnectivity();
      if (results.contains(ConnectivityResult.wifi)) return ConnectionType.wifi;
      if (results.contains(ConnectivityResult.mobile)) {
        return ConnectionType.mobile;
      }
      if (results.contains(ConnectivityResult.ethernet)) {
        return ConnectionType.ethernet;
      }
      if (results.contains(ConnectivityResult.none) || results.isEmpty) {
        return ConnectionType.none;
      }
      return ConnectionType.other;
    } catch (_) {
      return ConnectionType.other;
    }
  }

  /// Returns the current network operator's display name, or `null` when
  /// unavailable (no SIM, Wi-Fi-only device, or the platform call fails).
  Future<String?> getCarrierName() async {
    try {
      final String? name = await _telephonyChannel.invokeMethod<String>(
        'getNetworkOperatorName',
      );
      return (name == null || name.trim().isEmpty) ? null : name.trim();
    } catch (_) {
      return null;
    }
  }
}
