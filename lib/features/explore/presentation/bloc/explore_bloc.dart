import 'dart:async';
import 'dart:collection';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../shared/domain/entities/trading_pair.dart';
import '../../../market/domain/usecases/get_sparkline.dart';
import '../../../market/domain/usecases/get_trading_pairs.dart';
import '../../../market/domain/usecases/ping_market.dart';
import '../../domain/entities/explore_query.dart';
import '../../domain/usecases/compute_market_flow.dart';
import '../../domain/usecases/filter_sort_pairs.dart';
import 'explore_event.dart';
import 'explore_state.dart';

export 'explore_event.dart';
export 'explore_state.dart';

/// State holder of the Explore screen. Talks only to use cases.
///
/// Concurrency rules:
///  * search keystrokes are debounced ([searchDebounce]);
///  * every network load gets a sequence number, and a response is ignored if
///    a newer load started meanwhile (stale-response guard);
///  * sparklines are requested lazily by visible rows and fetched with a small
///    concurrency limit so scrolling never floods the API.
class ExploreBloc extends Bloc<ExploreEvent, ExploreState> {
  ExploreBloc({
    required GetTradingPairs getTradingPairs,
    required GetSparkline getSparkline,
    required PingMarket pingMarket,
    required FilterSortPairs filterSort,
    required ComputeMarketFlow computeFlow,
    String? initialQuote = 'USDT',
    this.searchDebounce = const Duration(milliseconds: 300),
    this.autoRefreshInterval,
    this.sparklineConcurrency = 4,
    DateTime Function()? now,
  })  : _getPairs = getTradingPairs,
        _getSparkline = getSparkline,
        _ping = pingMarket,
        _filterSort = filterSort,
        _flow = computeFlow,
        _now = now ?? DateTime.now,
        super(ExploreState(query: ExploreQuery(quoteAsset: initialQuote))) {
    on<ExploreStarted>(_onStarted);
    on<ExploreRetryRequested>(_onStarted);
    on<ExploreRefreshed>(_onRefreshed);
    on<ExploreSearchChanged>(_onSearchChanged);
    on<ExploreSearchApplied>(_onSearchApplied);
    on<ExploreQuoteSelected>(_onQuote);
    on<ExploreFiltersApplied>(_onFiltersApplied);
    on<ExploreSortToggled>(_onSortToggled);
    on<ExploreFiltersReset>(_onFiltersReset);
    on<ExploreMoveCleared>(_onMoveCleared);
    on<ExploreMinVolumeCleared>(_onMinVolumeCleared);
    on<ExploreShowMore>(_onShowMore);
    on<ExploreSparklineRequested>(_onSparklineRequested);
    on<ExploreSparklinesArrived>(_onSparklinesArrived);
  }

  final GetTradingPairs _getPairs;
  final GetSparkline _getSparkline;
  final PingMarket _ping;
  final FilterSortPairs _filterSort;
  final ComputeMarketFlow _flow;
  final DateTime Function() _now;

  final Duration searchDebounce;
  final Duration? autoRefreshInterval;
  final int sparklineConcurrency;

  Timer? _debounce;
  Timer? _refreshTimer;
  int _loadSeq = 0;

  final Queue<String> _queue = Queue<String>();
  final Set<String> _requested = <String>{};
  int _active = 0;

  // --- loading -------------------------------------------------------------

  Future<void> _onStarted(ExploreEvent event, Emitter<ExploreState> emit) async {
    emit(state.copyWith(status: LoadStatus.loading, clearError: true));
    await _load(emit, forceRefresh: false, firstLoad: true);
    _startTimer();
  }

  Future<void> _onRefreshed(
    ExploreRefreshed event,
    Emitter<ExploreState> emit,
  ) async {
    if (state.isLoading) return;
    emit(state.copyWith(refreshing: true, refreshFailed: false));
    await _load(emit, forceRefresh: true, firstLoad: false);
  }

  Future<void> _load(
    Emitter<ExploreState> emit, {
    required bool forceRefresh,
    required bool firstLoad,
  }) async {
    final int seq = ++_loadSeq;
    try {
      final (List<TradingPair> pairs, Duration? latency) = await (
        _getPairs(forceRefresh: forceRefresh),
        _safePing(),
      ).wait;
      if (seq != _loadSeq) return; // a newer load superseded this one

      final Map<String, int> counts = <String, int>{};
      for (final TradingPair p in pairs) {
        counts[p.quoteAsset] = (counts[p.quoteAsset] ?? 0) + 1;
      }
      // The remembered quote may not exist (any more): fall back to All.
      final String? q = state.query.quoteAsset;
      final ExploreQuery query = (q != null && !counts.containsKey(q))
          ? state.query.copyWith(clearQuote: true, minQuoteVolume: 0)
          : state.query;

      emit(_derive(state.copyWith(
        status: LoadStatus.success,
        allPairs: pairs,
        query: query,
        quoteCounts: counts,
        latency: latency,
        lastUpdated: _now(),
        refreshing: false,
        refreshFailed: false,
        clearError: true,
      ),),);
    } on AppException catch (e) {
      if (seq != _loadSeq) return;
      _emitFailure(emit, e.message, firstLoad);
    } catch (_) {
      if (seq != _loadSeq) return;
      _emitFailure(emit, 'Unexpected error while loading pairs.', firstLoad);
    }
  }

  void _emitFailure(Emitter<ExploreState> emit, String message, bool firstLoad) {
    if (state.hasData && !firstLoad) {
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
      return null;
    }
  }

  // --- search & filters ------------------------------------------------------

  void _onSearchChanged(ExploreSearchChanged e, Emitter<ExploreState> emit) {
    _debounce?.cancel();
    if (e.text.trim() == state.query.search.trim()) return;
    _debounce = Timer(searchDebounce, () {
      if (!isClosed) add(ExploreSearchApplied(e.text));
    });
  }

  void _onSearchApplied(ExploreSearchApplied e, Emitter<ExploreState> emit) {
    _applyQuery(emit, state.query.copyWith(search: e.text.trim()));
  }

  void _onQuote(ExploreQuoteSelected e, Emitter<ExploreState> emit) {
    if (e.quote == state.query.quoteAsset) return;
    // Volume thresholds are in quote units, so they reset with the quote.
    _applyQuery(
      emit,
      state.query.copyWith(
        quoteAsset: e.quote,
        clearQuote: e.quote == null,
        minQuoteVolume: 0,
      ),
    );
  }

  void _onFiltersApplied(ExploreFiltersApplied e, Emitter<ExploreState> emit) {
    _applyQuery(
      emit,
      state.query.copyWith(
        move: e.move,
        minQuoteVolume: state.query.quoteAsset == null ? 0 : e.minQuoteVolume,
        sortField: e.sortField,
        ascending: e.ascending,
      ),
    );
  }

  void _onSortToggled(ExploreSortToggled e, Emitter<ExploreState> emit) {
    final bool same = e.field == state.effectiveSort;
    _applyQuery(
      emit,
      state.query.copyWith(
        sortField: e.field,
        ascending: same ? !state.query.ascending : e.field == SortField.name,
      ),
    );
  }

  void _onFiltersReset(ExploreFiltersReset e, Emitter<ExploreState> emit) {
    _applyQuery(
      emit,
      ExploreQuery(
        search: state.query.search,
        quoteAsset: state.query.quoteAsset,
      ),
    );
  }

  void _onMoveCleared(ExploreMoveCleared e, Emitter<ExploreState> emit) {
    _applyQuery(emit, state.query.copyWith(move: MoveFilter.none));
  }

  void _onMinVolumeCleared(
    ExploreMinVolumeCleared e,
    Emitter<ExploreState> emit,
  ) {
    _applyQuery(emit, state.query.copyWith(minQuoteVolume: 0));
  }

  void _applyQuery(Emitter<ExploreState> emit, ExploreQuery query) {
    if (query == state.query) return;
    emit(_derive(state.copyWith(
      query: query,
      visibleCount: ExploreState.pageSize,
    ),),);
  }

  void _onShowMore(ExploreShowMore e, Emitter<ExploreState> emit) {
    emit(state.copyWith(
      visibleCount: state.visibleCount + ExploreState.pageSize,
    ),);
  }

  ExploreState _derive(ExploreState s) {
    final String? quote = s.query.quoteAsset;
    final List<TradingPair> inQuote = quote == null
        ? s.allPairs
        : <TradingPair>[
            for (final TradingPair p in s.allPairs)
              if (p.quoteAsset == quote) p,
          ];
    return s.copyWith(
      results: _filterSort(s.allPairs, s.query),
      flow: _flow(inQuote, quoteAsset: quote),
    );
  }

  // --- sparklines -------------------------------------------------------------

  void _onSparklineRequested(
    ExploreSparklineRequested e,
    Emitter<ExploreState> emit,
  ) {
    if (state.sparklines.containsKey(e.symbol) || !_requested.add(e.symbol)) {
      return;
    }
    _queue.add(e.symbol);
    _pump();
  }

  void _pump() {
    while (_active < sparklineConcurrency && _queue.isNotEmpty) {
      final String symbol = _queue.removeFirst();
      _active++;
      unawaited(_fetchOne(symbol));
    }
  }

  Future<void> _fetchOne(String symbol) async {
    List<double> values;
    try {
      values = await _getSparkline(symbol);
    } catch (_) {
      values = const <double>[]; // row shows a dashed placeholder
    }
    _active--;
    if (isClosed) return;
    add(ExploreSparklinesArrived(<String, List<double>>{symbol: values}));
    _pump();
  }

  void _onSparklinesArrived(
    ExploreSparklinesArrived e,
    Emitter<ExploreState> emit,
  ) {
    emit(state.copyWith(sparklines: <String, List<double>>{
      ...state.sparklines,
      ...e.series,
    },),);
  }

  // --- auto refresh -------------------------------------------------------------

  void _startTimer() {
    _refreshTimer?.cancel();
    final Duration? every = autoRefreshInterval;
    if (every == null) return;
    _refreshTimer = Timer.periodic(every, (_) {
      if (!isClosed) add(const ExploreRefreshed());
    });
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    _refreshTimer?.cancel();
    return super.close();
  }
}
