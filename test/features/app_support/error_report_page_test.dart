import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toolbax/core/services/service_locator.dart';
import 'package:toolbax/features/app_support/domain/app_support_gateway.dart';
import 'package:toolbax/features/app_support/presentation/error_report_page.dart';

import '../../helpers/fake_app_support_gateway.dart';

Future<FakeAppSupportGateway> _pumpPage(WidgetTester tester) async {
  await getIt.reset();
  final gateway = FakeAppSupportGateway();
  getIt.registerLazySingleton<AppSupportGateway>(() => gateway);

  await tester.pumpWidget(
    const MaterialApp(
      locale: Locale('fa', 'IR'),
      home: ErrorReportPage(),
    ),
  );
  await tester.pumpAndSettle();
  return gateway;
}

void main() {
  testWidgets('rejects a description shorter than 5 characters', (
    tester,
  ) async {
    final gateway = await _pumpPage(tester);

    await tester.enterText(find.byKey(const Key('error_description')), 'hi');
    await tester.tap(find.byKey(const Key('submit_error_report')));
    await tester.pumpAndSettle();

    expect(find.text('شرح خطا باید حداقل ۵ کاراکتر باشد.'), findsOneWidget);
    expect(gateway.lastErrorReportArgs, isNull);
  });

  testWidgets('submits successfully, clears the field, and shows a '
      'confirmation', (tester) async {
    final gateway = await _pumpPage(tester);

    await tester.enterText(
      find.byKey(const Key('error_description')),
      'صفحه خط‌کش باز نمی‌شود.',
    );
    await tester.tap(find.byKey(const Key('submit_error_report')));
    await tester.pumpAndSettle();

    expect(gateway.lastErrorReportArgs?['description'], 'صفحه خط‌کش باز نمی‌شود.');
    expect(find.text('گزارش شما ثبت شد.'), findsOneWidget);

    final TextFormField field = tester.widget(
      find.byKey(const Key('error_description')),
    );
    expect(field.controller?.text, isEmpty);
  });

  testWidgets('keeps the entered text and shows an error message on '
      'failure', (tester) async {
    final gateway = await _pumpPage(tester);
    gateway.errorToThrow = Exception('network down');

    await tester.enterText(
      find.byKey(const Key('error_description')),
      'یک مشکل واقعی',
    );
    await tester.tap(find.byKey(const Key('submit_error_report')));
    await tester.pumpAndSettle();

    final TextFormField field = tester.widget(
      find.byKey(const Key('error_description')),
    );
    expect(field.controller?.text, 'یک مشکل واقعی');
    expect(find.text('ارسال گزارش ناموفق بود.'), findsOneWidget);
  });

  testWidgets('prevents a duplicate submission from a rapid double tap', (
    tester,
  ) async {
    final gateway = await _pumpPage(tester);

    await tester.enterText(
      find.byKey(const Key('error_description')),
      'یک مشکل واقعی',
    );
    // _submit() guards re-entrancy with an instance-field check set
    // synchronously on the first call, so even if both taps' onPressed
    // fire before a rebuild, only one call should reach the gateway.
    await tester.tap(find.byKey(const Key('submit_error_report')));
    await tester.tap(
      find.byKey(const Key('submit_error_report')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(gateway.errorReportCallCount, 1);
  });
}
