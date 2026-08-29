import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'api_exception.dart';
import 'api_response.dart';
import 'http_transport.dart';

/// Thin request builder shared by every Parsik API call (banners, clicks,
/// error reports, advertising requests) — one client, one base URL, one
/// timeout/redirect policy, so features don't each build their own transport.
class SecureApiClient {
  // Kept as named params (not initializing formals) so callers in other
  // files can pass baseUrl/transport by name — an initializing formal would
  // force the external parameter name to match the private field name.
  SecureApiClient({required String baseUrl, required HttpTransport transport})
    : _baseUri = Uri.parse(baseUrl),
      // ignore: prefer_initializing_formals
      _transport = transport;

  final Uri _baseUri;
  final HttpTransport _transport;

  Future<ApiResponse> get(
    String path, {
    Map<String, String>? queryParameters,
    required Map<String, String> headers,
  }) {
    final Uri uri = _baseUri
        .resolve(path)
        .replace(queryParameters: (queryParameters?.isEmpty ?? true) ? null : queryParameters);
    return _guard(() => _transport.send(method: 'GET', uri: uri, headers: headers));
  }

  Future<ApiResponse> post(
    String path, {
    required Map<String, String> headers,
    required Object body,
  }) {
    final Uri uri = _baseUri.resolve(path);
    return _guard(
      () => _transport.send(
        method: 'POST',
        uri: uri,
        headers: headers,
        body: jsonEncode(body),
      ),
    );
  }

  Future<ApiResponse> _guard(Future<ApiResponse> Function() action) async {
    try {
      return await action();
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw kNetworkException;
    } on SocketException {
      throw kNetworkException;
    } on HttpException {
      throw kNetworkException;
    }
  }

  void close() => _transport.close();
}
