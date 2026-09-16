/// A simplified, Persian-labelled view of the device's active connection.
enum ConnectionType {
  wifi,
  mobile,
  ethernet,
  other,
  none;

  String get label => switch (this) {
    ConnectionType.wifi => 'Wi-Fi',
    ConnectionType.mobile => 'دیتای موبایل',
    ConnectionType.ethernet => 'اترنت',
    ConnectionType.other => 'سایر',
    ConnectionType.none => 'بدون اتصال',
  };
}
