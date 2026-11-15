import 'package:aether_app/core/errors/app_exception.dart';
import 'package:aether_app/core/constants/sectors.dart';
import 'package:aether_app/features/explore/domain/entities/explore_query.dart';
import 'package:aether_app/features/explore/domain/usecases/filter_sort_pairs.dart';
import 'package:aether_app/features/market/domain/repositories/market_repository.dart';
import 'package:aether_app/features/market/domain/usecases/compute_market_overview.dart';
import 'package:aether_app/features/market/domain/usecases/get_sparkline.dart';
import 'package:aether_app/features/market/domain/usecases/get_trading_pairs.dart';
import 'package:aether_app/features/market/domain/usecases/ping_market.dart';
import 'package:aether_app/features/market/domain/usecases/select_market_movers.dart';
import 'package:aether_app/features/market/presentation/bloc/market_bloc.dart';
import 'package:aether_app/shared/domain/entities/candlestick.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fixtures.dart';

class _MockRepo extends Mock implements MarketRepository {}

void main() {
  late _MockRepo repo;
  late MarketBloc bloc;

  final pairs = [
    pair('BTC', 'USDT', last: 67000, percent: 3, quoteVolume: 9e9),
    pair('ETH', 'USDT', last: 3500, percent: -2, quoteVolume: 5e9),
    pair('SOL', 'USDT', last: 150, percent: 8, quoteVolume: 2e9),
    pair('DOGE', 'USDT', last: 0.1, percent: 5, quoteVolume: 3e8),
    pair('ETH', 'BTC', last: 0.05, percent: 1, quoteVolume: 400),
  ];

  List<Candlestick> candles() => [
        for (int i = 0; i < 24; i++)
          Candlestick(
            openTime: DateTime.utc(2026, 11, 14, i),
            open: 1,
            high: 2,
            low: 1,
            close: 1.0 + i,
            volume: 1,
            closeTime: DateTime.utc(2026, 11, 14, i, 59),
            quoteAssetVolume: 1,
          ),
      ];

  MarketBloc build() => MarketBloc(
        getTradingPairs: GetTradingPairs(repo),
        getSparkline: GetSparkline(repo),
        pingMarket: PingMarket(repo),
        computeOverview: const ComputeMarketOverview(),
        selectMovers: const SelectMarketMovers(),
        filterSort: const FilterSortPairs(),
        now: () => DateTime.utc(2026, 11, 14, 12),
      );

  setUp(() {
    repo = _MockRepo();
    when(() => repo.getTradingPairs(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => pairs);
    when(() => repo.ping()).thenAnswer((_) async => const Duration(milliseconds: 24));
    when(() => repo.getCandlesticks(
          symbol: any(named: 'symbol'),
          interval: any(named: 'interval'),
          limit: any(named: 'limit'),
        ),).thenAnswer((_) async => candles());
    bloc = build();
  });

  tearDown(() => bloc.close());

  Future<void> started() async {
    bloc.add(const MarketStarted());
    await bloc.stream.firstWhere((s) => s.status == LoadStatus.success);
  }

  test('initial load derives overview, trends and list for USDT', () async {
    await started();
    final s = bloc.state;
    expect(s.quote, 'USDT');
    expect(s.overview!.quotePairCount, 4);
    expect(s.trendPairs.first.symbol, 'SOLUSDT'); // top gainer
    expect(s.listPairs.first.symbol, 'BTCUSDT'); // volume desc
    expect(s.latency, const Duration(milliseconds: 24));
    expect(s.availableQuotes, ['USDT', 'BTC']);
    expect(s.sectorCounts['all'], 4);
    expect(s.sectorCounts['meme'], 1);
  });

  test('switching quote, trend, sector and sort re-derives lists', () async {
    await started();
    bloc.add(const MarketQuoteSelected('BTC'));
    await bloc.stream.firstWhere((s) => s.quote == 'BTC');
    expect(bloc.state.listPairs.map((p) => p.symbol), ['ETHBTC']);

    bloc.add(const MarketQuoteSelected('USDT'));
    await bloc.stream.firstWhere((s) => s.quote == 'USDT');
    bloc.add(const MarketTrendSelected(TrendKind.losers));
    await bloc.stream.firstWhere((s) => s.trend == TrendKind.losers);
    expect(bloc.state.trendPairs.map((p) => p.symbol), ['ETHUSDT']);

    bloc.add(MarketSectorSelected(Sector.meme.id));
    await bloc.stream.firstWhere((s) => s.sector == Sector.meme);
    expect(bloc.state.listPairs.map((p) => p.symbol), ['DOGEUSDT']);

    bloc.add(const MarketSectorSelected('all'));
    await bloc.stream.firstWhere((s) => s.sector == Sector.all);
    bloc.add(const MarketSortChanged(SortField.price, ascending: true));
    await bloc.stream.firstWhere((s) => s.sortField == SortField.price);
    expect(bloc.state.listPairs.first.symbol, 'DOGEUSDT');
  });

  test('sparklines arrive after the first load', () async {
    await started();
    final s = bloc.state.sparklines.isNotEmpty
        ? bloc.state
        : await bloc.stream.firstWhere((s) => s.sparklines.isNotEmpty);
    expect(s.sparklines['SOLUSDT']!.length, 24);
  });

  test('first-load failure produces a failure state; retry recovers', () async {
    when(() => repo.getTradingPairs(forceRefresh: any(named: 'forceRefresh')))
        .thenThrow(const NetworkUnavailableException());
    bloc.add(const MarketStarted());
    final failed =
        await bloc.stream.firstWhere((s) => s.status == LoadStatus.failure);
    expect(failed.errorMessage, isNotEmpty);
    expect(failed.hasData, isFalse);

    when(() => repo.getTradingPairs(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => pairs);
    bloc.add(const MarketRetryRequested());
    await bloc.stream.firstWhere((s) => s.status == LoadStatus.success);
    expect(bloc.state.hasData, isTrue);
  });

  test('a failed refresh keeps the old data and flags it stale', () async {
    await started();
    when(() => repo.getTradingPairs(forceRefresh: any(named: 'forceRefresh')))
        .thenThrow(const RequestTimeoutException());
    bloc.add(const MarketRefreshed());
    final s = await bloc.stream.firstWhere((s) => s.refreshFailed);
    expect(s.status, LoadStatus.success);
    expect(s.pairs, pairs);
    expect(s.refreshing, isFalse);
  });

  test('ping failure does not fail the screen', () async {
    when(() => repo.ping()).thenThrow(const NetworkUnavailableException());
    await started();
    expect(bloc.state.latency, isNull);
    expect(bloc.state.hasData, isTrue);
  });
}
