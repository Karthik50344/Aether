import '../../../../shared/domain/entities/trading_pair.dart';
import '../entities/market_overview.dart';

/// Pure aggregation over already-loaded pairs (no I/O).
class ComputeMarketOverview {
  const ComputeMarketOverview();

  MarketOverview call(List<TradingPair> pairs, {required String quoteAsset}) {
    double volume = 0;
    int count = 0;
    int up = 0;
    int down = 0;
    int flat = 0;
    for (final TradingPair p in pairs) {
      if (p.quoteAsset != quoteAsset) continue;
      count++;
      volume += p.quoteVolume;
      if (p.priceChangePercent > 0) {
        up++;
      } else if (p.priceChangePercent < 0) {
        down++;
      } else {
        flat++;
      }
    }
    return MarketOverview(
      quoteAsset: quoteAsset,
      totalQuoteVolume: volume,
      quotePairCount: count,
      activePairCount: pairs.length,
      advancing: up,
      declining: down,
      unchanged: flat,
    );
  }
}
