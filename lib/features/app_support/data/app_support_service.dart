import 'dart:convert';

import '../../../core/config/ads_runtime_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/secure_api_client.dart';
import '../domain/app_support_gateway.dart';
import '../domain/support_receipt.dart';

class AppSupportService implements AppSupportGateway {
  AppSupportService({required SecureApiClient client, required AdsRuntimeConfig config})
    // ignore: prefer_initializing_formals
    : _client = client,
      // ignore: prefer_initializing_formals
      _config = config;

  final SecureApiClient _client;
  final AdsRuntimeConfig _config;

  @override
  bool get isConfigured => _config.isConfigured;

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json; charset=utf-8',
    'X-API-KEY': _config.apiKey,
    'X-EXTERNAL-APP-API-KEY': _config.externalAppApiKey,
  };

  @override
  Future<SupportReceipt> submitErrorReport({required String description}) {
    return _submit(
      path: 'api/public/app-submissions/error-reports',
      body: {'description': description.trim()},
    );
  }

  @override
  Future<SupportReceipt> submitAdvertisingRequest({
    required String fullName,
    required String phoneNumber,
    required String province,
    required String city,
    required String details,
  }) {
    return _submit(
      path: 'api/public/app-submissions/advertising-requests',
      body: {
        'fullName': fullName.trim(),
        'phoneNumber': phoneNumber.trim(),
        'province': province.trim(),
        'city': city.trim(),
        'details': details.trim(),
      },
    );
  }

  Future<SupportReceipt> _submit({
    required String path,
    required Map<String, Object?> body,
  }) async {
    if (!isConfigured) throw kNotConfiguredException;

    final response = await _client.post(path, headers: _headers, body: body);

    if (response.statusCode != 201) throw mapStatusToException(response.statusCode);

    final Object? decoded = _tryDecode(response.body);
    if (decoded is! Map<String, dynamic>) throw kInvalidResponseException;

    final String id = (decoded['id'] as String?)?.trim() ?? '';
    if (id.isEmpty) throw kInvalidResponseException;

    return SupportReceipt(
      id: id,
      type: (decoded['type'] as String?)?.trim() ?? '',
      status: (decoded['status'] as String?)?.trim() ?? '',
    );
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
