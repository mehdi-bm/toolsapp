import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:toolbax/core/config/ads_runtime_config.dart';
import 'package:toolbax/core/network/api_exception.dart';
import 'package:toolbax/core/network/api_response.dart';
import 'package:toolbax/core/network/secure_api_client.dart';
import 'package:toolbax/features/advertising/data/advertising_service.dart';

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
  late AdvertisingService service;

  setUp(() {
    transport = FakeHttpTransport();
    service = AdvertisingService(
      client: SecureApiClient(baseUrl: _kBaseUrl, transport: transport),
      config: _kConfiguredTestConfig,
    );
  });

  test('does not call the network when the API keys are missing', () async {
    final unconfigured = AdvertisingService(
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

    expect(unconfigured.isConfigured, isFalse);
    expect(await unconfigured.fetchBanners(), isEmpty);
    expect(transport.lastUri, isNull);
  });

  group('fetchBanners', () {
    test('sends both auth headers and the platform query parameter', () async {
      transport.responseToReturn = const ApiResponse(
        statusCode: 200,
        body: '[]',
      );

      await service.fetchBanners();

      expect(transport.lastMethod, 'GET');
      expect(transport.lastUri?.path, '/api/public/ads/banners');
      expect(transport.lastUri?.queryParameters['platform'], 'Android');
      expect(transport.lastUri?.queryParameters.containsKey('sectionCode'), isFalse);
      expect(transport.lastHeaders?['Accept'], 'application/json');
      expect(transport.lastHeaders?['X-API-KEY'], isNotNull);
      expect(transport.lastHeaders?['X-EXTERNAL-APP-API-KEY'], isNotNull);
    });

    test('includes sectionCode in the query when configured', () async {
      final withSection = AdvertisingService(
        client: SecureApiClient(baseUrl: _kBaseUrl, transport: transport),
        config: const AdsRuntimeConfig(
          baseUrl: _kBaseUrl,
          apiKey: 'k',
          externalAppApiKey: 'k2',
          appName: 'toolsApp',
          platform: 'Android',
          sectionCode: 'home-main',
        ),
      );
      transport.responseToReturn = const ApiResponse(
        statusCode: 200,
        body: '[]',
      );

      await withSection.fetchBanners();

      expect(transport.lastUri?.queryParameters['sectionCode'], 'home-main');
    });

    test('parses a valid banner list', () async {
      transport.responseToReturn = ApiResponse(
        statusCode: 200,
        body: jsonEncode([
          {
            'bannerId': 'b1',
            'bannerTitle': ' عنوان ',
            'imageUrl': '/uploads/banners/x.webp',
            'destinationUrl': 'https://example.com/landing',
            'campaignTitle': 'کمپین',
            'sectionName': 'صفحه اصلی',
            'sectionCode': 'home-main',
          },
        ]),
      );

      final banners = await service.fetchBanners();

      expect(banners, hasLength(1));
      expect(banners.single.bannerId, 'b1');
      expect(banners.single.bannerTitle, 'عنوان');
    });

    test('drops items with a missing or empty bannerId', () async {
      transport.responseToReturn = ApiResponse(
        statusCode: 200,
        body: jsonEncode([
          {'bannerTitle': 'no id here'},
          {'bannerId': '', 'bannerTitle': 'empty id'},
          {'bannerId': 'ok', 'bannerTitle': 'kept'},
        ]),
      );

      final banners = await service.fetchBanners();

      expect(banners, hasLength(1));
      expect(banners.single.bannerId, 'ok');
    });

    test('resolves a relative imageUrl against the base URL', () async {
      final String resolved = service.resolvePublicUrl(
        '/uploads/banners/x.webp',
      );
      expect(resolved, 'https://ads.parsikonline.ir/uploads/banners/x.webp');
    });

    test('returns an empty list for a null/empty response body', () async {
      transport.responseToReturn = const ApiResponse(
        statusCode: 200,
        body: '',
      );
      expect(await service.fetchBanners(), isEmpty);
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
          service.fetchBanners(),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              entry.value,
            ),
          ),
        );
      });
    }

    test('maps invalid JSON to the generic invalid-response message', () async {
      transport.responseToReturn = const ApiResponse(
        statusCode: 200,
        body: 'not json{{',
      );
      await expectLater(
        service.fetchBanners(),
        throwsA(same(kInvalidResponseException)),
      );
    });

    test('maps a transport-level error to the network message', () async {
      transport.errorToThrow = kNetworkException;
      await expectLater(
        service.fetchBanners(),
        throwsA(same(kNetworkException)),
      );
    });
  });

  group('registerClick', () {
    test('sends the full payload with the correct referrer URL shape', () async {
      transport.responseToReturn = ApiResponse(
        statusCode: 201,
        body: jsonEncode({
          'clickId': 'c1',
          'bannerId': 'b1',
          'destinationUrl': 'https://example.com/landing',
        }),
      );

      final result = await service.registerClick(
        bannerId: 'b1',
        externalUserId: 'abc123',
      );

      expect(transport.lastMethod, 'POST');
      expect(transport.lastUri?.path, '/api/public/ads/click');
      expect(
        transport.lastHeaders?['Content-Type'],
        'application/json; charset=utf-8',
      );

      final Map<String, dynamic> sentBody =
          jsonDecode(transport.lastBody!) as Map<String, dynamic>;
      expect(sentBody['bannerId'], 'b1');
      expect(sentBody['externalUserId'], 'abc123');
      expect(sentBody['platform'], 'Android');
      expect(sentBody['referrerUrl'], contains('/ads/b1'));

      expect(result.clickId, 'c1');
      expect(result.destinationUrl, 'https://example.com/landing');
    });

    test('rejects a 201 response missing clickId/destinationUrl', () async {
      transport.responseToReturn = ApiResponse(
        statusCode: 201,
        body: jsonEncode({'clickId': ''}),
      );
      await expectLater(
        service.registerClick(bannerId: 'b1', externalUserId: 'u1'),
        throwsA(same(kInvalidResponseException)),
      );
    });

    test('maps a non-201 status to an exception', () async {
      transport.responseToReturn = const ApiResponse(
        statusCode: 500,
        body: '{}',
      );
      await expectLater(
        service.registerClick(bannerId: 'b1', externalUserId: 'u1'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
