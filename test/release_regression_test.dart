import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbax/core/services/service_locator.dart';
import 'package:toolbax/core/constants/tool_catalog.dart';
import 'package:toolbax/core/routing/tool_navigation.dart';
import 'package:toolbax/core/utils/tool_search.dart';
import 'package:toolbax/features/password_generator/domain/password_generator.dart';
import 'package:toolbax/features/qr_generator/domain/wifi_qr.dart';
import 'package:toolbax/main.dart';

void main() {
  test('Persian search accepts Arabic letters, spaces and missing ZWNJ', () {
    expect(filterTools('خط كش').single.id, 'ruler');
    expect(filterTools('چراغقوه').single.id, 'flashlight');
    expect(filterTools('ذره بين').single.id, 'magnifier');
    expect(filterTools('توليد رمز').single.id, 'password_generator');
    expect(filterTools('compass').single.id, 'compass');
    expect(filterTools('qr generator').single.id, 'qr_generator');
  });

  test(
    'Every selected password category is present even at minimum length',
    () {
      for (int seed = 0; seed < 100; seed++) {
        final password = generatePassword(
          length: 4,
          useUppercase: true,
          useLowercase: true,
          useNumbers: true,
          useSymbols: true,
          random: Random(seed),
        );
        for (final group in [
          kUppercaseChars,
          kLowercaseChars,
          kNumberChars,
          kSymbolChars,
        ]) {
          expect(
            password.split('').any(group.contains),
            isTrue,
            reason: 'seed $seed, group $group',
          );
        }
        expect(password.length, 4);
      }
    },
  );

  test('Wi-Fi QR escapes delimiters and preserves significant spaces', () {
    expect(
      buildWifiQr(ssid: ' cafe;: ', password: r'a\b;c,d:"e', security: 'WPA'),
      r'WIFI:T:WPA;S: cafe\;\: ;P:a\\b\;c\,d\:\"e;;',
    );
    expect(
      buildWifiQr(ssid: 'Guest', password: 'old-secret', security: 'nopass'),
      'WIFI:T:nopass;S:Guest;;',
    );
  });

  Future<void> pumpApp(WidgetTester tester, Size size, double scale) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
    await setupServiceLocator();
    await tester.pumpWidget(const ToolboxApp());
    await tester.pumpAndSettle();
  }

  for (final viewport in [
    (const Size(320, 568), 2.0),
    (const Size(568, 320), 1.0),
  ]) {
    for (final tool in kAllTools) {
      testWidgets(
        'catalog ${tool.id} opens at ${viewport.$1} scale ${viewport.$2}',
        (tester) async {
          await pumpApp(tester, viewport.$1, viewport.$2);
          openTool(
            tester.element(find.byKey(const Key('tool_search_field'))),
            tool,
          );
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('tool_search_field')), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
    for (final tool in [
      ('تولید رمز', 'password_generator'),
      ('کد تصادفی', 'random_generator'),
      ('ساخت QR', 'qr_generator'),
    ]) {
      testWidgets('${tool.$2} fits ${viewport.$1} at scale ${viewport.$2}', (
        tester,
      ) async {
        await pumpApp(tester, viewport.$1, viewport.$2);
        // Search by an unambiguous title fragment from the catalog.
        final queries = {
          'password_generator': 'رمز',
          'random_generator': 'تصادفی',
          'qr_generator': 'ساخت QR',
        };
        await tester.enterText(
          find.byKey(const Key('tool_search_field')),
          queries[tool.$2]!,
        );
        await tester.pumpAndSettle();
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        final card = find.byKey(Key('tool_card_${tool.$2}'));
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('tool_search_field')), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('returning from a search result does not reopen the keyboard', (
    tester,
  ) async {
    await pumpApp(tester, const Size(400, 800), 1);
    await tester.enterText(
      find.byKey(const Key('tool_search_field')),
      'qr_generator',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tool_card_qr_generator')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('oversized QR explains the limit and disables image export', (
    tester,
  ) async {
    await pumpApp(tester, const Size(400, 800), 1);
    await tester.enterText(
      find.byKey(const Key('tool_search_field')),
      'ساخت QR',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tool_card_qr_generator')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('qr_gen_primary_field')),
      'سلام' * 1000,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('بیش از حد طولانی'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('qr_gen_save_action')))
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}
