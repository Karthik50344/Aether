import 'package:equatable/equatable.dart';

/// A chart range and the Binance kline request that produces it.
/// (Typed constants instead of an enum, per project rules.)
///
/// Binance valid intervals used: 1m, 5m, 15m, 1h, 4h, 1d (limit <= 1000).
class ChartPeriod extends Equatable {
  const ChartPeriod._({
    required this.id,
    required this.label,
    required this.interval,
    required this.limit,
  });

  /// Stable id, also what Settings persists ("1D").
  final String id;
  final String label;

  /// Binance kline interval string.
  final String interval;

  /// Number of candles requested.
  final int limit;

  static const ChartPeriod hour1 =
      ChartPeriod._(id: '1H', label: '1H', interval: '1m', limit: 60);
  static const ChartPeriod hours4 =
      ChartPeriod._(id: '4H', label: '4H', interval: '5m', limit: 48);
  static const ChartPeriod day1 =
      ChartPeriod._(id: '1D', label: '1D', interval: '15m', limit: 96);
  static const ChartPeriod week1 =
      ChartPeriod._(id: '1W', label: '1W', interval: '1h', limit: 168);
  static const ChartPeriod month1 =
      ChartPeriod._(id: '1M', label: '1M', interval: '4h', limit: 180);
  static const ChartPeriod year1 =
      ChartPeriod._(id: '1Y', label: '1Y', interval: '1d', limit: 365);

  /// In display order (matches Figma: 1H 4H 1D 1W 1M 1Y).
  static const List<ChartPeriod> all = <ChartPeriod>[
    hour1,
    hours4,
    day1,
    week1,
    month1,
    year1,
  ];

  static const ChartPeriod defaultPeriod = day1;

  /// Looks up a persisted id; unknown ids fall back to [defaultPeriod].
  static ChartPeriod fromId(String? id) {
    for (final ChartPeriod p in all) {
      if (p.id == id) return p;
    }
    return defaultPeriod;
  }

  @override
  List<Object?> get props => <Object?>[id];
}
