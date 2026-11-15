import '../../../../shared/domain/entities/candlestick.dart';
import '../../../../shared/domain/entities/trading_pair.dart';
import '../entities/orderflow.dart';
import '../entities/pair_stats.dart';

/// Pure derivations for the details screen.
class ComputePairStats {
  const ComputePairStats();

  /// [daily] = recent 1d candles, oldest first (the last one is "today").
  PairStats call(TradingPair pair, {List<Candlestick> daily = const <Candlestick>[]}) {
    double? vsAvg;
    if (daily.length >= 2) {
      final List<Candlestick> prior = daily.sublist(0, daily.length - 1);
      final List<Candlestick> window =
          prior.length > 7 ? prior.sublist(prior.length - 7) : prior;
      final double avg = window.fold<double>(0, (double s, Candlestick c) => s + c.volume) /
          window.length;
      if (avg > 0) vsAvg = (pair.volume - avg) / avg * 100;
    }
    return PairStats(
      high: pair.highPrice,
      low: pair.lowPrice,
      baseVolume: pair.volume,
      quoteVolume: pair.quoteVolume,
      priceChange: pair.priceChange,
      priceChangePercent: pair.priceChangePercent,
      lastPrice: pair.lastPrice,
      tradeCount: pair.tradeCount,
      tradesPerSecond:
          pair.tradeCount == null ? null : pair.tradeCount! / Duration.secondsPerDay,
      volumeVs7dAvgPercent: vsAvg,
      vwap: pair.weightedAvgPrice,
      openPrice: pair.openPrice,
    );
  }

  /// `null` when the latest daily candle has no taker fields or no volume.
  Orderflow? orderflow(List<Candlestick> daily) {
    if (daily.isEmpty) return null;
    final Candlestick c = daily.last;
    final double? buyBase = c.takerBuyBaseVolume;
    final double? buyQuote = c.takerBuyQuoteVolume;
    if (buyBase == null || buyQuote == null || c.volume <= 0) return null;
    return Orderflow(
      takerBuyShare: (buyBase / c.volume).clamp(0.0, 1.0),
      netQuoteFlow: 2 * buyQuote - c.quoteAssetVolume,
    );
  }
}
