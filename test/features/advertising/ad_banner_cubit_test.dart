import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbax/features/advertising/data/install_id_repository.dart';
import 'package:toolbax/features/advertising/domain/ad_banner_model.dart';
import 'package:toolbax/features/advertising/presentation/ad_banner_cubit.dart';

import '../../helpers/fake_advertising_gateway.dart';

const AdBannerModel _kBanner = AdBannerModel(
  bannerId: 'b1',
  bannerTitle: 'عنوان',
  imageUrl: '',
  destinationUrl: 'https://example.com',
  campaignTitle: '',
  sectionName: '',
  sectionCode: '',
);

Future<InstallIdRepository> _installIdRepository() async {
  SharedPreferences.setMockInitialValues(const {});
  return InstallIdRepository(await SharedPreferences.getInstance());
}

void main() {
  test('loads banners on construction', () async {
    final gateway = FakeAdvertisingGateway()..bannersToReturn = [_kBanner];
    final cubit = AdBannerCubit(
      gateway: gateway,
      installIdRepository: await _installIdRepository(),
    );

    expect(cubit.state.initialLoading, isTrue);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.initialLoading, isFalse);
    expect(cubit.state.banners, hasLength(1));
    expect(gateway.fetchCallCount, 1);
  });

  test('surfaces a fetch error without crashing', () async {
    final gateway = FakeAdvertisingGateway()..fetchError = Exception('boom');
    final cubit = AdBannerCubit(
      gateway: gateway,
      installIdRepository: await _installIdRepository(),
    );

    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.initialLoading, isFalse);
    expect(cubit.state.banners, isEmpty);
    expect(cubit.state.errorMessage, isNotNull);
  });

  test('refresh() re-fetches even within the cache window', () async {
    final gateway = FakeAdvertisingGateway()..bannersToReturn = [_kBanner];
    final cubit = AdBannerCubit(
      gateway: gateway,
      installIdRepository: await _installIdRepository(),
    );
    await Future<void>.delayed(Duration.zero);
    expect(gateway.fetchCallCount, 1);

    await cubit.refresh();
    expect(gateway.fetchCallCount, 2);
  });

  test('onResumed() does not re-fetch while the cache is still fresh', () async {
    final gateway = FakeAdvertisingGateway()..bannersToReturn = [_kBanner];
    final cubit = AdBannerCubit(
      gateway: gateway,
      installIdRepository: await _installIdRepository(),
    );
    await Future<void>.delayed(Duration.zero);
    expect(gateway.fetchCallCount, 1);

    cubit.onResumed();
    await Future<void>.delayed(Duration.zero);
    expect(gateway.fetchCallCount, 1);
  });

  test('openBanner registers exactly one click for concurrent taps', () async {
    final gateway = FakeAdvertisingGateway()..bannersToReturn = [_kBanner];
    final cubit = AdBannerCubit(
      gateway: gateway,
      installIdRepository: await _installIdRepository(),
    );
    await Future<void>.delayed(Duration.zero);

    final Future<void> first = cubit.openBanner(_kBanner);
    final Future<void> second = cubit.openBanner(_kBanner);
    await Future.wait([first, second]);

    expect(gateway.clickCallCount, 1);
  });

  test(
    'openBanner falls back to the banner destination when click registration fails',
    () async {
      final gateway = FakeAdvertisingGateway()
        ..bannersToReturn = [_kBanner]
        ..clickError = Exception('network down');
      final cubit = AdBannerCubit(
        gateway: gateway,
        installIdRepository: await _installIdRepository(),
      );
      await Future<void>.delayed(Duration.zero);

      // Should not throw even though click registration fails.
      await cubit.openBanner(_kBanner);
      expect(gateway.clickCallCount, 1);
    },
  );

  test(
    'resolves a relative imageUrl through the gateway before storing it',
    () async {
      const bannerWithImage = AdBannerModel(
        bannerId: 'b2',
        bannerTitle: 'عنوان',
        imageUrl: '/uploads/x.webp',
        destinationUrl: 'https://example.com',
        campaignTitle: '',
        sectionName: '',
        sectionCode: '',
      );
      final gateway = FakeAdvertisingGateway()
        ..bannersToReturn = [bannerWithImage]
        ..resolveOverride = (v) => 'https://ads.example.com$v';
      final cubit = AdBannerCubit(
        gateway: gateway,
        installIdRepository: await _installIdRepository(),
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        cubit.state.banners.single.imageUrl,
        'https://ads.example.com/uploads/x.webp',
      );
    },
  );

  test(
    'falls back to an empty imageUrl when resolution throws',
    () async {
      const bannerWithImage = AdBannerModel(
        bannerId: 'b3',
        bannerTitle: 'عنوان',
        imageUrl: 'ftp://bad-scheme',
        destinationUrl: 'https://example.com',
        campaignTitle: '',
        sectionName: '',
        sectionCode: '',
      );
      final gateway = FakeAdvertisingGateway()
        ..bannersToReturn = [bannerWithImage]
        ..resolveOverride = (_) => throw Exception('invalid');
      final cubit = AdBannerCubit(
        gateway: gateway,
        installIdRepository: await _installIdRepository(),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.banners.single.imageUrl, isEmpty);
    },
  );

  test('does nothing when the gateway is not configured', () async {
    final gateway = FakeAdvertisingGateway()..isConfiguredValue = false;
    final cubit = AdBannerCubit(
      gateway: gateway,
      installIdRepository: await _installIdRepository(),
    );
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.initialLoading, isFalse);
    expect(cubit.state.banners, isEmpty);
    expect(gateway.fetchCallCount, 0);
  });
}
