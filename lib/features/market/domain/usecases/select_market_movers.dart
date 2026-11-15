import '../../../../core/constants/quote_assets.dart';
import '../../../../shared/domain/entities/trading_pair.dart';

/// Pairs for one quote asset, split for the dashboard.
class MarketMovers {
  const MarketMovers({
    required this.topByVolume,
    required this.gainers,
    required this.losers,
  });
  final List<TradingPair> topByVolume;
  final List<TradingPair> gainers;
  final List<TradingPair> losers;
}

/// Pure selection. Pairs below the minimum 24h quote volume are ignored for
/// gainers/losers so illiquid pairs do not dominate the lists.
class SelectMarketMovers {
  const SelectMarketMovers();

  MarketMovers call(
    List<TradingPair> pairs, {
    required String quoteAsset,
    int limit = 5,
    double? minQuoteVolume,
  }) {
    final double floor =
        minQuoteVolume ?? QuoteAssets.defaultMinQuoteVolume(quoteAsset);
    final List<TradingPair> ofQuote = <TradingPair>[
      for (final TradingPair p in pairs)
        if (p.quoteAsset == quoteAsset) p,
    ];
    final List<TradingPair> top = <TradingPair>[...ofQuote]
      ..sort((TradingPair a, TradingPair b) =>
          b.quoteVolume.compareTo(a.quoteVolume),);
    final List<TradingPair> liquid = <TradingPair>[
      for (final TradingPair p in ofQuote)
        if (p.quoteVolume >= floor) p,
    ];
    final List<TradingPair> gain = <TradingPair>[
      for (final TradingPair p in liquid)
        if (p.priceChangePercent > 0) p,
    ]..sort((TradingPair a, TradingPair b) =>
        b.priceChangePercent.compareTo(a.priceChangePercent),);
    final List<TradingPair> lose = <TradingPair>[
      for (final TradingPair p in liquid)
        if (p.priceChangePercent < 0) p,
    ]..sort((TradingPair a, TradingPair b) =>
        a.priceChangePercent.compareTo(b.priceChangePercent),);
    List<TradingPair> take(List<TradingPair> l) =>
        l.length > limit ? l.sublist(0, limit) : l;
    return MarketMovers(
      topByVolume: take(top),
      gainers: take(gain),
      losers: take(lose),
    );
  }
}
