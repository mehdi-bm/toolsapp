import 'package:toolbax/features/advertising/domain/ad_banner_model.dart';
import 'package:toolbax/features/advertising/domain/ad_click_result.dart';
import 'package:toolbax/features/advertising/domain/advertising_gateway.dart';

class FakeAdvertisingGateway implements AdvertisingGateway {
  bool isConfiguredValue = true;
  List<AdBannerModel> bannersToReturn = const [];
  Object? fetchError;
  Object? clickError;
  AdClickResult? clickResultToReturn;
  int fetchCallCount = 0;
  int clickCallCount = 0;
  String? lastClickBannerId;
  String Function(String value)? resolveOverride;

  @override
  bool get isConfigured => isConfiguredValue;

  @override
  String resolvePublicUrl(String value) =>
      resolveOverride?.call(value) ?? value;

  @override
  Future<List<AdBannerModel>> fetchBanners() async {
    fetchCallCount++;
    if (fetchError != null) throw fetchError!;
    return bannersToReturn;
  }

  @override
  Future<AdClickResult> registerClick({
    required String bannerId,
    required String externalUserId,
  }) async {
    clickCallCount++;
    lastClickBannerId = bannerId;
    if (clickError != null) throw clickError!;
    return clickResultToReturn ??
        const AdClickResult(clickId: 'c1', destinationUrl: 'https://example.com');
  }

  @override
  void close() {}
}
