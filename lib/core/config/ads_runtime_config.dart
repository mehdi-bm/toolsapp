import 'ads_config.dart';

/// Injectable view of the Parsik API configuration. Production code builds
/// this once from [AdsConfig] (which reads `--dart-define` values); tests
/// construct it directly so service behavior doesn't depend on build-time
/// environment variables being set.
class AdsRuntimeConfig {
  const AdsRuntimeConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.externalAppApiKey,
    required this.appName,
    required this.platform,
    required this.sectionCode,
  });

  factory AdsRuntimeConfig.fromEnvironment() => const AdsRuntimeConfig(
    baseUrl: AdsConfig.baseUrl,
    apiKey: AdsConfig.apiKey,
    externalAppApiKey: AdsConfig.externalAppApiKey,
    appName: AdsConfig.appName,
    platform: AdsConfig.platform,
    sectionCode: AdsConfig.sectionCode,
  );

  final String baseUrl;
  final String apiKey;
  final String externalAppApiKey;
  final String appName;
  final String platform;
  final String sectionCode;

  bool get isConfigured => apiKey.isNotEmpty && externalAppApiKey.isNotEmpty;
}
