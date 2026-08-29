import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/config/ads_runtime_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/secure_api_client.dart';
import '../domain/ad_banner_model.dart';
import '../domain/ad_click_result.dart';
import '../domain/advertising_gateway.dart';

class AdvertisingService implements AdvertisingGateway {
  AdvertisingService({required SecureApiClient client, required AdsRuntimeConfig config})
    // ignore: prefer_initializing_formals
    : _client = client,
      // ignore: prefer_initializing_formals
      _config = config;

  final SecureApiClient _client;
  final AdsRuntimeConfig _config;

  @override
  bool get isConfigured => _config.isConfigured;

  Map<String, String> get _authHeaders => {
    'Accept': 'application/json',
    'X-API-KEY': _config.apiKey,
    'X-EXTERNAL-APP-API-KEY': _config.externalAppApiKey,
  };

  @override
  String resolvePublicUrl(String value) {
    final Uri? parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) {
      final bool isHttps = parsed.scheme == 'https';
      final bool isDevHttp = kDebugMode && parsed.scheme == 'http';
      if (!isHttps && !isDevHttp) throw kInvalidResponseException;
      return parsed.toString();
    }
    return Uri.parse(_config.baseUrl).resolve(value).toString();
  }

  @override
  Future<List<AdBannerModel>> fetchBanners() async {
    if (!isConfigured) return const [];

    final Map<String, String> query = {'platform': _config.platform};
    if (_config.sectionCode.isNotEmpty) {
      query['sectionCode'] = _config.sectionCode;
    }

    final response = await _client.get(
      'api/public/ads/banners',
      queryParameters: query,
      headers: _authHeaders,
    );

    if (response.statusCode != 200) throw mapStatusToException(response.statusCode);
    if (response.body.trim().isEmpty) return const [];

    final Object? decoded = _tryDecode(response.body);
    if (decoded == null) return const [];
    if (decoded is! List) throw kInvalidResponseException;

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(AdBannerModel.tryParse)
        .whereType<AdBannerModel>()
        .toList();
  }

  @override
  Future<AdClickResult> registerClick({
    required String bannerId,
    required String externalUserId,
  }) async {
    if (!isConfigured) throw kNotConfiguredException;

    final Map<String, Object?> body = {
      'bannerId': bannerId,
      'externalUserId': externalUserId,
      'appName': _config.appName,
      'platform': _config.platform,
      'referrerUrl':
          'https://parsikhesab.com/apps/${_config.appName}/ads/$bannerId',
    };

    final response = await _client.post(
      'api/public/ads/click',
      headers: {..._authHeaders, 'Content-Type': 'application/json; charset=utf-8'},
      body: body,
    );

    if (response.statusCode != 201) throw mapStatusToException(response.statusCode);

    final Object? decoded = _tryDecode(response.body);
    if (decoded is! Map<String, dynamic>) throw kInvalidResponseException;

    final String clickId = (decoded['clickId'] as String?)?.trim() ?? '';
    final String destinationUrl =
        (decoded['destinationUrl'] as String?)?.trim() ?? '';
    if (clickId.isEmpty || destinationUrl.isEmpty) {
      throw kInvalidResponseException;
    }

    return AdClickResult(clickId: clickId, destinationUrl: destinationUrl);
  }

  Object? _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      throw kInvalidResponseException;
    }
  }

  @override
  void close() => _client.close();
}
