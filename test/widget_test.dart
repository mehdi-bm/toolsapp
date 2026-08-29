import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:toolbax/core/services/service_locator.dart';
import 'package:toolbax/core/utils/persian_numbers.dart';
import 'package:toolbax/main.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  await getIt.reset();
  SharedPreferences.setMockInitialValues(const {});
  await setupServiceLocator();
  await tester.pumpWidget(const ToolboxApp());
  await tester.pumpAndSettle();
}

/// Categories below the fold aren't laid out by the lazy Home list until
/// scrolled into view, so their tool cards don't exist as widgets yet.
Future<void> _scrollToToolCard(WidgetTester tester, String id) async {
  final Finder scrollable = find
      .descendant(
        of: find.byKey(const Key('home_scroll_view')),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(
    find.byKey(Key('tool_card_$id')),
    300,
    scrollable: scrollable,
  );
  await tester.pump();
}

void main() {
  testWidgets('RootShell shows Home by default and switches tabs via the '
      'bottom navigation bar', (WidgetTester tester) async {
    await _pumpApp(tester);

    expect(find.text('جعبه‌ابزار پارسیک'), findsOneWidget);
    expect(find.text('خط‌کش'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav_favorites')));
    await tester.pumpAndSettle();
    expect(
      find.text('هنوز ابزاری به علاقه‌مندی‌ها اضافه نکرده‌اید.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('nav_settings')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('settings_theme_mode_selector')),
      findsOneWidget,
    );
  });

  testWidgets('Android back button returns to Home tab instead of exiting '
      'the app', (WidgetTester tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(const Key('nav_settings')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('settings_theme_mode_selector')),
      findsOneWidget,
    );

    final ByteData message = const JSONMethodCodec().encodeMethodCall(
      const MethodCall('popRoute'),
    );
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      message,
      (_) {},
    );
    await tester.pumpAndSettle();

    expect(find.text('خط‌کش'), findsOneWidget);
  });

  testWidgets('Search filters tools by Persian title and shows a message '
      'when nothing matches', (WidgetTester tester) async {
    await _pumpApp(tester);

    await tester.enterText(find.byKey(const Key('tool_search_field')), 'رمز');
    await tester.pumpAndSettle();

    expect(find.text('تولید رمز'), findsOneWidget);
    expect(find.text('خط‌کش'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('tool_search_field')),
      'زززچمقچمق',
    );
    await tester.pumpAndSettle();

    expect(find.text('ابزاری با این نام پیدا نشد.'), findsOneWidget);
  });

  testWidgets('Toggling a favorite on Home persists it into the Favorites '
      'tab', (WidgetTester tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(const Key('favorite_toggle_ruler')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav_favorites')));
    await tester.pumpAndSettle();

    expect(
      find.text('هنوز ابزاری به علاقه‌مندی‌ها اضافه نکرده‌اید.'),
      findsNothing,
    );
    expect(find.text('خط‌کش'), findsOneWidget);
  });

  testWidgets('Ruler tool opens, and its calibration sheet can be opened '
      'and saved', (WidgetTester tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(const Key('tool_card_ruler')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('اندازه‌گیری روی صفحهٔ گوشی تقریبی است'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('ruler_rotate_action')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('ruler_calibrate_action')));
    await tester.pumpAndSettle();
    expect(find.text('کالیبره کردن خط‌کش'), findsOneWidget);

    await tester.tap(find.text('ذخیره'));
    await tester.pumpAndSettle();
    expect(find.text('کالیبره کردن خط‌کش'), findsNothing);
  });

  testWidgets('Protractor tool opens, resets and accepts a drag without '
      'throwing', (WidgetTester tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(const Key('tool_card_protractor')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('با کشیدن انگشت روی صفحه'),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const Key('protractor_dial')),
      const Offset(-40, -10),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('protractor_reset_action')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Level tool opens and does not crash when the accelerometer '
      'platform channel is unavailable in the test environment', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    // pumpAndSettle isn't used here: without a real accelerometer platform
    // channel the tool may sit in its loading state, whose spinner animates
    // indefinitely and would make pumpAndSettle time out.
    await tester.tap(find.byKey(const Key('tool_card_level')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.textContaining('کالیبره کردن'),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  for (final String id in [
    'qr_scanner',
    'barcode_scanner',
    'color_detector',
    'magnifier',
    'sound_meter',
  ]) {
    testWidgets(
      '$id opens and shows a permission prompt instead of crashing when no '
      'platform channel is available',
      (WidgetTester tester) async {
        await _pumpApp(tester);
        await _scrollToToolCard(tester, id);

        // pumpAndSettle isn't used here: while the permission check is
        // pending, the gate shows a CircularProgressIndicator, whose
        // animation never stops and would make pumpAndSettle time out.
        await tester.tap(find.byKey(Key('tool_card_$id')));
        await tester.pump();
        await tester.pump(const Duration(seconds: 6));

        expect(
          find.byKey(const Key('permission_action')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Flashlight tool opens and does not crash when the torch '
      'platform channel is unavailable in the test environment', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _scrollToToolCard(tester, 'flashlight');

    await tester.tap(find.byKey(const Key('tool_card_flashlight')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));

    expect(
      find.textContaining('چراغ‌قوه'),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Compass tool opens and does not crash when the sensor '
      'platform channel is unavailable in the test environment', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _scrollToToolCard(tester, 'compass');

    await tester.tap(find.byKey(const Key('tool_card_compass')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.textContaining('قطب‌نما'),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Password generator produces a password matching the selected '
      'length and categories, and shows a placeholder when none are '
      'selected', (WidgetTester tester) async {
    await _pumpApp(tester);
    await _scrollToToolCard(tester, 'password_generator');
    await tester.tap(find.byKey(const Key('tool_card_password_generator')));
    await tester.pumpAndSettle();

    String displayedText() => tester
        .widget<SelectableText>(find.byKey(const Key('password_display')))
        .data!;

    expect(displayedText().length, 16);

    for (final String key in [
      'password_toggle_uppercase',
      'password_toggle_lowercase',
      'password_toggle_numbers',
      'password_toggle_symbols',
    ]) {
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
    }

    expect(displayedText(), 'حداقل یک نوع کاراکتر را انتخاب کنید.');
  });

  testWidgets('Random code generator switches between numeric and '
      'alphanumeric modes without crashing', (WidgetTester tester) async {
    await _pumpApp(tester);
    await _scrollToToolCard(tester, 'random_generator');
    await tester.tap(find.byKey(const Key('tool_card_random_generator')));
    await tester.pumpAndSettle();

    String displayedCode() => tester
        .widget<SelectableText>(find.byKey(const Key('random_code_display')))
        .data!;

    expect(displayedCode().length, 6);
    expect(RegExp(r'^[0-9]+$').hasMatch(displayedCode()), isTrue);

    await tester.tap(find.text('عدد و حرف'));
    await tester.pumpAndSettle();

    expect(RegExp(r'^[0-9A-Z]+$').hasMatch(displayedCode()), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('QR generator renders a QR code once content is entered and '
      'shows extra fields for Wi-Fi', (WidgetTester tester) async {
    await _pumpApp(tester);
    await _scrollToToolCard(tester, 'qr_generator');
    await tester.tap(find.byKey(const Key('tool_card_qr_generator')));
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsNothing);
    expect(find.text('برای مشاهدهٔ QR، اطلاعات را وارد کنید.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('qr_gen_primary_field')),
      'سلام دنیا',
    );
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsOneWidget);

    await tester.tap(find.byKey(const Key('qr_gen_type_wifi')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('qr_gen_ssid_field')), findsOneWidget);
    expect(find.byKey(const Key('qr_gen_wifi_password_field')), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);

    await tester.enterText(
      find.byKey(const Key('qr_gen_ssid_field')),
      'MyNetwork',
    );
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsOneWidget);

    // Saving talks to a platform channel unavailable in tests; just confirm
    // it doesn't crash the app.
    await tester.ensureVisible(find.byKey(const Key('qr_gen_save_action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('qr_gen_save_action')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Text counter shows live character/word/line counts', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _scrollToToolCard(tester, 'char_counter');
    await tester.tap(find.byKey(const Key('tool_card_char_counter')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('text_counter_input')),
      'سلام دنیا',
    );
    await tester.pumpAndSettle();

    expect(find.text(toPersianNumber(9)), findsOneWidget); // characters
    expect(find.text(toPersianNumber(8)), findsOneWidget); // no spaces
    expect(find.text(toPersianNumber(2)), findsOneWidget); // words
    expect(find.text(toPersianNumber(1)), findsOneWidget); // lines
  });

  testWidgets('Speech/text converter: TTS input accepts text and play does '
      'not crash without a TTS platform channel', (WidgetTester tester) async {
    await _pumpApp(tester);
    await _scrollToToolCard(tester, 'speech_text_converter');
    await tester.tap(find.byKey(const Key('tool_card_speech_text_converter')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tts_input_field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('tts_input_field')),
      'سلام دنیا',
    );
    await tester.tap(find.byKey(const Key('tts_toggle_action')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });

  testWidgets('Speech/text converter: switching to speech-to-text shows a '
      'permission prompt instead of crashing', (WidgetTester tester) async {
    await _pumpApp(tester);
    await _scrollToToolCard(tester, 'speech_text_converter');
    await tester.tap(find.byKey(const Key('tool_card_speech_text_converter')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('گفتار به متن'));
    // pumpAndSettle isn't used here: while the permission check is pending,
    // the gate shows a CircularProgressIndicator, whose animation never
    // stops and would make pumpAndSettle time out.
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));

    expect(find.byKey(const Key('permission_action')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Text case converter transforms text and leaves Persian '
      'letters unchanged', (WidgetTester tester) async {
    await _pumpApp(tester);
    await _scrollToToolCard(tester, 'text_case_converter');
    await tester.tap(find.byKey(const Key('tool_card_text_case_converter')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('case_converter_input')),
      'hello سلام',
    );
    await tester.tap(find.byKey(const Key('case_converter_upper')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SelectableText>(
            find.byKey(const Key('case_converter_output')),
          )
          .data,
      'HELLO سلام',
    );
  });

  testWidgets('Text cleaner normalizes Arabic letters and collapses extra '
      'spaces live', (WidgetTester tester) async {
    await _pumpApp(tester);
    await _scrollToToolCard(tester, 'text_cleaner');
    await tester.tap(find.byKey(const Key('tool_card_text_cleaner')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('text_cleaner_input')),
      'علي   و   كتاب',
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SelectableText>(find.byKey(const Key('text_cleaner_output')))
          .data,
      'علی و کتاب',
    );
  });

  testWidgets('Settings: changing theme mode updates MaterialApp.themeMode', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await tester.tap(find.byKey(const Key('nav_settings')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );

    await tester.tap(find.text('تاریک'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
  });

  testWidgets('Settings: turning off "show recent" hides the section on '
      'Home, and reset restores it', (WidgetTester tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(const Key('tool_card_ruler')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('آخرین ابزارهای استفاده‌شده'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav_settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings_toggle_show_recent')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav_home')));
    await tester.pumpAndSettle();
    expect(find.text('آخرین ابزارهای استفاده‌شده'), findsNothing);

    await tester.tap(find.byKey(const Key('nav_settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings_reset_action')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('بازنشانی'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<SwitchListTile>(
        find.byKey(const Key('settings_toggle_show_recent')),
      ).value,
      isTrue,
    );

    await tester.tap(find.byKey(const Key('nav_home')));
    await tester.pumpAndSettle();
    expect(find.text('آخرین ابزارهای استفاده‌شده'), findsOneWidget);
  });

  testWidgets('Settings: About and Privacy Policy pages open with their '
      'content', (WidgetTester tester) async {
    await _pumpApp(tester);
    await tester.tap(find.byKey(const Key('nav_settings')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('درباره برنامه'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('درباره برنامه'));
    await tester.pumpAndSettle();
    expect(find.text('نسخه 1.0.0'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('حریم خصوصی'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('حریم خصوصی'));
    await tester.pumpAndSettle();
    expect(find.textContaining('هیچ داده‌ای از دستگاه شما'), findsOneWidget);
  });

  testWidgets('Settings: contact tile fails gracefully without a mail app '
      'platform channel', (WidgetTester tester) async {
    await _pumpApp(tester);
    await tester.tap(find.byKey(const Key('nav_settings')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('تماس با ما'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('تماس با ما'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });

  testWidgets('Home does not crash with the (unconfigured, in tests) ad '
      'banner wired in, and pull-to-refresh works', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    // Unconfigured in tests (no --dart-define keys), so the banner widget
    // renders nothing — this just confirms it doesn't crash the page.
    expect(tester.takeException(), isNull);

    await tester.fling(
      find.byKey(const Key('home_scroll_view')),
      const Offset(0, 300),
      1000,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings: error report and advertising request entries open '
      'their pages', (WidgetTester tester) async {
    await _pumpApp(tester);
    await tester.tap(find.byKey(const Key('nav_settings')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings_error_report_entry')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings_error_report_entry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('error_description')), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings_advertising_request_entry')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('settings_advertising_request_entry')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('advertising_full_name')), findsOneWidget);
  });
}
