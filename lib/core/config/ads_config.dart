/// Reads Parsik advertising/support API configuration from `--dart-define`
/// values supplied at build time. Never hardcode real keys here — if a key
/// is missing, [isConfigured] is false and callers must disable the
/// corresponding feature with a clear message instead of faking a value.
abstract final class AdsConfig {
  static const String baseUrl = String.fromEnvironment(
    'ADS_BASE_URL',
    defaultValue: 'https://ads.parsikonline.ir/',
  );

  static const String apiKey = String.fromEnvironment('ADS_API_KEY');

  static const String externalAppApiKey = String.fromEnvironment(
    'ADS_EXTERNAL_APP_API_KEY',
  );

  static const String appName = String.fromEnvironment(
    'ADS_APP_NAME',
    defaultValue: 'toolsApp',
  );

  static const String platform = String.fromEnvironment(
    'ADS_PLATFORM',
    defaultValue: 'Android',
  );

  static const String sectionCode = String.fromEnvironment(
    'ADS_SECTION_CODE',
  );

  static bool get isConfigured => apiKey.isNotEmpty && externalAppApiKey.isNotEmpty;
}
