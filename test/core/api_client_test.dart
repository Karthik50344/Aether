import 'package:aether_app/core/errors/app_exception.dart';
import 'package:aether_app/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_http_adapter.dart';

void main() {
  late FakeHttpAdapter http;
  late DateTime clock;
  late ApiClient api;

  setUp(() {
    http = FakeHttpAdapter();
    clock = DateTime.utc(2026, 11, 15, 12);
    final ApiClient base = ApiClient.forBaseUrl('https://example.test', adapter: http);
    // Rebuild with an injectable clock and no retry delay.
    api = ApiClient(
      Dio(BaseOptions(
        baseUrl: 'https://example.test',
        responseType: ResponseType.plain,
        validateStatus: (_) => true,
      ),)..httpClientAdapter = http,
      now: () => clock,
      retryDelay: Duration.zero,
    );
    expect(base, isNotNull);
  });

  test('decodes a 200 JSON body and drops null query values', () async {
    http.enqueueJson('{"a":1}');
    final Object? r = await api.getJson('/x', query: <String, Object?>{'k': 'v', 'n': null});
    expect(r, <String, dynamic>{'a': 1});
    expect(http.requests.single.uri.toString(), 'https://example.test/x?k=v');
  });

  test('429 -> RateLimited with Retry-After, then cooldown blocks the network',
      () async {
    http.enqueueJson('{}', status: 429, headers: <String, List<String>>{
      'retry-after': <String>['30'],
    },);
    await expectLater(
      api.getJson('/x'),
      throwsA(isA<RateLimitedException>()
          .having((e) => e.retryAfter, 'retryAfter', const Duration(seconds: 30)),),
    );
    expect(http.requests, hasLength(1));

    // Still cooling down: fails fast, no second request.
    await expectLater(api.getJson('/x'), throwsA(isA<RateLimitedException>()));
    expect(http.requests, hasLength(1));
    expect(api.cooldownRemaining, isNotNull);

    // After the cooldown the network is used again.
    clock = clock.add(const Duration(seconds: 31));
    http.enqueueJson('[]');
    expect(await api.getJson('/x'), <dynamic>[]);
    expect(http.requests, hasLength(2));
    expect(api.cooldownRemaining, isNull);
  });

  test('418 (IP ban) without header uses the longer default cooldown', () async {
    http.enqueueJson('{}', status: 418);
    await expectLater(api.getJson('/x'), throwsA(isA<RateLimitedException>()));
    expect(api.cooldownRemaining, const Duration(minutes: 2));
  });

  test('HTTP 400 with code -1121 -> NotFound', () async {
    http.enqueueJson('{"code":-1121,"msg":"Invalid symbol."}', status: 400);
    await expectLater(api.getJson('/x'), throwsA(isA<NotFoundException>()));
  });

  test('HTTP 404 -> NotFound; HTTP 500 -> Server with status', () async {
    http.enqueueJson('{}', status: 404);
    await expectLater(api.getJson('/x'), throwsA(isA<NotFoundException>()));
    http.enqueueJson('{}', status: 503);
    await expectLater(
      api.getJson('/x'),
      throwsA(isA<ServerException>().having((e) => e.statusCode, 'status', 503)),
    );
  });

  test('timeout is retried once, then surfaces as RequestTimeout', () async {
    http.enqueueError(DioExceptionType.receiveTimeout);
    http.enqueueError(DioExceptionType.receiveTimeout);
    await expectLater(api.getJson('/x'), throwsA(isA<RequestTimeoutException>()));
    expect(http.requests, hasLength(2));
  });

  test('a transient failure followed by success returns the data', () async {
    http.enqueueError(DioExceptionType.connectionError);
    http.enqueueJson('{"ok":true}');
    expect(await api.getJson('/x'), <String, dynamic>{'ok': true});
    expect(http.requests, hasLength(2));
  });

  test('retries: 0 makes a single attempt', () async {
    http.enqueueError(DioExceptionType.connectionError);
    await expectLater(
      api.getJson('/x', retries: 0),
      throwsA(isA<NetworkUnavailableException>()),
    );
    expect(http.requests, hasLength(1));
  });

  test('invalid JSON -> ParseException', () async {
    http.enqueueJson('<html>oops</html>');
    await expectLater(api.getJson('/x'), throwsA(isA<ParseException>()));
  });

  test('a large body is decoded (background isolate path)', () async {
    final String big = '[${List<String>.filled(40000, '"0123456789"').join(',')}]';
    expect(big.length, greaterThan(256 * 1024));
    http.enqueueJson(big);
    final Object? r = await api.getJson('/x');
    expect((r! as List<dynamic>).length, 40000);
  });
}
