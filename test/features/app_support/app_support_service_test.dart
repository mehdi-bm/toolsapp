import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:toolbax/core/config/ads_runtime_config.dart';
import 'package:toolbax/core/network/api_exception.dart';
import 'package:toolbax/core/network/api_response.dart';
import 'package:toolbax/core/network/secure_api_client.dart';
import 'package:toolbax/features/app_support/data/app_support_service.dart';

import '../../helpers/fake_http_transport.dart';

const String _kBaseUrl = 'https://ads.parsikonline.ir/';

const AdsRuntimeConfig _kConfiguredTestConfig = AdsRuntimeConfig(
  baseUrl: _kBaseUrl,
  apiKey: 'test-api-key',
  externalAppApiKey: 'test-external-app-key',
  appName: 'toolsApp',
  platform: 'Android',
  sectionCode: '',
);

void main() {
  late FakeHttpTransport transport;
  late AppSupportService service;

  setUp(() {
    transport = FakeHttpTransport();
    service = AppSupportService(
      client: SecureApiClient(baseUrl: _kBaseUrl, transport: transport),
      config: _kConfiguredTestConfig,
    );
  });

  test('does not call the network when the API keys are missing', () async {
    final unconfigured = AppSupportService(
      client: SecureApiClient(baseUrl: _kBaseUrl, transport: transport),
      config: const AdsRuntimeConfig(
        baseUrl: _kBaseUrl,
        apiKey: '',
        externalAppApiKey: '',
        appName: 'toolsApp',
        platform: 'Android',
        sectionCode: '',
      ),
    );

    await expectLater(
      unconfigured.submitErrorReport(description: 'test'),
      throwsA(same(kNotConfiguredException)),
    );
    expect(transport.lastUri, isNull);
  });

  group('submitErrorReport', () {
    test('posts the exact endpoint, headers and trimmed body', () async {
      transport.responseToReturn = ApiResponse(
        statusCode: 201,
        body: jsonEncode({
          'id': 'r1',
          'type': 'ErrorReport',
          'status': 'New',
        }),
      );

      final receipt = await service.submitErrorReport(
        description: '  something broke  ',
      );

      expect(transport.lastMethod, 'POST');
      expect(transport.lastUri?.path, '/api/public/app-submissions/error-reports');
      expect(transport.lastHeaders?['X-API-KEY'], 'test-api-key');
      expect(
        transport.lastHeaders?['X-EXTERNAL-APP-API-KEY'],
        'test-external-app-key',
      );

      final Map<String, dynamic> body =
          jsonDecode(transport.lastBody!) as Map<String, dynamic>;
      expect(body['description'], 'something broke');

      expect(receipt.id, 'r1');
      expect(receipt.type, 'ErrorReport');
      expect(receipt.status, 'New');
    });

    test('rejects a 201 response with a missing id', () async {
      transport.responseToReturn = ApiResponse(
        statusCode: 201,
        body: jsonEncode({'type': 'ErrorReport'}),
      );
      await expectLater(
        service.submitErrorReport(description: 'x'),
        throwsA(same(kInvalidResponseException)),
      );
    });
  });

  group('submitAdvertisingRequest', () {
    test('posts every field trimmed, to the correct endpoint', () async {
      transport.responseToReturn = ApiResponse(
        statusCode: 201,
        body: jsonEncode({
          'id': 'a1',
          'type': 'AdvertisingRequest',
          'status': 'New',
        }),
      );

      await service.submitAdvertisingRequest(
        fullName: ' نام کامل ',
        phoneNumber: ' 09123456789 ',
        province: ' تهران ',
        city: ' تهران ',
        details: ' توضیحات ',
      );

      expect(
        transport.lastUri?.path,
        '/api/public/app-submissions/advertising-requests',
      );
      final Map<String, dynamic> body =
          jsonDecode(transport.lastBody!) as Map<String, dynamic>;
      expect(body['fullName'], 'نام کامل');
      expect(body['phoneNumber'], '09123456789');
      expect(body['province'], 'تهران');
      expect(body['city'], 'تهران');
      expect(body['details'], 'توضیحات');
    });
  });

  for (final entry in {
    400: 'اطلاعات واردشده معتبر نیست؛ فیلدها را بررسی کنید.',
    401: 'ارتباط امن برنامه با سرور تأیید نشد؛ نسخه برنامه را به‌روزرسانی کنید.',
    429: 'تعداد درخواست‌ها زیاد است؛ کمی بعد دوباره تلاش کنید.',
    500: 'مشکلی در سرور رخ داد؛ کمی بعد دوباره تلاش کنید.',
  }.entries) {
    test('maps HTTP ${entry.key} to a clear Persian message', () async {
      transport.responseToReturn = ApiResponse(
        statusCode: entry.key,
        body: '{}',
      );
      await expectLater(
        service.submitErrorReport(description: 'x'),
        throwsA(
          isA<ApiException>().having((e) => e.message, 'message', entry.value),
        ),
      );
    });
  }

  test('maps invalid JSON to the generic invalid-response message', () async {
    transport.responseToReturn = const ApiResponse(
      statusCode: 201,
      body: 'not json{{',
    );
    await expectLater(
      service.submitErrorReport(description: 'x'),
      throwsA(same(kInvalidResponseException)),
    );
  });

  test('maps a transport-level error to the network message', () async {
    transport.errorToThrow = kNetworkException;
    await expectLater(
      service.submitErrorReport(description: 'x'),
      throwsA(same(kNetworkException)),
    );
  });
}
