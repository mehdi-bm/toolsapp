import 'ad_banner_model.dart';
import 'ad_click_result.dart';

abstract class AdvertisingGateway {
  bool get isConfigured;

  /// Resolves a possibly-relative URL from the API against the ads base
  /// URL, and rejects anything that isn't http/https.
  String resolvePublicUrl(String value);

  Future<List<AdBannerModel>> fetchBanners();

  Future<AdClickResult> registerClick({
    required String bannerId,
    required String externalUserId,
  });

  /// Releases the underlying transport. Only call this on an instance you
  /// own exclusively — the app-wide registration shares its transport with
  /// [AppSupportGateway] and must not be closed by a single consumer.
  void close();
}
