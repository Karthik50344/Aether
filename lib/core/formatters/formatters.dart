import 'package:intl/intl.dart';

/// Number formatting shared by every screen. Pure functions, locale-fixed to
/// en_US so output is deterministic (and testable).
abstract final class Fmt {
  static final NumberFormat _grouped2 = NumberFormat('#,##0.00', 'en_US');
  static final NumberFormat _int = NumberFormat('#,##0', 'en_US');

  /// "1,428"
  static String integer(num v) => _int.format(v);

  /// Prices adapt their precision to magnitude so tiny coins stay readable:
  /// 67,420.50 | 178.45 | 7.3200 | 0.052300 | 0.00001040
  static String price(double v) {
    if (v.isNaN || v.isInfinite) return '--';
    final double a = v.abs();
    if (a >= 1000) return _grouped2.format(v);
    if (a >= 100) return v.toStringAsFixed(2);
    if (a >= 1) return v.toStringAsFixed(4);
    if (a >= 0.01) return v.toStringAsFixed(6);
    if (a == 0) return '0.00';
    return v.toStringAsFixed(8);
  }

  /// Price with a "$" prefix for dollar-like quote assets ("$67,420.50"),
  /// plain otherwise ("0.052000" for ETH/BTC).
  static String pricedIn(double v, String quote) =>
      isDollarQuote(quote) ? '\$${price(v)}' : price(v);

  /// "+3.42%" / "-2.10%" / "0.00%"
  static String percent(double v, {bool sign = true}) {
    if (v.isNaN || v.isInfinite) return '--';
    final String body = '${v.abs().toStringAsFixed(2)}%';
    if (!sign) return body;
    if (v > 0) return '+$body';
    if (v < 0) return '-$body';
    return body;
  }

  /// Volume / notional amounts: 12.4B, 680M, 3.9K, or full "12,400,000,000"
  /// when [compact] is false (Settings > Compact Metrics).
  static String volume(double v, {bool compact = true}) {
    if (v.isNaN || v.isInfinite) return '--';
    if (!compact) return _int.format(v.round());
    final double a = v.abs();
    if (a >= 1e12) return '${_trim(v / 1e12)}T';
    if (a >= 1e9) return '${_trim(v / 1e9)}B';
    if (a >= 1e6) return '${_trim(v / 1e6)}M';
    if (a >= 1e3) return '${_trim(v / 1e3)}K';
    if (a >= 100) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }

  static String _trim(double v) {
    final String s = v.abs() >= 100 ? v.toStringAsFixed(1) : v.toStringAsFixed(2);
    return s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
  }

  /// Quote-aware amount: "$12.4B" for dollar quotes, "1.2K BTC" otherwise.
  static String quoteAmount(double v, String quote, {bool compact = true}) {
    final String n = volume(v, compact: compact);
    return isDollarQuote(quote) ? '\$$n' : '$n $quote';
  }

  /// Quote assets worth about one US dollar (stablecoins).
  static bool isDollarQuote(String quote) =>
      quote == 'USDT' || quote == 'FDUSD' || quote == 'USDC' || quote == 'BUSD';

  /// "1s ago", "12s ago", "3m ago", "2h ago".
  static String ago(DateTime then, DateTime now) {
    final int s = now.difference(then).inSeconds;
    if (s < 1) return 'just now';
    if (s < 60) return '${s}s ago';
    if (s < 3600) return '${s ~/ 60}m ago';
    return '${s ~/ 3600}h ago';
  }

  // --- dates & signed amounts --------------------------------------------

  static final DateFormat _hms = DateFormat('HH:mm:ss', 'en_US');
  static final DateFormat _hm = DateFormat('HH:mm', 'en_US');
  static final DateFormat _md = DateFormat('MMM d', 'en_US');
  static final DateFormat _mdhm = DateFormat('MMM d, HH:mm', 'en_US');
  static final DateFormat _my = DateFormat("MMM ''yy", 'en_US');

  /// "14:42:01" (UTC).
  static String clockSeconds(DateTime t) => _hms.format(t.toUtc());

  /// X-axis label for a candle series with Binance [interval]
  /// ("15m" -> "14:30", "4h" -> "Nov 12", "1d" -> "Nov 12").
  static String chartAxis(DateTime t, String interval) {
    final DateTime u = t.toUtc();
    if (interval.endsWith('m')) return _hm.format(u);
    if (interval == '1d') return _md.format(u);
    return _md.format(u);
  }

  /// "Today, 14:30 UTC" or "Nov 12, 14:30 UTC".
  static String chartStamp(DateTime t, {DateTime? now}) {
    final DateTime u = t.toUtc();
    final DateTime n = (now ?? DateTime.now()).toUtc();
    final bool today = u.year == n.year && u.month == n.month && u.day == n.day;
    return today ? 'Today, ${_hm.format(u)} UTC' : '${_mdhm.format(u)} UTC';
  }

  /// Month + year label (long ranges).
  static String monthYear(DateTime t) => _my.format(t.toUtc());

  /// "+$2,231.80" / "-$12.00" (dollar quotes) or "+0.001200" (others).
  static String signedAmount(double v, String quote) {
    final String sign = v > 0 ? '+' : (v < 0 ? '-' : '');
    final String body = price(v.abs());
    return isDollarQuote(quote) ? '$sign\$$body' : '$sign$body';
  }
}
