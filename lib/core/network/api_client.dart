import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show compute;

import '../errors/app_exception.dart';

typedef NowFn = DateTime Function();

Object? _decodeJson(String body) => jsonDecode(body);

/// Thin JSON-over-HTTP GET client around Dio. It is the ONLY place that sees
/// Dio types: everything leaving it is either decoded JSON or an
/// [AppException].
///
/// Behaviour:
///  * every HTTP status is inspected here (`validateStatus` accepts all), so
///    mapping is explicit and testable;
///  * 429 / 418 -> [RateLimitedException] and a COOLDOWN: until `Retry-After`
///    (or a default) has passed, further calls fail immediately without
///    touching the network, so auto-refresh timers can never hammer Binance
///    into an IP ban;
///  * timeouts and connection failures are retried [maxRetries] times (GET is
///    idempotent) before surfacing;
///  * large bodies are decoded on a background isolate.
class ApiClient {
  ApiClient(
    this._dio, {
    NowFn? now,
    this.maxRetries = 1,
    this.retryDelay = const Duration(milliseconds: 400),
    this.defaultRateLimitCooldown = const Duration(seconds: 30),
    this.defaultBanCooldown = const Duration(minutes: 2),
  }) : _now = now ?? DateTime.now;

  /// Dio configured for Binance public market data.
  factory ApiClient.forBaseUrl(
    String baseUrl, {
    HttpClientAdapter? adapter,
  }) {
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        // /ticker/24hr for every symbol is a ~1-2 MB response.
        receiveTimeout: const Duration(seconds: 25),
        responseType: ResponseType.plain,
        headers: const <String, Object>{'Accept': 'application/json'},
        validateStatus: (_) => true,
      ),
    );
    if (adapter != null) dio.httpClientAdapter = adapter;
    return ApiClient(dio);
  }

  final Dio _dio;
  final NowFn _now;
  final int maxRetries;
  final Duration retryDelay;
  final Duration defaultRateLimitCooldown;
  final Duration defaultBanCooldown;

  DateTime? _blockedUntil;

  /// Time left of a rate-limit cooldown, or null when requests may be sent.
  Duration? get cooldownRemaining {
    final DateTime? until = _blockedUntil;
    if (until == null) return null;
    final Duration left = until.difference(_now());
    if (left <= Duration.zero) {
      _blockedUntil = null;
      return null;
    }
    return left;
  }

  /// GET [path] and return the decoded JSON body.
  Future<Object?> getJson(
    String path, {
    Map<String, Object?>? query,
    int? retries,
  }) async {
    final Duration? cooling = cooldownRemaining;
    if (cooling != null) throw _rateLimited(cooling);

    final int attempts = (retries ?? maxRetries) + 1;
    for (int attempt = 1;; attempt++) {
      try {
        return await _once(path, query);
      } on RequestTimeoutException {
        if (attempt >= attempts) rethrow;
      } on NetworkUnavailableException {
        if (attempt >= attempts) rethrow;
      }
      await Future<void>.delayed(retryDelay);
    }
  }

  Future<Object?> _once(String path, Map<String, Object?>? query) async {
    final Response<String> response;
    try {
      response = await _dio.get<String>(
        path,
        queryParameters: <String, Object?>{
          if (query != null)
            for (final MapEntry<String, Object?> e in query.entries)
              if (e.value != null) e.key: e.value,
        },
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      throw UnknownException(cause: e);
    }

    final int status = response.statusCode ?? 0;
    final String body = response.data ?? '';

    if (status >= 200 && status < 300) return _decode(body);

    if (status == 429 || status == 418) {
      final Duration wait = _retryAfter(response) ??
          (status == 418 ? defaultBanCooldown : defaultRateLimitCooldown);
      _blockedUntil = _now().add(wait);
      throw _rateLimited(wait);
    }
    if (status == 404 || _isInvalidSymbol(body)) {
      throw const NotFoundException('That trading pair was not found.');
    }
    throw ServerException(statusCode: status);
  }

  Future<Object?> _decode(String body) async {
    if (body.isEmpty) return null;
    try {
      return body.length > 256 * 1024
          ? await compute(_decodeJson, body)
          : jsonDecode(body);
    } on FormatException {
      throw const ParseException();
    }
  }

  static Duration? _retryAfter(Response<String> r) {
    final int? seconds = int.tryParse(r.headers.value('retry-after') ?? '');
    return seconds == null || seconds <= 0 ? null : Duration(seconds: seconds);
  }

  /// Binance answers HTTP 400 with `{"code":-1121,"msg":"Invalid symbol."}`.
  static bool _isInvalidSymbol(String body) {
    if (!body.contains('-1121')) return false;
    try {
      final Object? json = jsonDecode(body);
      return json is Map<String, dynamic> && json['code'] == -1121;
    } on FormatException {
      return false;
    }
  }

  static RateLimitedException _rateLimited(Duration wait) {
    final int s = wait.inSeconds < 1 ? 1 : wait.inSeconds;
    return RateLimitedException(
      retryAfter: wait,
      message: 'Too many requests. Try again in ${s < 60 ? '$s s' : '${(s / 60).ceil()} min'}.',
    );
  }

  static AppException _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const RequestTimeoutException();
      case DioExceptionType.connectionError:
        return const NetworkUnavailableException();
      case DioExceptionType.badCertificate:
        return const NetworkUnavailableException(
          'A secure connection could not be established.',
        );
      case DioExceptionType.cancel:
        return const UnknownException(message: 'The request was cancelled.');
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        if (e.error is SocketException) {
          return const NetworkUnavailableException();
        }
        return UnknownException(cause: e.error ?? e);
    }
  }
}
