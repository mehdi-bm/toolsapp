import 'package:flutter_test/flutter_test.dart';
import 'package:toolbax/features/advertising/domain/ad_banner_model.dart';

void main() {
  test('parses a complete banner', () {
    final model = AdBannerModel.tryParse({
      'bannerId': ' b1 ',
      'bannerTitle': 'عنوان',
      'imageUrl': '/x.webp',
      'destinationUrl': 'https://example.com',
      'campaignTitle': 'کمپین',
      'sectionName': 'خانه',
      'sectionCode': 'home',
    });

    expect(model, isNotNull);
    expect(model!.bannerId, 'b1');
    expect(model.bannerTitle, 'عنوان');
  });

  test('rejects a banner with a missing bannerId', () {
    expect(AdBannerModel.tryParse({'bannerTitle': 'x'}), isNull);
  });

  test('rejects a banner with an empty bannerId', () {
    expect(AdBannerModel.tryParse({'bannerId': '   '}), isNull);
  });

  test('tolerates missing optional fields', () {
    final model = AdBannerModel.tryParse({'bannerId': 'b1'});
    expect(model, isNotNull);
    expect(model!.bannerTitle, isEmpty);
  });
}
