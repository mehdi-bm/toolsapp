/// A simple, non-technical summary of connection quality, derived from the
/// measured download speed.
enum ConnectionQuality {
  weak,
  medium,
  excellent;

  String get label => switch (this) {
    ConnectionQuality.weak => 'ضعیف',
    ConnectionQuality.medium => 'متوسط',
    ConnectionQuality.excellent => 'عالی',
  };

  /// Derives a quality rating from a download speed in Mbps. Thresholds
  /// follow common consumer guidance: under 5 Mbps struggles with video
  /// calls/streaming, 5-25 Mbps covers most everyday use (including HD
  /// streaming), above that is comfortably fast.
  static ConnectionQuality fromDownloadMbps(double mbps) {
    if (mbps < 5) return ConnectionQuality.weak;
    if (mbps < 25) return ConnectionQuality.medium;
    return ConnectionQuality.excellent;
  }
}
