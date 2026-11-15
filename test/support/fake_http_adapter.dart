import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Scripted Dio adapter: each request pops the next responder; every request
/// is recorded so tests can assert paths / query strings / call counts.
class FakeHttpAdapter implements HttpClientAdapter {
  final List<FutureOr<ResponseBody> Function(RequestOptions)> _queue =
      <FutureOr<ResponseBody> Function(RequestOptions)>[];
  final List<RequestOptions> requests = <RequestOptions>[];

  /// Used when the queue is empty.
  FutureOr<ResponseBody> Function(RequestOptions)? fallback;

  void enqueue(FutureOr<ResponseBody> Function(RequestOptions) responder) =>
      _queue.add(responder);

  void enqueueJson(String body,
          {int status = 200, Map<String, List<String>>? headers}) =>
      enqueue((_) => json(body, status: status, headers: headers));

  void enqueueError(DioExceptionType type) => enqueue((RequestOptions o) =>
      throw DioException(requestOptions: o, type: type));

  static ResponseBody json(String body,
          {int status = 200, Map<String, List<String>>? headers}) =>
      ResponseBody.fromString(
        body,
        status,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>['application/json'],
          ...?headers,
        },
      );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (_queue.isNotEmpty) return _queue.removeAt(0)(options);
    final FutureOr<ResponseBody> Function(RequestOptions)? f = fallback;
    if (f != null) return f(options);
    throw StateError('FakeHttpAdapter: no response queued for ${options.uri}');
  }

  @override
  void close({bool force = false}) {}
}
