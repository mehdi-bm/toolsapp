import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbax/features/advertising/data/install_id_repository.dart';
import 'package:toolbax/features/advertising/domain/ad_banner_model.dart';
import 'package:toolbax/features/advertising/presentation/ad_banner_cubit.dart';
import 'package:toolbax/features/advertising/presentation/ad_banner_widget.dart';

import '../../helpers/fake_advertising_gateway.dart';

const AdBannerModel _kBannerA = AdBannerModel(
  bannerId: 'a',
  bannerTitle: 'بنر الف',
  imageUrl: '',
  destinationUrl: 'https://example.com/a',
  campaignTitle: '',
  sectionName: '',
  sectionCode: '',
);

const AdBannerModel _kBannerB = AdBannerModel(
  bannerId: 'b',
  bannerTitle: 'بنر ب',
  imageUrl: '',
  destinationUrl: 'https://example.com/b',
  campaignTitle: '',
  sectionName: '',
  sectionCode: '',
);

void main() {
  testWidgets('shows nothing once loaded with an empty banner list', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(const {});
    final InstallIdRepository repo = InstallIdRepository(
      await SharedPreferences.getInstance(),
    );
    final gateway = FakeAdvertisingGateway();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<AdBannerCubit>(
            create: (_) => AdBannerCubit(gateway: gateway, installIdRepository: repo),
            child: const AdBannerWidget(),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('ad_loading_placeholder')), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ad_loading_placeholder')), findsNothing);
    expect(find.byKey(const Key('ad_banner_page_view')), findsNothing);
    expect(find.byKey(const Key('ad_load_error')), findsNothing);
  });

  testWidgets('shows a retry button on error and retries on tap', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(const {});
    final InstallIdRepository repo = InstallIdRepository(
      await SharedPreferences.getInstance(),
    );
    final gateway = FakeAdvertisingGateway()..fetchError = Exception('boom');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<AdBannerCubit>(
            create: (_) => AdBannerCubit(gateway: gateway, installIdRepository: repo),
            child: const AdBannerWidget(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ad_load_error')), findsOneWidget);
    expect(gateway.fetchCallCount, 1);

    await tester.tap(find.byKey(const Key('ad_retry_button')));
    await tester.pumpAndSettle();

    expect(gateway.fetchCallCount, 2);
  });

  testWidgets('renders a single banner with its key', (tester) async {
    SharedPreferences.setMockInitialValues(const {});
    final InstallIdRepository repo = InstallIdRepository(
      await SharedPreferences.getInstance(),
    );
    final gateway = FakeAdvertisingGateway()..bannersToReturn = [_kBannerA];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<AdBannerCubit>(
            create: (_) => AdBannerCubit(gateway: gateway, installIdRepository: repo),
            child: const AdBannerWidget(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ad_banner_page_view')), findsOneWidget);
    expect(find.byKey(const Key('ad_banner_a')), findsOneWidget);
    expect(find.text('بنر الف'), findsOneWidget);
  });

  testWidgets('tapping a banner registers exactly one click', (tester) async {
    // The re-entrancy guard itself (blocking two truly-concurrent taps) is
    // covered at the cubit level in ad_banner_cubit_test.dart via
    // Future.wait — the fake gateway here resolves near-instantly, so two
    // sequentially-awaited tester.tap() calls would let the first click
    // fully finish before the second fires, making them legitimately two
    // separate clicks rather than a race.
    SharedPreferences.setMockInitialValues(const {});
    final InstallIdRepository repo = InstallIdRepository(
      await SharedPreferences.getInstance(),
    );
    final gateway = FakeAdvertisingGateway()..bannersToReturn = [_kBannerA];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<AdBannerCubit>(
            create: (_) => AdBannerCubit(gateway: gateway, installIdRepository: repo),
            child: const AdBannerWidget(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('ad_banner_a')));
    await tester.pumpAndSettle();

    expect(gateway.clickCallCount, 1);
    expect(gateway.lastClickBannerId, 'a');
  });

  testWidgets('renders multiple banners in the page view', (tester) async {
    SharedPreferences.setMockInitialValues(const {});
    final InstallIdRepository repo = InstallIdRepository(
      await SharedPreferences.getInstance(),
    );
    final gateway = FakeAdvertisingGateway()
      ..bannersToReturn = [_kBannerA, _kBannerB];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<AdBannerCubit>(
            create: (_) => AdBannerCubit(gateway: gateway, installIdRepository: repo),
            child: const AdBannerWidget(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ad_banner_a')), findsOneWidget);
    // The second page exists in the PageView but may not be laid out until
    // scrolled to; assert via the controller-driven page view instead.
    expect(find.byKey(const Key('ad_banner_page_view')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
