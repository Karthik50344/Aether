sealed class AppException implements Exception {
  const AppException(this.message);

  /// Human-readable, safe to show in the UI.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// No connectivity (offline, DNS failure, connection refused).
final class NetworkUnavailableException extends AppException {
  const NetworkUnavailableException([
    super.message = 'No internet connection. Check your network and retry.',
  ]);
}

/// Connect / send / receive timeout.
final class RequestTimeoutException extends AppException {
  const RequestTimeoutException([
    super.message = 'The request timed out. Please try again.',
  ]);
}

/// HTTP 429 (rate limit) or 418 (IP temporarily banned) from Binance.
final class RateLimitedException extends AppException {
  const RateLimitedException({
    this.retryAfter,
    String message = 'Too many requests. Please wait a moment and retry.',
  }) : super(message);

  /// Value of the `Retry-After` header, when the server sent one.
  final Duration? retryAfter;
}

/// Any other non-2xx HTTP response.
final class ServerException extends AppException {
  const ServerException({
    required this.statusCode,
    String message = 'The market data service returned an error.',
  }) : super(message);

  final int statusCode;
}

/// The response arrived but its shape was not what we expect.
final class ParseException extends AppException {
  const ParseException([
    super.message = 'Received unexpected data from the market data service.',
  ]);
}

/// A requested symbol / series does not exist.
final class NotFoundException extends AppException {
  const NotFoundException([super.message = 'The requested item was not found.']);
}

/// Anything we did not anticipate. Keeps the original object for logging.
final class UnknownException extends AppException {
  const UnknownException({
    this.cause,
    String message = 'An unexpected error occurred.',
  }) : super(message);

  final Object? cause;
}
