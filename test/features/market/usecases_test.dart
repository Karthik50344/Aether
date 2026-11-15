import 'package:aether_app/features/explore/domain/entities/explore_query.dart';
import 'package:aether_app/features/explore/domain/usecases/filter_sort_pairs.dart';
import 'package:aether_app/features/explore/domain/usecases/compute_market_flow.dart';
import 'package:aether_app/features/market/domain/usecases/compute_market_overview.dart';
import 'package:aether_app/features/market/domain/usecases/select_market_movers.dart';
import 'package:aether_app/shared/domain/entities/trading_pair.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';

void main() {
  final List<TradingPair> pairs = <TradingPair>[
    pair('BTC', 'USDT', last: 67000, percent: 3, quoteVolume: 9e9),
    pair('ETH', 'USDT', last: 3500, percent: -2, quoteVolume: 5e9),
    pair('SOL', 'USDT', last: 150, percent: 8, quoteVolume: 2e9),
    pair('DOGE', 'USDT', last: 0.1, percent: 0, quoteVolume: 5e5), // illiquid
    pair('ETH', 'BTC', last: 0.05, percent: 1, quoteVolume: 100),
  ];

  test('overview aggregates one quote asset only', () {
    final o = const ComputeMarketOverview()(pairs, quoteAsset: 'USDT');
    expect(o.quotePairCount, 4);
    expect(o.activePairCount, 5);
    expect(o.advancing, 2);
    expect(o.declining, 1);
    expect(o.unchanged, 1);
    expect(o.totalQuoteVolume, 9e9 + 5e9 + 2e9 + 5e5);
  });

  test('movers respect quote asset, volume floor and limit', () {
    final m = const SelectMarketMovers()(pairs, quoteAsset: 'USDT', limit: 2);
    expect(m.topByVolume.map((p) => p.symbol), ['BTCUSDT', 'ETHUSDT']);
    expect(m.gainers.map((p) => p.symbol), ['SOLUSDT', 'BTCUSDT']);
    expect(m.losers.map((p) => p.symbol), ['ETHUSDT']);
  });

  group('FilterSortPairs', () {
    const FilterSortPairs f = FilterSortPairs();

    test('default sort is volume descending', () {
      expect(f(pairs, const ExploreQuery()).first.symbol, 'BTCUSDT');
    });

    test('search matches symbol and base asset, case-insensitively', () {
      expect(f(pairs, const ExploreQuery(search: ' sol ')).length, 1);
      expect(f(pairs, const ExploreQuery(search: 'ethbtc')).length, 1);
      expect(f(pairs, const ExploreQuery(search: 'zzz')), isEmpty);
    });

    test('search ignores separators and also matches asset names', () {
      expect(f(pairs, const ExploreQuery(search: 'BTC/USDT')).length, 1);
      expect(f(pairs, const ExploreQuery(search: 'eth-btc')).length, 1);
      expect(f(pairs, const ExploreQuery(search: 'bitcoin')).length, 1);
    });

    test('quote and move filters', () {
      final r = f(pairs,
          const ExploreQuery(quoteAsset: 'USDT', move: MoveFilter.gainers));
      expect(r.map((p) => p.symbol), ['BTCUSDT', 'SOLUSDT']);
      final l = f(pairs, const ExploreQuery(move: MoveFilter.losers));
      expect(l.map((p) => p.symbol), ['ETHUSDT']);
    });

    test('min volume and ascending price sort', () {
      final r = f(
        pairs,
        ExploreQuery(
          quoteAsset: 'USDT',
          minQuoteVolume: 1e6,
          sortField: SortField.price,
          ascending: true,
        ),
      );
      expect(r.map((p) => p.symbol), ['SOLUSDT', 'ETHUSDT', 'BTCUSDT']);
    });
  });

  group('ComputeMarketFlow', () {
    const compute = ComputeMarketFlow();

    test('breadth, total volume and BTC share for one quote', () {
      final usdt = pairs.where((p) => p.quoteAsset == 'USDT').toList();
      final flow = compute(usdt, quoteAsset: 'USDT');
      expect(flow.advancing, 2);
      expect(flow.declining, 1);
      expect(flow.unchanged, 1);
      expect(flow.advancingShare, closeTo(0.5, 1e-9));
      expect(flow.totalQuoteVolume, 9e9 + 5e9 + 2e9 + 5e5);
      expect(flow.btcShare, closeTo(9e9 / (16e9 + 5e5), 1e-9));
    });

    test('All Pairs has no volume total (mixed units)', () {
      final flow = compute(pairs);
      expect(flow.totalQuoteVolume, isNull);
      expect(flow.btcShare, isNull);
      expect(flow.total, 5);
    });

    test('no BTC share for the BTC quote or empty input', () {
      final btc = pairs.where((p) => p.quoteAsset == 'BTC').toList();
      expect(compute(btc, quoteAsset: 'BTC').btcShare, isNull);
      expect(compute(const [], quoteAsset: 'USDT').advancingShare, 0);
    });
  });
}
