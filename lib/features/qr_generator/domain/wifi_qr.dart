/// ZXing Wi-Fi payload escaping. Spaces in SSIDs and passwords are significant.
String buildWifiQr({
  required String ssid,
  required String password,
  required String security,
}) {
  String escape(String value) =>
      value.replaceAllMapped(RegExp(r'[\\;,:"]'), (match) => '\\${match[0]}');
  if (ssid.isEmpty) return '';
  return 'WIFI:T:$security;S:${escape(ssid)};'
      '${security == 'nopass' ? '' : 'P:${escape(password)};'};';
}
