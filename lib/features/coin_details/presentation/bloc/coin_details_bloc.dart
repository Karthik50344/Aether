import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../shared/domain/entities/candlestick.dart';
import '../../../../shared/domain/entities/order_book_depth.dart';
import '../../../../shared/domain/entities/recent_trade.dart';
import '../../../../shared/domain/entities/trading_pair.dart';
import '../../../market/domain/usecases/get_trading_pair.dart';
import '../../../watchlist/domain/usecases/watchlist_usecases.dart';
import '../../domain/entities/chart_indicator.dart';
import '../../domain/entities/chart_period.dart';
import '../../domain/usecases/build_chart_series.dart';
import '../../domain/usecases/compute_pair_stats.dart';
import '../../domain/usecases/get_candlesticks.dart';
import '../../domain/usecases/get_daily_candles.dart';
import '../../domain/usecases/get_order_book_depth.dart';
import '../../domain/usecases/get_recent_trades.dart';
import 'coin_details_event.dart';
import 'coin_details_state.dart';

export 'coin_details_event.dart';
export 'coin_details_state.dart';

/// State holder of the pair details screen (one instance per opened pair).
///
/// Loading order: the pair first (page-level), then chart / daily context /
/// trades / depth in parallel, each with its own status. Sequence numbers make
/// sure a slow response for an old period or an old refresh can never
/// overwrite newer data.
class CoinDetailsBloc extends Bloc<CoinDetailsEvent, CoinDetailsState> {
  CoinDetailsBloc({
    required String symbol,
    required GetTradingPair getPair,
    required GetCandlesticks getCandlesticks,
    required GetDailyCandles getDailyCandles,
    required GetRecentTrades getRecentTrades,
    required GetOrderBookDepth getDepth,
    required BuildChartSeries buildSeries,
    required ComputePairStats computeStats,
    required IsInWatchlist isInWatchlist,
    required ToggleWatchlist toggleWatchlist,
    ChartPeriod initialPeriod = ChartPeriod.defaultPeriod,
    this.autoRefreshInterval,
    this.tradesLimit = 20,
    this.depthLimit = 100,
    DateTime Function()? now,
  })  : _getPair = getPair,
        _getCandles = getCandlesticks,
        _getDaily = getDailyCandles,
        _getTrades = getRecentTrades,
        _getDepth = getDepth,
        _buildSeries = buildSeries,
        _computeStats = computeStats,
        _isWatched = isInWatchlist,
        _toggle = toggleWatchlist,
        _now = now ?? DateTime.now,
        super(CoinDetailsState(
          symbol: symbol.trim().toUpperCase(),
          period: initialPeriod,
        )) {
    on<CoinDetailsStarted>(_onStarted);
    on<CoinDetailsRefreshed>(_onRefreshed);
    on<ChartPeriodSelected>(_onPeriod);
    on<ChartIndicatorToggled>(_onIndicator);
    on<WatchlistToggled>(_onWatchlist);
  }

  final GetTradingPair _getPair;
  final GetCandlesticks _getCandles;
  final GetDailyCandles _getDaily;
  final GetRecentTrades _getTrades;
  final GetOrderBookDepth _getDepth;
  final BuildChartSeries _buildSeries;
  final ComputePairStats _computeStats;
  final IsInWatchlist _isWatched;
  final ToggleWatchlist _toggle;
  final DateTime Function() _now;

  final Duration? autoRefreshInterval;
  final int tradesLimit;
  final int depthLimit;

  Timer? _timer;
  int _loadSeq = 0;
  int _chartSeq = 0;
  List<Candlestick> _daily = const <Candlestick>[];

  String get _symbol => state.symbol;

  // --- loading -------------------------------------------------------------

  Future<void> _onStarted(
    CoinDetailsStarted event,
    Emitter<CoinDetailsState> emit,
  ) async {
    emit(state.copyWith(pairStatus: LoadStatus.loading, clearError: true));
    await _loadAll(emit, first: true);
    _startTimer();
  }

  Future<void> _onRefreshed(
    CoinDetailsRefreshed event,
    Emitter<CoinDetailsState> emit,
  ) async {
    if (state.isLoading) return;
    if (state.hasFailed && !state.hasPair) {
      emit(state.copyWith(pairStatus: LoadStatus.loading, clearError: true));
      await _loadAll(emit, first: true);
      return;
    }
    emit(state.copyWith(refreshing: true, refreshFailed: false));
    await _loadAll(emit, first: false);
  }

  Future<void> _loadAll(
    Emitter<CoinDetailsState> emit, {
    required bool first,
  }) async {
    final int seq = ++_loadSeq;
    try {
      final TradingPair pair = await _getPair(_symbol, forceRefresh: !first);
      if (seq != _loadSeq) return;
      emit(state.copyWith(
        pairStatus: LoadStatus.success,
        pair: pair,
        stats: _computeStats(pair, daily: _daily),
        lastUpdated: _now(),
        clearError: true,
      ));
    } on AppException catch (e) {
      if (seq != _loadSeq) return;
      _pairFailure(emit, e.message, first);
      return;
    } catch (_) {
      if (seq != _loadSeq) return;
      _pairFailure(emit, 'Unexpected error while loading $_symbol.', first);
      return;
    }

    // Independent sections; each handles its own failure.
    await Future.wait(<Future<void>>[
      _loadChart(emit, seq: ++_chartSeq, showLoading: first),
      _loadDaily(emit, seq),
      _loadTrades(emit, seq, first),
      _loadDepth(emit, seq, first),
      if (first) _loadWatched(emit),
    ]);
    if (seq == _loadSeq && state.refreshing) {
      emit(state.copyWith(refreshing: false));
    }
  }

  void _pairFailure(Emitter<CoinDetailsState> emit, String message, bool first) {
    if (state.hasPair && !first) {
      emit(state.copyWith(
        refreshing: false,
        refreshFailed: true,
        errorMessage: message,
      ));
    } else {
      emit(state.copyWith(
        pairStatus: LoadStatus.failure,
        refreshing: false,
        errorMessage: message,
      ));
    }
  }

  Future<void> _loadChart(
    Emitter<CoinDetailsState> emit, {
    required int seq,
    required bool showLoading,
  }) async {
    if (showLoading) {
      emit(state.copyWith(chartStatus: LoadStatus.loading, clearSeries: true));
    }
    final ChartPeriod period = state.period;
    try {
      final List<Candlestick> candles = await _getCandles(_symbol, period);
      if (seq != _chartSeq) return; // user picked another period meanwhile
      emit(state.copyWith(
        chartStatus: LoadStatus.success,
        series: _buildSeries(candles),
      ));
    } catch (_) {
      if (seq != _chartSeq) return;
      // keep older series on a failed background refresh
      emit(state.copyWith(
        chartStatus: state.series == null ? LoadStatus.failure : LoadStatus.success,
      ));
    }
  }

  Future<void> _loadDaily(Emitter<CoinDetailsState> emit, int seq) async {
    try {
      final List<Candlestick> daily = await _getDaily(_symbol);
      if (seq != _loadSeq) return;
      _daily = daily;
      final TradingPair? pair = state.pair;
      if (pair == null) return;
      emit(state.copyWith(
        stats: _computeStats(pair, daily: daily),
        orderflow: _computeStats.orderflow(daily),
        clearOrderflow: _computeStats.orderflow(daily) == null,
      ));
    } catch (_) {
      // Optional context (7D comparison, taker flow): the page works without.
    }
  }

  Future<void> _loadTrades(
    Emitter<CoinDetailsState> emit,
    int seq,
    bool first,
  ) async {
    if (first) emit(state.copyWith(tradesStatus: LoadStatus.loading));
    try {
      final List<RecentTrade> trades = await _getTrades(_symbol, limit: tradesLimit);
      if (seq != _loadSeq) return;
      emit(state.copyWith(
        tradesStatus: LoadStatus.success,
        trades: trades.reversed.toList(growable: false),
      ));
    } catch (_) {
      if (seq != _loadSeq) return;
      emit(state.copyWith(
        tradesStatus: state.trades.isEmpty ? LoadStatus.failure : LoadStatus.success,
      ));
    }
  }

  Future<void> _loadDepth(
    Emitter<CoinDetailsState> emit,
    int seq,
    bool first,
  ) async {
    if (first) emit(state.copyWith(depthStatus: LoadStatus.loading));
    try {
      final OrderBookDepth depth = await _getDepth(_symbol, limit: depthLimit);
      if (seq != _loadSeq) return;
      emit(state.copyWith(depthStatus: LoadStatus.success, depth: depth));
    } catch (_) {
      if (seq != _loadSeq) return;
      emit(state.copyWith(
        depthStatus: state.depth == null ? LoadStatus.failure : LoadStatus.success,
      ));
    }
  }

  Future<void> _loadWatched(Emitter<CoinDetailsState> emit) async {
    try {
      emit(state.copyWith(isWatched: await _isWatched(_symbol)));
    } catch (_) {
      // storage problem: star stays off
    }
  }

  // --- user actions --------------------------------------------------------

  Future<void> _onPeriod(
    ChartPeriodSelected event,
    Emitter<CoinDetailsState> emit,
  ) async {
    if (event.period == state.period && state.chartStatus != LoadStatus.failure) {
      return;
    }
    emit(state.copyWith(period: event.period));
    await _loadChart(emit, seq: ++_chartSeq, showLoading: true);
  }

  void _onIndicator(
    ChartIndicatorToggled event,
    Emitter<CoinDetailsState> emit,
  ) {
    final Set<ChartIndicator> next = <ChartIndicator>{...state.indicators};
    if (!next.remove(event.indicator)) next.add(event.indicator);
    emit(state.copyWith(indicators: next));
  }

  Future<void> _onWatchlist(
    WatchlistToggled event,
    Emitter<CoinDetailsState> emit,
  ) async {
    try {
      emit(state.copyWith(isWatched: await _toggle(_symbol)));
    } catch (_) {
      // storage failure: leave the star as it was
    }
  }

  // --- auto refresh --------------------------------------------------------

  void _startTimer() {
    _timer?.cancel();
    final Duration? every = autoRefreshInterval;
    if (every == null) return;
    _timer = Timer.periodic(every, (_) {
      if (!isClosed) add(const CoinDetailsRefreshed());
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
