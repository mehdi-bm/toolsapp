import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toolbax/core/services/service_locator.dart';
import 'package:toolbax/features/app_support/domain/app_support_gateway.dart';
import 'package:toolbax/features/app_support/presentation/advertising_request_page.dart';

import '../../helpers/fake_app_support_gateway.dart';

Future<FakeAppSupportGateway> _pumpPage(WidgetTester tester) async {
  await getIt.reset();
  final gateway = FakeAppSupportGateway();
  getIt.registerLazySingleton<AppSupportGateway>(() => gateway);

  await tester.pumpWidget(
    const MaterialApp(
      locale: Locale('fa', 'IR'),
      home: AdvertisingRequestPage(),
    ),
  );
  await tester.pumpAndSettle();
  return gateway;
}

Future<void> _fillValidForm(WidgetTester tester, {String phone = '09123456789'}) async {
  await tester.enterText(
    find.byKey(const Key('advertising_full_name')),
    'نام کامل',
  );
  await tester.enterText(find.byKey(const Key('advertising_phone')), phone);
  await tester.enterText(find.byKey(const Key('advertising_province')), 'تهران');
  await tester.enterText(find.byKey(const Key('advertising_city')), 'تهران');
}

void main() {
  testWidgets('rejects submission when required fields are empty', (
    tester,
  ) async {
    final gateway = await _pumpPage(tester);

    await tester.tap(find.byKey(const Key('submit_advertising_request')));
    await tester.pumpAndSettle();

    expect(find.text('نام و نام خانوادگی را وارد کنید.'), findsOneWidget);
    expect(gateway.lastAdvertisingRequestArgs, isNull);
  });

  testWidgets('accepts a Persian-digit phone number', (tester) async {
    final gateway = await _pumpPage(tester);

    await _fillValidForm(tester, phone: '۰۹۱۲۳۴۵۶۷۸۹');
    await tester.tap(find.byKey(const Key('submit_advertising_request')));
    await tester.pumpAndSettle();

    expect(gateway.lastAdvertisingRequestArgs, isNotNull);
    expect(gateway.lastAdvertisingRequestArgs?['phoneNumber'], '۰۹۱۲۳۴۵۶۷۸۹');
  });

  testWidgets('rejects a phone number with too few digits', (tester) async {
    final gateway = await _pumpPage(tester);

    await _fillValidForm(tester, phone: '123');
    await tester.tap(find.byKey(const Key('submit_advertising_request')));
    await tester.pumpAndSettle();

    expect(find.text('شمارهٔ تماس معتبر نیست.'), findsOneWidget);
    expect(gateway.lastAdvertisingRequestArgs, isNull);
  });

  testWidgets('submits all fields and clears the form on success', (
    tester,
  ) async {
    final gateway = await _pumpPage(tester);

    await _fillValidForm(tester);
    await tester.enterText(
      find.byKey(const Key('advertising_details')),
      'توضیح تکمیلی',
    );
    await tester.tap(find.byKey(const Key('submit_advertising_request')));
    await tester.pumpAndSettle();

    expect(gateway.lastAdvertisingRequestArgs?['fullName'], 'نام کامل');
    expect(gateway.lastAdvertisingRequestArgs?['phoneNumber'], '09123456789');
    expect(gateway.lastAdvertisingRequestArgs?['province'], 'تهران');
    expect(gateway.lastAdvertisingRequestArgs?['city'], 'تهران');
    expect(gateway.lastAdvertisingRequestArgs?['details'], 'توضیح تکمیلی');

    expect(
      find.text(
        'درخواست شما ثبت شد؛ کارشناسان تبلیغات با شمارهٔ ثبت‌شده تماس '
        'می‌گیرند.',
      ),
      findsOneWidget,
    );

    final TextFormField nameField = tester.widget(
      find.byKey(const Key('advertising_full_name')),
    );
    expect(nameField.controller?.text, isEmpty);
  });

  testWidgets('keeps entered values and shows an error message on failure', (
    tester,
  ) async {
    final gateway = await _pumpPage(tester);
    gateway.errorToThrow = Exception('network down');

    await _fillValidForm(tester);
    await tester.tap(find.byKey(const Key('submit_advertising_request')));
    await tester.pumpAndSettle();

    final TextFormField nameField = tester.widget(
      find.byKey(const Key('advertising_full_name')),
    );
    expect(nameField.controller?.text, 'نام کامل');
    expect(find.text('ارسال درخواست ناموفق بود.'), findsOneWidget);
  });

  testWidgets('lays out province and city without overflow on a small '
      'screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpPage(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('lays out province and city side by side on a wide screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpPage(tester);

    expect(tester.takeException(), isNull);
  });
}
