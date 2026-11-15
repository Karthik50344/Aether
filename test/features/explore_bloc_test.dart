import 'dart:async';

import 'package:aether_app/core/errors/app_exception.dart';
import 'package:aether_app/features/explore/domain/entities/explore_query.dart';
import 'package:aether_app/features/explore/domain/usecases/compute_market_flow.dart';
import 'package:aether_app/features/explore/domain/usecases/filter_sort_pairs.dart';
import 'package:aether_app/features/explore/presentation/bloc/explore_bloc.dart';
import 'package:aether_app/features/market/domain/repositories/market_repository.dart';
import 'package:aether_app/features/market/domain/usecases/get_sparkline.dart';
import 'package:aether_app/features/market/domain/usecases/get_trading_pairs.dart';
import 'package:aether_app/features/market/domain/usecases/ping_market.dart';
import 'package:aether_app/shared/domain/entities/candlestick.dart';
import 'package:aether_app/shared/domain/entities/trading_pair.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fixtures.dart';

class _MockRepo extends Mock implements MarketRepository {}

void main() {
  late _MockRepo repo;
  late ExploreBloc bloc;

  final pairs = <TradingPair>[
    pair('BTC', 'USDT', last: 67000, percent: 3, quoteVolume: 9e9),
    pair('ETH', 'USDT', last: 3500, percent: -2, quoteVolume: 5e9),
    pair('SOL', 'USDT', last: 150, percent: 8, quoteVolume: 2e9),
    pair('DOGE', 'USDT', last: 0.1, percent: 5, quoteVolume: 5e5),
    pair('ETH', 'BTC', last: 0.05, percent: 1, quoteVolume: 400),
    pair('BNB', 'EUR', last: 500, percent: 0, quoteVolume: 2e6),
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

  ExploreBloc build({
    String? initialQuote = 'USDT',
    Duration debounce = const Duration(milliseconds: 20),
    int concurrency = 4,
  }) =>
      ExploreBloc(
        getTradingPairs: GetTradingPairs(repo),
        getSparkline: GetSparkline(repo),
        pingMarket: PingMarket(repo),
        filterSort: const FilterSortPairs(),
        computeFlow: const ComputeMarketFlow(),
        initialQuote: initialQuote,
        searchDebounce: debounce,
        sparklineConcurrency: concurrency,
        now: () => DateTime.utc(2026, 11, 14, 12),
      );

  setUp(() {
    repo = _MockRepo();
    when(() => repo.getTradingPairs(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => pairs);
    when(() => repo.ping())
        .thenAnswer((_) async => const Duration(milliseconds: 18));
    when(() => repo.getCandlesticks(
          symbol: any(named: 'symbol'),
          interval: any(named: 'interval'),
          limit: any(named: 'limit'),
        ),).thenAnswer((_) async => candles());
    bloc = build();
  });

  tearDown(() => bloc.close());

  Future<void> started() async {
    bloc.add(const ExploreStarted());
    await bloc.stream.firstWhere((s) => s.status == LoadStatus.success);
  }

  test('loads, defaults to USDT, sorts by volume, builds quote tabs', () async {
    await started();
    final s = bloc.state;
    expect(s.results.map((p) => p.symbol),
        ['BTCUSDT', 'ETHUSDT', 'SOLUSDT', 'DOGEUSDT'],);
    expect(s.quoteTabs, ['USDT', 'BTC', 'EUR']);
    expect(s.flow!.quoteAsset, 'USDT');
    expect(s.latency, const Duration(milliseconds: 18));
    expect(s.activeFilterCount, 0);
  });

  test('falls back to All Pairs when the remembered quote does not exist',
      () async {
    bloc = build(initialQuote: 'TRY');
    await started();
    expect(bloc.state.query.quoteAsset, isNull);
    expect(bloc.state.results.length, pairs.length);
  });

  test('quote selection resets the min-volume filter and can show All',
      () async {
    await started();
    bloc.add(const ExploreFiltersApplied(
      move: MoveFilter.none,
      minQuoteVolume: 1e9,
      sortField: SortField.volume,
      ascending: false,
    ),);
    await bloc.stream.firstWhere((s) => s.query.minQuoteVolume == 1e9);
    expect(bloc.state.results.length, 3);
    expect(bloc.state.activeFilterCount, 1);

    bloc.add(const ExploreQuoteSelected('BTC'));
    await bloc.stream.firstWhere((s) => s.query.quoteAsset == 'BTC');
    expect(bloc.state.query.minQuoteVolume, 0);
    expect(bloc.state.results.map((p) => p.symbol), ['ETHBTC']);

    bloc.add(const ExploreQuoteSelected(null));
    await bloc.stream.firstWhere((s) => s.query.quoteAsset == null);
    expect(bloc.state.results.length, pairs.length);
    expect(bloc.state.flow!.totalQuoteVolume, isNull);
  });

  test('move filter, clear chips and reset', () async {
    await started();
    bloc.add(const ExploreFiltersApplied(
      move: MoveFilter.gainers,
      minQuoteVolume: 0,
      sortField: SortField.change,
      ascending: false,
    ),);
    await bloc.stream.firstWhere((s) => s.query.move == MoveFilter.gainers);
    expect(bloc.state.results.map((p) => p.symbol),
        ['SOLUSDT', 'DOGEUSDT', 'BTCUSDT'],);
    expect(bloc.state.activeFilterCount, 2); // move + custom sort

    bloc.add(const ExploreMoveCleared());
    await bloc.stream.firstWhere((s) => s.query.move == MoveFilter.none);
    expect(bloc.state.results.length, 4);

    bloc.add(const ExploreFiltersReset());
    await bloc.stream.firstWhere((s) => s.query.sortField == null);
    expect(bloc.state.activeFilterCount, 0);
  });

  test('table header sort toggles direction on the active field', () async {
    await started();
    bloc.add(const ExploreSortToggled(SortField.volume));
    await bloc.stream.firstWhere((s) => s.query.ascending);
    expect(bloc.state.results.first.symbol, 'DOGEUSDT');

    bloc.add(const ExploreSortToggled(SortField.price));
    await bloc.stream.firstWhere((s) => s.query.sortField == SortField.price);
    expect(bloc.state.query.ascending, isFalse);
    expect(bloc.state.results.first.symbol, 'BTCUSDT');
  });

  test('search is debounced: only the final text is applied', () async {
    await started();
    final seen = <String>[];
    final sub = bloc.stream.listen((s) => seen.add(s.query.search));
    bloc.add(const ExploreSearchChanged('b'));
    bloc.add(const ExploreSearchChanged('bt'));
    bloc.add(const ExploreSearchChanged('btc'));
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await sub.cancel();
    expect(seen, ['btc']);
    expect(bloc.state.results.map((p) => p.symbol), ['BTCUSDT']);
  });

  test('show more pages through a long result list', () async {
    final many = [
      for (int i = 0; i < 120; i++)
        pair('C$i', 'USDT', quoteVolume: 1e9 - i * 1e6),
    ];
    when(() => repo.getTradingPairs(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => many);
    await started();
    expect(bloc.state.visible.length, ExploreState.pageSize);
    expect(bloc.state.remaining, 70);

    bloc.add(const ExploreShowMore());
    await bloc.stream.firstWhere((s) => s.visibleCount > ExploreState.pageSize);
    expect(bloc.state.visible.length, 100);

    // a new query goes back to the first page
    bloc.add(const ExploreSortToggled(SortField.volume));
    await bloc.stream.firstWhere((s) => s.query.ascending);
    expect(bloc.state.visibleCount, ExploreState.pageSize);
  });

  test('stale-response guard: a slow older load cannot overwrite a newer one',
      () async {
    final slow = Completer<List<TradingPair>>();
    final fast = Completer<List<TradingPair>>();
    final queue = [slow, fast];
    when(() => repo.getTradingPairs(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) => queue.removeAt(0).future);

    bloc.add(const ExploreStarted()); // takes `slow`
    await Future<void>.delayed(Duration.zero);
    bloc.add(const ExploreRetryRequested()); // takes `fast`
    await Future<void>.delayed(Duration.zero);

    final newer = [pair('NEW', 'USDT')];
    fast.complete(newer);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    slow.complete(pairs); // arrives late
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(bloc.state.allPairs, newer);
  });

  test('sparklines are fetched lazily, once per symbol, with a concurrency cap',
      () async {
    await started();
    int active = 0;
    int peak = 0;
    final gates = <Completer<void>>[];
    when(() => repo.getCandlesticks(
          symbol: any(named: 'symbol'),
          interval: any(named: 'interval'),
          limit: any(named: 'limit'),
        ),).thenAnswer((_) async {
      active++;
      if (active > peak) peak = active;
      final gate = Completer<void>();
      gates.add(gate);
      await gate.future;
      active--;
      return candles();
    });
    await bloc.close();
    bloc = build(concurrency: 2);
    await started();

    for (final s in ['A', 'B', 'C', 'D', 'A']) {
      bloc.add(ExploreSparklineRequested(s));
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(peak, 2);
    expect(gates.length, 2);

    while (bloc.state.sparklines.length < 4) {
      for (final g in gates.where((g) => !g.isCompleted)) {
        g.complete();
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(gates.length, 4); // 'A' requested twice but fetched once
    expect(bloc.state.sparklines.keys.toSet(), {'A', 'B', 'C', 'D'});
    expect(peak, 2);
  });

  test('a failing sparkline becomes an empty series, not an error', () async {
    when(() => repo.getCandlesticks(
          symbol: any(named: 'symbol'),
          interval: any(named: 'interval'),
          limit: any(named: 'limit'),
        ),).thenThrow(const NetworkUnavailableException());
    await started();
    bloc.add(const ExploreSparklineRequested('BTCUSDT'));
    final s = await bloc.stream.firstWhere((s) => s.sparklines.isNotEmpty);
    expect(s.sparklines['BTCUSDT'], isEmpty);
    expect(s.status, LoadStatus.success);
  });

  test('first-load failure then retry; refresh failure keeps old data',
      () async {
    when(() => repo.getTradingPairs(forceRefresh: any(named: 'forceRefresh')))
        .thenThrow(const NetworkUnavailableException());
    bloc.add(const ExploreStarted());
    await bloc.stream.firstWhere((s) => s.status == LoadStatus.failure);

    when(() => repo.getTradingPairs(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => pairs);
    bloc.add(const ExploreRetryRequested());
    await bloc.stream.firstWhere((s) => s.status == LoadStatus.success);

    when(() => repo.getTradingPairs(forceRefresh: any(named: 'forceRefresh')))
        .thenThrow(const RequestTimeoutException());
    bloc.add(const ExploreRefreshed());
    final s = await bloc.stream.firstWhere((s) => s.refreshFailed);
    expect(s.allPairs, pairs);
    expect(s.status, LoadStatus.success);
  });
}
