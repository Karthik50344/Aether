import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/sectors.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/domain/entities/trading_pair.dart';
import '../../../explore/domain/entities/explore_query.dart';
import '../../../explore/domain/usecases/filter_sort_pairs.dart';
import '../../domain/entities/market_overview.dart';
import '../../domain/usecases/compute_market_overview.dart';
import '../../domain/usecases/get_sparkline.dart';
import '../../domain/usecases/get_trading_pairs.dart';
import '../../domain/usecases/ping_market.dart';
import '../../domain/usecases/select_market_movers.dart';
import 'market_event.dart';
import 'market_state.dart';

export 'market_event.dart';
export 'market_state.dart';

/// Dashboard state holder. Talks only to use cases.
class MarketBloc extends Bloc<MarketEvent, MarketState> {
  MarketBloc({
    required GetTradingPairs getTradingPairs,
    required GetSparkline getSparkline,
    required PingMarket pingMarket,
    required ComputeMarketOverview computeOverview,
    required SelectMarketMovers selectMovers,
    required FilterSortPairs filterSort,
    DateTime Function()? now,
    this.autoRefreshInterval,
    this.trendLimit = 6,
  })  : _getPairs = getTradingPairs,
        _getSparkline = getSparkline,
        _ping = pingMarket,
        _overview = computeOverview,
        _movers = selectMovers,
        _filterSort = filterSort,
        _now = now ?? DateTime.now,
        super(const MarketState()) {
    on<MarketStarted>(_onStarted);
    on<MarketRetryRequested>(_onStarted);
    on<MarketRefreshed>(_onRefreshed);
    on<MarketQuoteSelected>(_onQuote);
    on<MarketTrendSelected>(_onTrend);
    on<MarketSectorSelected>(_onSector);
    on<MarketSortChanged>(_onSort);
    on<MarketSparklinesArrived>(_onSparklines);
  }

  final GetTradingPairs _getPairs;
  final GetSparkline _getSparkline;
  final PingMarket _ping;
  final ComputeMarketOverview _overview;
  final SelectMarketMovers _movers;
  final FilterSortPairs _filterSort;
  final DateTime Function() _now;

  /// `null` disables periodic refresh (tests).
  final Duration? autoRefreshInterval;
  final int trendLimit;

  Timer? _timer;
  final Set<String> _sparklineRequested = <String>{};

  // --- loading -------------------------------------------------------------

  Future<void> _onStarted(MarketEvent event, Emitter<MarketState> emit) async {
    emit(state.copyWith(status: LoadStatus.loading, clearError: true));
    await _load(emit, forceRefresh: false, firstLoad: true);
    _startTimer();
  }

  Future<void> _onRefreshed(
    MarketRefreshed event,
    Emitter<MarketState> emit,
  ) async {
    if (state.isLoading) return;
    emit(state.copyWith(refreshing: true, refreshFailed: false));
    await _load(emit, forceRefresh: event.forceNetwork, firstLoad: false);
  }

  Future<void> _load(
    Emitter<MarketState> emit, {
    required bool forceRefresh,
    required bool firstLoad,
  }) async {
    try {
      final (List<TradingPair> pairs, Duration? latency) = await (
        _getPairs(forceRefresh: forceRefresh),
        _safePing(),
      ).wait;

      final List<String> quotes = <String>{
        for (final TradingPair p in pairs) p.quoteAsset,
      }.toList();
      // Keep the selected quote if it exists; otherwise fall back.
      final String quote = quotes.contains(state.quote)
          ? state.quote
          : (_firstAvailable(quotes) ?? state.quote);

      final MarketState next = _derive(state.copyWith(
        status: LoadStatus.success,
        pairs: pairs,
        quote: quote,
        latency: latency,
        lastUpdated: _now(),
        refreshing: false,
        refreshFailed: false,
        clearError: true,
      ),);
      emit(next);
      _requestSparklines(next.trendPairs);
    } on AppException catch (e) {
      _emitFailure(emit, e.message, firstLoad);
    } catch (_) {
      _emitFailure(emit, 'Unexpected error while loading markets.', firstLoad);
    }
  }

  void _emitFailure(Emitter<MarketState> emit, String message, bool firstLoad) {
    if (state.hasData && !firstLoad) {
      // Keep showing the previous data; just flag the stale refresh.
      emit(state.copyWith(
        refreshing: false,
        refreshFailed: true,
        errorMessage: message,
      ),);
    } else {
      emit(state.copyWith(
        status: LoadStatus.failure,
        refreshing: false,
        errorMessage: message,
      ),);
    }
  }

  Future<Duration?> _safePing() async {
    try {
      return await _ping();
    } catch (_) {
      return null; // latency is informational; never fail the screen on it
    }
  }

  static String? _firstAvailable(List<String> quotes) {
    for (final String q in const <String>['USDT', 'FDUSD', 'BTC']) {
      if (quotes.contains(q)) return q;
    }
    return quotes.isEmpty ? null : quotes.first;
  }

  // --- user actions --------------------------------------------------------

  void _onQuote(MarketQuoteSelected e, Emitter<MarketState> emit) {
    if (e.quote == state.quote) return;
    final MarketState next = _derive(state.copyWith(quote: e.quote));
    emit(next);
    _requestSparklines(next.trendPairs);
  }

  void _onTrend(MarketTrendSelected e, Emitter<MarketState> emit) {
    if (e.trend == state.trend) return;
    final MarketState next = _derive(state.copyWith(trend: e.trend));
    emit(next);
    _requestSparklines(next.trendPairs);
  }

  void _onSector(MarketSectorSelected e, Emitter<MarketState> emit) {
    emit(_derive(state.copyWith(sector: Sector.fromId(e.sectorId))));
  }

  void _onSort(MarketSortChanged e, Emitter<MarketState> emit) {
    emit(_derive(state.copyWith(sortField: e.field, ascending: e.ascending)));
  }

  void _onSparklines(
    MarketSparklinesArrived e,
    Emitter<MarketState> emit,
  ) {
    emit(state.copyWith(sparklines: <String, List<double>>{
      ...state.sparklines,
      ...e.series,
    },),);
  }

  // --- derivation (pure; use cases do the work) ------------------------------

  MarketState _derive(MarketState s) {
    final MarketOverview overview = _overview(s.pairs, quoteAsset: s.quote);
    final MarketMovers movers =
        _movers(s.pairs, quoteAsset: s.quote, limit: trendLimit);

    final List<TradingPair> trend;
    if (s.trend == TrendKind.gainers) {
      trend = movers.gainers;
    } else if (s.trend == TrendKind.losers) {
      trend = movers.losers;
    } else {
      trend = movers.topByVolume;
    }

    final List<TradingPair> ofQuote = <TradingPair>[
      for (final TradingPair p in s.pairs)
        if (p.quoteAsset == s.quote) p,
    ];
    final Map<String, int> counts = <String, int>{
      for (final Sector sec in Sector.values)
        sec.id: <TradingPair>[
          for (final TradingPair p in ofQuote)
            if (sec.contains(p.baseAsset)) p,
        ].length,
    };

    final List<TradingPair> inSector = <TradingPair>[
      for (final TradingPair p in ofQuote)
        if (s.sector.contains(p.baseAsset)) p,
    ];
    final List<TradingPair> list = _filterSort(
      inSector,
      ExploreQuery(
        quoteAsset: s.quote,
        sortField: s.sortField,
        ascending: s.ascending,
      ),
    );

    return s.copyWith(
      overview: overview,
      trendPairs: trend,
      listPairs: list,
      sectorCounts: counts,
    );
  }

  // --- sparklines ------------------------------------------------------------

  void _requestSparklines(List<TradingPair> pairs) {
    final List<String> missing = <String>[
      for (final TradingPair p in pairs)
        if (!state.sparklines.containsKey(p.symbol) &&
            _sparklineRequested.add(p.symbol))
          p.symbol,
    ];
    if (missing.isEmpty) return;
    unawaited(_fetchSparklines(missing));
  }

  Future<void> _fetchSparklines(List<String> symbols) async {
    final Map<String, List<double>> out = <String, List<double>>{};
    await Future.wait(<Future<void>>[
      for (final String s in symbols)
        () async {
          try {
            out[s] = await _getSparkline(s);
          } catch (_) {
            out[s] = const <double>[]; // empty -> card shows a flat placeholder
          }
        }(),
    ]);
    if (!isClosed) add(MarketSparklinesArrived(out));
  }

  // --- auto refresh ------------------------------------------------------------

  void _startTimer() {
    _timer?.cancel();
    final Duration? every = autoRefreshInterval;
    if (every == null) return;
    _timer = Timer.periodic(every, (_) {
      if (!isClosed) add(const MarketRefreshed());
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
