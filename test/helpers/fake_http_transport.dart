import 'package:toolbax/core/network/api_response.dart';
import 'package:toolbax/core/network/http_transport.dart';

/// Records the last request it was asked to send and returns a scripted
/// response (or throws a scripted error), so service-layer tests can verify
/// exact headers/query/body without touching the network.
class FakeHttpTransport implements HttpTransport {
  String? lastMethod;
  Uri? lastUri;
  Map<String, String>? lastHeaders;
  String? lastBody;
  bool closed = false;

  ApiResponse? responseToReturn;
  Object? errorToThrow;

  @override
  Future<ApiResponse> send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) async {
    lastMethod = method;
    lastUri = uri;
    lastHeaders = headers;
    lastBody = body;
    if (errorToThrow != null) throw errorToThrow!;
    return responseToReturn!;
  }

  @override
  void close() {
    closed = true;
  }
}
