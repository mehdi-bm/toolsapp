import 'dart:convert';
import 'dart:io';

import 'api_exception.dart';
import 'api_response.dart';

/// Low-level HTTP transport. Abstracted so tests can substitute a fake that
/// records requests and returns canned responses without touching the
/// network.
abstract class HttpTransport {
  Future<ApiResponse> send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  });

  void close();
}

/// A `dart:io`-based transport with the security/robustness properties the
/// Parsik advertising API contract requires: manual (not automatic)
/// redirect handling capped at 3 same-origin hops so credential headers are
/// never leaked cross-domain, bounded connect/receive timeouts, and a 2MB
/// response-size cap.
class IoHttpTransport implements HttpTransport {
  IoHttpTransport({
    Duration connectTimeout = const Duration(seconds: 8),
    Duration receiveTimeout = const Duration(seconds: 12),
    int maxResponseBytes = 2 * 1024 * 1024,
    int maxRedirects = 3,
  }) : _client = HttpClient()..connectionTimeout = connectTimeout,
       // ignore: prefer_initializing_formals
       _receiveTimeout = receiveTimeout,
       // ignore: prefer_initializing_formals
       _maxResponseBytes = maxResponseBytes,
       // ignore: prefer_initializing_formals
       _maxRedirects = maxRedirects;

  final HttpClient _client;
  final Duration _receiveTimeout;
  final int _maxResponseBytes;
  final int _maxRedirects;

  @override
  Future<ApiResponse> send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) async {
    final Uri origin = Uri(scheme: uri.scheme, host: uri.host, port: uri.port);
    Uri currentUri = uri;

    for (int hop = 0; hop <= _maxRedirects; hop++) {
      final HttpClientRequest request = await _client
          .openUrl(method, currentUri)
          .timeout(_receiveTimeout);
      request.followRedirects = false;
      headers.forEach(request.headers.set);
      if (body != null) {
        final List<int> encoded = utf8.encode(body);
        request.headers.contentLength = encoded.length;
        request.add(encoded);
      }

      final HttpClientResponse response = await request.close().timeout(
        _receiveTimeout,
      );

      final bool isRedirect =
          response.statusCode >= 300 && response.statusCode < 400;
      if (isRedirect) {
        final String? location = response.headers.value(
          HttpHeaders.locationHeader,
        );
        await response.drain<void>();
        if (location == null || hop == _maxRedirects) {
          throw kInvalidResponseException;
        }
        final Uri redirectUri = currentUri.resolve(location);
        final Uri redirectOrigin = Uri(
          scheme: redirectUri.scheme,
          host: redirectUri.host,
          port: redirectUri.port,
        );
        if (redirectOrigin != origin) {
          // Cross-origin redirect: never forward our API keys there.
          throw kInvalidResponseException;
        }
        currentUri = redirectUri;
        continue;
      }

      final String responseBody = await _readBounded(response);
      return ApiResponse(statusCode: response.statusCode, body: responseBody);
    }

    throw kInvalidResponseException;
  }

  Future<String> _readBounded(HttpClientResponse response) async {
    final List<int> bytes = <int>[];
    await for (final List<int> chunk in response.timeout(_receiveTimeout)) {
      bytes.addAll(chunk);
      if (bytes.length > _maxResponseBytes) {
        throw kInvalidResponseException;
      }
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  @override
  void close() => _client.close(force: true);
}
