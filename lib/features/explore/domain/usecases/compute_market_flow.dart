import '../../../../shared/domain/entities/trading_pair.dart';
import '../entities/market_flow.dart';

/// Pure aggregation over the pairs the user is looking at.
class ComputeMarketFlow {
  const ComputeMarketFlow();

  /// [pairs] should already be restricted to [quoteAsset] when it is not null.
  MarketFlow call(List<TradingPair> pairs, {String? quoteAsset}) {
    int up = 0;
    int down = 0;
    int flat = 0;
    double volume = 0;
    double btcVolume = 0;
    bool hasBtc = false;
    for (final TradingPair p in pairs) {
      if (p.priceChangePercent > 0) {
        up++;
      } else if (p.priceChangePercent < 0) {
        down++;
      } else {
        flat++;
      }
      if (quoteAsset != null && p.quoteAsset == quoteAsset) {
        volume += p.quoteVolume;
        if (p.baseAsset == 'BTC') {
          hasBtc = true;
          btcVolume = p.quoteVolume;
        }
      }
    }
    return MarketFlow(
      quoteAsset: quoteAsset,
      advancing: up,
      declining: down,
      unchanged: flat,
      totalQuoteVolume: quoteAsset == null ? null : volume,
      btcShare: (quoteAsset == null ||
              quoteAsset == 'BTC' ||
              !hasBtc ||
              volume <= 0)
          ? null
          : btcVolume / volume,
    );
  }
}
