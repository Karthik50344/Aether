import 'dart:async';

import 'package:aether_app/core/errors/app_exception.dart';
import 'package:aether_app/core/storage/key_value_store.dart';
import 'package:aether_app/features/coin_details/domain/entities/chart_indicator.dart';
import 'package:aether_app/features/coin_details/domain/entities/chart_period.dart';
import 'package:aether_app/features/coin_details/domain/usecases/build_chart_series.dart';
import 'package:aether_app/features/coin_details/domain/usecases/compute_pair_stats.dart';
import 'package:aether_app/features/coin_details/domain/usecases/get_candlesticks.dart';
import 'package:aether_app/features/coin_details/domain/usecases/get_daily_candles.dart';
import 'package:aether_app/features/coin_details/domain/usecases/get_order_book_depth.dart';
import 'package:aether_app/features/coin_details/domain/usecases/get_recent_trades.dart';
import 'package:aether_app/features/coin_details/presentation/bloc/coin_details_bloc.dart';
import 'package:aether_app/features/market/domain/repositories/market_repository.dart';
import 'package:aether_app/features/market/domain/usecases/get_trading_pair.dart';
import 'package:aether_app/features/watchlist/data/watchlist_repository_impl.dart';
import 'package:aether_app/features/watchlist/domain/usecases/watchlist_usecases.dart';
import 'package:aether_app/shared/domain/entities/candlestick.dart';
import 'package:aether_app/shared/domain/entities/order_book_depth.dart';
import 'package:aether_app/shared/domain/entities/recent_trade.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fixtures.dart';

class _MockRepo extends Mock implements MarketRepository {}

void main() {
  late _MockRepo repo;
  late InMemoryStore store;
  late CoinDetailsBloc bloc;

  List<Candlestick> candles(int n, {double? takerBase, double? takerQuote}) => [
        for (int i = 0; i < n; i++)
          Candlestick(
            openTime: DateTime.utc(2026, 11, 1, i),
            open: 100,
            high: 102,
            low: 98,
            close: 100.0 + i,
            volume: 10,
            closeTime: DateTime.utc(2026, 11, 1, i, 59),
            quoteAssetVolume: 1000,
            takerBuyBaseVolume: takerBase,
            takerBuyQuoteVolume: takerQuote,
          ),
      ];

  final btc = pair('BTC', 'USDT', last: 67420.5, percent: 3.4, quoteVolume: 9e9);

  CoinDetailsBloc build({String symbol = 'btcusdt'}) {
    final wl = WatchlistRepositoryImpl(store);
    return CoinDetailsBloc(
      symbol: symbol,
      getPair: GetTradingPair(repo),
      getCandlesticks: GetCandlesticks(repo),
      getDailyCandles: GetDailyCandles(repo),
      getRecentTrades: GetRecentTrades(repo),
      getDepth: GetOrderBookDepth(repo),
      buildSeries: const BuildChartSeries(),
      computeStats: const ComputePairStats(),
      isInWatchlist: IsInWatchlist(wl),
      toggleWatchlist: ToggleWatchlist(wl),
      now: () => DateTime.utc(2026, 11, 14, 12),
    );
  }

  void stubCandles(Future<List<Candlestick>> Function(String interval, int limit) f) {
    when(() => repo.getCandlesticks(
          symbol: any(named: 'symbol'),
          interval: any(named: 'interval'),
          limit: any(named: 'limit'),
        ),).thenAnswer((inv) => f(
          inv.namedArguments[#interval] as String,
          inv.namedArguments[#limit] as int,
        ),);
  }

  setUp(() {
    repo = _MockRepo();
    store = InMemoryStore();
    when(() => repo.getTradingPair(any(), forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => btc);
    stubCandles((interval, limit) async => interval == '1d'
        ? candles(8, takerBase: 6, takerQuote: 600)
        : candles(limit),);
    when(() => repo.getRecentTrades(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async => [
              for (int i = 0; i < 3; i++)
                RecentTrade(
                  id: i,
                  price: 100,
                  quantity: 1,
                  quoteQuantity: 100,
                  time: DateTime.utc(2026, 11, 14, 12, 0, i),
                  isBuyerMaker: false,
                ),
            ],);
    when(() => repo.getOrderBookDepth(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async => const OrderBookDepth(
              lastUpdateId: 1,
              bids: [DepthLevel(price: 100, quantity: 6)],
              asks: [DepthLevel(price: 100, quantity: 4)],
            ),);
    bloc = build();
  });

  tearDown(() => bloc.close());

  Future<CoinDetailsState> started() async {
    bloc.add(const CoinDetailsStarted());
    return bloc.stream.firstWhere((s) =>
        s.pairStatus == LoadStatus.success &&
        s.chartStatus == LoadStatus.success &&
        s.tradesStatus == LoadStatus.success &&
        s.depthStatus == LoadStatus.success &&
        s.orderflow != null,);
  }

  test('loads every section; symbol is normalised', () async {
    final s = await started();
    expect(s.symbol, 'BTCUSDT');
    expect(s.pair, btc);
    expect(s.series!.length, ChartPeriod.defaultPeriod.limit);
    expect(s.stats!.baseVolume, btc.volume);
    expect(s.stats!.volumeVs7dAvgPercent, isNotNull);
    expect(s.orderflow!.takerBuyShare, closeTo(0.6, 1e-9));
    expect(s.trades.first.id, 2); // newest first
    expect(s.depth!.bidShare, closeTo(0.6, 1e-9));
    expect(s.isWatched, isFalse);
    verify(() => repo.getCandlesticks(
        symbol: 'BTCUSDT', interval: '15m', limit: 96,),).called(1);
  });

  test('indicators: MA(7) on by default; toggles add and remove', () async {
    await started();
    expect(bloc.state.showsIndicator(ChartIndicator.ma7), isTrue);
    bloc.add(const ChartIndicatorToggled(ChartIndicator.volume));
    await bloc.stream.firstWhere((s) => s.showsIndicator(ChartIndicator.volume));
    bloc.add(const ChartIndicatorToggled(ChartIndicator.ma7));
    await bloc.stream.firstWhere((s) => !s.showsIndicator(ChartIndicator.ma7));
    expect(bloc.state.indicators, {ChartIndicator.volume});
  });

  test('period change reloads the chart with that period request', () async {
    await started();
    bloc.add(const ChartPeriodSelected(ChartPeriod.week1));
    final s = await bloc.stream.firstWhere(
        (s) => s.period == ChartPeriod.week1 && s.series?.length == 168,);
    expect(s.chartStatus, LoadStatus.success);
    verify(() => repo.getCandlesticks(
        symbol: 'BTCUSDT', interval: '1h', limit: 168,),).called(1);
  });

  test('stale chart guard: a slow older period cannot overwrite a newer one',
      () async {
    final slow = Completer<List<Candlestick>>();
    stubCandles((interval, limit) {
      if (interval == '15m') return slow.future; // default 1D, never fast
      if (interval == '1d') return Future.value(candles(8));
      return Future.value(candles(5)); // 1W
    });
    bloc.add(const CoinDetailsStarted());
    await bloc.stream.firstWhere((s) => s.pairStatus == LoadStatus.success);

    bloc.add(const ChartPeriodSelected(ChartPeriod.week1));
    await bloc.stream.firstWhere((s) => s.series?.length == 5);

    slow.complete(candles(30)); // arrives late
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state.period, ChartPeriod.week1);
    expect(bloc.state.series!.length, 5);
  });

  test('watchlist toggle persists and starts from stored state', () async {
    await WatchlistRepositoryImpl(store).toggle('BTCUSDT');
    bloc = build();
    bloc.add(const CoinDetailsStarted());
    await bloc.stream.firstWhere((s) => s.isWatched);

    bloc.add(const WatchlistToggled());
    await bloc.stream.firstWhere((s) => !s.isWatched);
    expect(await WatchlistRepositoryImpl(store).contains('BTCUSDT'), isFalse);
  });

  test('unknown pair -> page-level failure; refresh recovers', () async {
    when(() => repo.getTradingPair(any(), forceRefresh: any(named: 'forceRefresh')))
        .thenThrow(const NotFoundException('Trading pair BTCUSDT was not found.'));
    bloc.add(const CoinDetailsStarted());
    final failed =
        await bloc.stream.firstWhere((s) => s.pairStatus == LoadStatus.failure);
    expect(failed.errorMessage, contains('not found'));
    expect(failed.hasPair, isFalse);

    when(() => repo.getTradingPair(any(), forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => btc);
    bloc.add(const CoinDetailsRefreshed());
    await bloc.stream.firstWhere((s) => s.pairStatus == LoadStatus.success);
    expect(bloc.state.hasPair, isTrue);
  });

  test('a failing section does not fail the page', () async {
    when(() => repo.getRecentTrades(any(), limit: any(named: 'limit')))
        .thenThrow(const NetworkUnavailableException());
    when(() => repo.getOrderBookDepth(any(), limit: any(named: 'limit')))
        .thenThrow(const RequestTimeoutException());
    bloc.add(const CoinDetailsStarted());
    final s = await bloc.stream.firstWhere((s) =>
        s.tradesStatus == LoadStatus.failure &&
        s.depthStatus == LoadStatus.failure,);
    expect(s.pairStatus, LoadStatus.success);
    expect(s.hasPair, isTrue);
  });

  test('daily-candle failure only hides the optional figures', () async {
    stubCandles((interval, limit) async {
      if (interval == '1d') throw const NetworkUnavailableException();
      return candles(limit);
    });
    final s = await (() async {
      bloc.add(const CoinDetailsStarted());
      return bloc.stream.firstWhere((s) =>
          s.chartStatus == LoadStatus.success &&
          s.depthStatus == LoadStatus.success &&
          s.tradesStatus == LoadStatus.success,);
    })();
    expect(s.orderflow, isNull);
    expect(s.stats!.volumeVs7dAvgPercent, isNull);
    expect(s.stats, isNotNull);
  });

  test('failed refresh keeps old data and flags it', () async {
    await started();
    when(() => repo.getTradingPair(any(), forceRefresh: any(named: 'forceRefresh')))
        .thenThrow(const RequestTimeoutException());
    bloc.add(const CoinDetailsRefreshed());
    final s = await bloc.stream.firstWhere((s) => s.refreshFailed);
    expect(s.pair, btc);
    expect(s.series, isNotNull);
    expect(s.refreshing, isFalse);
  });
}
