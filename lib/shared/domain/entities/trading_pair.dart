import 'package:equatable/equatable.dart';

/// A Binance Spot trading pair with its 24h statistics.
///
/// `BTCUSDT` = base asset BTC priced in quote asset USDT. All figures are
/// specific to Binance Spot - they are NOT global market statistics.
///
/// Numbers are `double` because they are only displayed / compared / summed
/// for aggregates; no order or balance arithmetic exists in this app.
class TradingPair extends Equatable {
  const TradingPair({
    required this.symbol,
    required this.baseAsset,
    required this.quoteAsset,
    required this.lastPrice,
    required this.priceChange,
    required this.priceChangePercent,
    required this.highPrice,
    required this.lowPrice,
    required this.volume,
    required this.quoteVolume,
    this.tradeCount,
    this.openPrice,
    this.weightedAvgPrice,
  });

  /// Exchange symbol, e.g. `BTCUSDT`.
  final String symbol;
  final String baseAsset;
  final String quoteAsset;

  final double lastPrice;

  /// Absolute change over the rolling 24h window, in quote units.
  final double priceChange;

  /// Percentage change over 24h (3.42 means +3.42 %).
  final double priceChangePercent;
  final double highPrice;
  final double lowPrice;

  /// 24h traded volume in base-asset units.
  final double volume;

  /// 24h traded volume in quote-asset units.
  final double quoteVolume;

  /// Number of trades in the 24h window, when reported.
  final int? tradeCount;

  /// Price at the start of the 24h window.
  final double? openPrice;

  /// 24h volume-weighted average price on Binance Spot.
  final double? weightedAvgPrice;

  /// `BTC/USDT`
  String get displayName => '$baseAsset/$quoteAsset';

  bool get isPositive => priceChangePercent >= 0;

  @override
  List<Object?> get props => <Object?>[
        symbol,
        baseAsset,
        quoteAsset,
        lastPrice,
        priceChange,
        priceChangePercent,
        highPrice,
        lowPrice,
        volume,
        quoteVolume,
        tradeCount,
        openPrice,
        weightedAvgPrice,
      ];
}
