import 'package:equatable/equatable.dart';

/// One kline (candlestick) of a trading pair.
class Candlestick extends Equatable {
  const Candlestick({
    required this.openTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.closeTime,
    required this.quoteAssetVolume,
    this.numberOfTrades,
    this.takerBuyBaseVolume,
    this.takerBuyQuoteVolume,
  });

  /// UTC.
  final DateTime openTime;
  final double open;
  final double high;
  final double low;
  final double close;

  /// Base-asset volume.
  final double volume;
  final DateTime closeTime;

  /// Quote-asset volume.
  final double quoteAssetVolume;
  final int? numberOfTrades;

  /// Portion of [volume] bought by takers (aggressive buyers), when reported.
  final double? takerBuyBaseVolume;

  /// Portion of [quoteAssetVolume] bought by takers, when reported.
  final double? takerBuyQuoteVolume;

  bool get isBullish => close >= open;

  @override
  List<Object?> get props => <Object?>[
        openTime,
        open,
        high,
        low,
        close,
        volume,
        closeTime,
        quoteAssetVolume,
        numberOfTrades,
        takerBuyBaseVolume,
        takerBuyQuoteVolume,
      ];
}
