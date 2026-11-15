import '../../../../core/constants/asset_names.dart';
import '../../../../shared/domain/entities/trading_pair.dart';
import '../entities/explore_query.dart';

/// Pure search + filter + sort over loaded pairs.
class FilterSortPairs {
  const FilterSortPairs();

  List<TradingPair> call(List<TradingPair> pairs, ExploreQuery q) {
    final String needle = _normalize(q.search);
    final List<TradingPair> out = <TradingPair>[
      for (final TradingPair p in pairs)
        if (_matches(p, q, needle)) p,
    ];
    final SortField field = q.sortField ?? SortField.volume;
    out.sort((TradingPair a, TradingPair b) {
      final int c = field.compare(a, b);
      final int signed = q.ascending ? c : -c;
      return signed != 0 ? signed : a.symbol.compareTo(b.symbol);
    });
    return out;
  }

  static bool _matches(TradingPair p, ExploreQuery q, String needle) {
    if (q.quoteAsset != null && p.quoteAsset != q.quoteAsset) return false;
    if (p.quoteVolume < q.minQuoteVolume) return false;
    if (q.move == MoveFilter.gainers && p.priceChangePercent <= 0) return false;
    if (q.move == MoveFilter.losers && p.priceChangePercent >= 0) return false;
    if (needle.isEmpty) return true;
    return p.symbol.toLowerCase().contains(needle) ||
        p.baseAsset.toLowerCase().contains(needle) ||
        AssetNames.nameOf(p.baseAsset).toLowerCase().replaceAll(' ', '').contains(needle);
  }

  /// "BTC/USDT", " btc-usdt " and "btcusdt" all search the same way.
  static String _normalize(String raw) =>
      raw.trim().toLowerCase().replaceAll(RegExp(r'[\s/_\-]'), '');
}
