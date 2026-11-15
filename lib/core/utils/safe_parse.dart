/// Null-safe parsing helpers for loosely typed JSON (Binance sends numbers as
/// strings). They never throw; callers decide whether `null` means "skip the
/// row" or "fail with ParseException".
library;

/// `"123.45"`, `123.45` or `123` -> double. NaN / infinity -> null.
double? parseDouble(Object? value) {
  if (value is num) {
    final double d = value.toDouble();
    return d.isFinite ? d : null;
  }
  if (value is String) {
    final double? d = double.tryParse(value);
    return (d != null && d.isFinite) ? d : null;
  }
  return null;
}

/// `"42"`, `42` or `42.0` -> int.
int? parseInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.isFinite ? value.toInt() : null;
  if (value is String) return int.tryParse(value);
  return null;
}

/// Epoch milliseconds -> UTC [DateTime].
DateTime? parseEpochMillis(Object? value) {
  final int? ms = parseInt(value);
  if (ms == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
}

/// Non-empty string or null.
String? parseString(Object? value) {
  if (value is String && value.isNotEmpty) return value;
  return null;
}
