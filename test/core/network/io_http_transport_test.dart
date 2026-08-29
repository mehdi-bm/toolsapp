import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:toolbax/core/network/api_exception.dart';
import 'package:toolbax/core/network/http_transport.dart';

void main() {
  late HttpServer server;
  late HttpServer otherOriginServer;

  tearDown(() async {
    await server.close(force: true);
    await otherOriginServer.close(force: true);
  });

  Future<HttpServer> bindLocal() => HttpServer.bind(InternetAddress.loopbackIPv4, 0);

  test('follows a same-origin redirect chain within the hop limit', () async {
    server = await bindLocal();
    otherOriginServer = await bindLocal(); // unused in this case, just to satisfy tearDown

    server.listen((HttpRequest request) async {
      if (request.uri.path == '/start') {
        request.response.statusCode = 302;
        request.response.headers.set(
          HttpHeaders.locationHeader,
          'http://${server.address.address}:${server.port}/final',
        );
        await request.response.close();
      } else {
        request.response.statusCode = 200;
        request.response.write('{"ok":true}');
        await request.response.close();
      }
    });

    final transport = IoHttpTransport(maxRedirects: 3);
    final response = await transport.send(
      method: 'GET',
      uri: Uri.parse('http://${server.address.address}:${server.port}/start'),
      headers: const {'X-API-KEY': 'secret'},
    );

    expect(response.statusCode, 200);
    expect(response.body, '{"ok":true}');
    transport.close();
  });

  test('rejects a cross-origin redirect instead of leaking headers there', () async {
    server = await bindLocal();
    otherOriginServer = await bindLocal();

    bool otherOriginHitWithApiKey = false;
    otherOriginServer.listen((HttpRequest request) async {
      otherOriginHitWithApiKey =
          request.headers.value('X-API-KEY') == 'secret';
      request.response.statusCode = 200;
      await request.response.close();
    });

    server.listen((HttpRequest request) async {
      request.response.statusCode = 302;
      request.response.headers.set(
        HttpHeaders.locationHeader,
        'http://${otherOriginServer.address.address}:${otherOriginServer.port}/steal',
      );
      await request.response.close();
    });

    final transport = IoHttpTransport(maxRedirects: 3);

    await expectLater(
      transport.send(
        method: 'GET',
        uri: Uri.parse('http://${server.address.address}:${server.port}/start'),
        headers: const {'X-API-KEY': 'secret'},
      ),
      throwsA(same(kInvalidResponseException)),
    );
    expect(otherOriginHitWithApiKey, isFalse);
    transport.close();
  });

  test('gives up after exceeding the redirect hop limit', () async {
    server = await bindLocal();
    otherOriginServer = await bindLocal();

    int hops = 0;
    server.listen((HttpRequest request) async {
      hops++;
      request.response.statusCode = 302;
      request.response.headers.set(
        HttpHeaders.locationHeader,
        'http://${server.address.address}:${server.port}/hop$hops',
      );
      await request.response.close();
    });

    final transport = IoHttpTransport(maxRedirects: 2);

    await expectLater(
      transport.send(
        method: 'GET',
        uri: Uri.parse('http://${server.address.address}:${server.port}/start'),
        headers: const {},
      ),
      throwsA(same(kInvalidResponseException)),
    );
    // Initial request + up to maxRedirects follow-ups, never unbounded.
    expect(hops, lessThanOrEqualTo(3));
    transport.close();
  });

  test('rejects a response larger than the configured byte cap', () async {
    server = await bindLocal();
    otherOriginServer = await bindLocal();

    server.listen((HttpRequest request) async {
      request.response.statusCode = 200;
      request.response.write('x' * 1000);
      await request.response.close();
    });

    final transport = IoHttpTransport(maxResponseBytes: 100);

    await expectLater(
      transport.send(
        method: 'GET',
        uri: Uri.parse('http://${server.address.address}:${server.port}/big'),
        headers: const {},
      ),
      throwsA(same(kInvalidResponseException)),
    );
    transport.close();
  });

  test('sends the request body as UTF-8 JSON', () async {
    server = await bindLocal();
    otherOriginServer = await bindLocal();

    String? receivedBody;
    server.listen((HttpRequest request) async {
      receivedBody = await utf8.decoder.bind(request).join();
      request.response.statusCode = 201;
      await request.response.close();
    });

    final transport = IoHttpTransport();
    await transport.send(
      method: 'POST',
      uri: Uri.parse('http://${server.address.address}:${server.port}/post'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'a': 'سلام'}),
    );

    expect(receivedBody, jsonEncode({'a': 'سلام'}));
    transport.close();
  });
}
