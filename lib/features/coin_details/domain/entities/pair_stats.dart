import 'package:equatable/equatable.dart';

/// Figures of the "24H Market Statistics" grid. Everything comes from
/// `/ticker/24hr` plus (optionally) 8 daily klines; nothing is invented.
class PairStats extends Equatable {
  const PairStats({
    required this.high,
    required this.low,
    required this.baseVolume,
    required this.quoteVolume,
    required this.priceChange,
    required this.priceChangePercent,
    required this.lastPrice,
    this.tradeCount,
    this.tradesPerSecond,
    this.volumeVs7dAvgPercent,
    this.vwap,
    this.openPrice,
  });

  final double high;
  final double low;
  final double baseVolume;
  final double quoteVolume;
  final double priceChange;
  final double priceChangePercent;
  final double lastPrice;
  final int? tradeCount;

  /// `tradeCount / 86400` (average over the 24h window).
  final double? tradesPerSecond;

  /// 24h base volume vs the mean of the previous (up to 7) daily candles.
  final double? volumeVs7dAvgPercent;

  /// `weightedAvgPrice` of the 24h window (Binance VWAP).
  final double? vwap;
  final double? openPrice;

  /// How far the last price is below the 24h high (<= 0), in percent.
  double get fromHighPercent => high == 0 ? 0 : (lastPrice - high) / high * 100;

  /// How far the last price is above the 24h low (>= 0), in percent.
  double get aboveLowPercent => low == 0 ? 0 : (lastPrice - low) / low * 100;

  @override
  List<Object?> get props => <Object?>[
        high,
        low,
        baseVolume,
        quoteVolume,
        priceChange,
        priceChangePercent,
        lastPrice,
        tradeCount,
        tradesPerSecond,
        volumeVs7dAvgPercent,
        vwap,
        openPrice,
      ];
}
