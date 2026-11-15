import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/state/load_status.dart';
import '../../../../shared/domain/entities/trading_pair.dart';
import '../../../market/domain/usecases/get_trading_pairs.dart';
import '../../domain/entities/watchlist_summary.dart';
import '../../domain/usecases/watchlist_usecases.dart';
import 'watchlist_event.dart';
import 'watchlist_state.dart';

export 'watchlist_event.dart';
export 'watchlist_state.dart';

class WatchlistBloc extends Bloc<WatchlistEvent, WatchlistState> {
  WatchlistBloc({
    required GetWatchlist getWatchlist,
    required AddToWatchlist addToWatchlist,
    required RemoveFromWatchlist removeFromWatchlist,
    required ReorderWatchlist reorderWatchlist,
    required GetTradingPairs getTradingPairs,
    required ComputeWatchlistSummary computeSummary,
    DateTime Function()? now,
    this.autoRefreshInterval,
  })  : _get = getWatchlist,
        _add = addToWatchlist,
        _remove = removeFromWatchlist,
        _reorder = reorderWatchlist,
        _getPairs = getTradingPairs,
        _summary = computeSummary,
        _now = now ?? DateTime.now,
        super(const WatchlistState()) {
    on<WatchlistStarted>(_onStarted);
    on<WatchlistRefreshed>(_onRefreshed);
    on<WatchlistEditToggled>(
        (e, emit) => emit(state.copyWith(editing: !state.editing)),);
    on<WatchlistPairRemoved>(_onRemoved);
    on<WatchlistPairAdded>(_onAdded);
    on<WatchlistReordered>(_onReordered);
  }

  final GetWatchlist _get;
  final AddToWatchlist _add;
  final RemoveFromWatchlist _remove;
  final ReorderWatchlist _reorder;
  final GetTradingPairs _getPairs;
  final ComputeWatchlistSummary _summary;
  final DateTime Function() _now;
  final Duration? autoRefreshInterval;
  Timer? _timer;

  WatchlistState _withSymbols(WatchlistState s, List<String> symbols) {
    final List<TradingPair> saved = <TradingPair>[
      for (final String sym in symbols)
        if (s.pairsBySymbol[sym] case final TradingPair p) p,
    ];
    return s.copyWith(symbols: symbols, summary: _summary(saved));
  }

  Future<void> _onStarted(
      WatchlistStarted e, Emitter<WatchlistState> emit,) async {
    emit(state.copyWith(status: LoadStatus.loading, clearError: true));
    await _load(emit, force: false);
    final Duration? every = autoRefreshInterval;
    if (every != null) {
      _timer?.cancel();
      _timer = Timer.periodic(every, (_) {
        if (!isClosed) add(const WatchlistRefreshed());
      });
    }
  }

  Future<void> _onRefreshed(
      WatchlistRefreshed e, Emitter<WatchlistState> emit,) async {
    if (state.status == LoadStatus.loading) return;
    if (e.force && state.status == LoadStatus.failure) {
      emit(state.copyWith(status: LoadStatus.loading, clearError: true));
    }
    await _load(emit, force: e.force);
  }

  Future<void> _load(Emitter<WatchlistState> emit, {required bool force}) async {
    try {
      final List<String> symbols = await _get();
      final List<TradingPair> all = await _getPairs(forceRefresh: force);
      final Map<String, TradingPair> by = <String, TradingPair>{
        for (final TradingPair p in all) p.symbol: p,
      };
      emit(_withSymbols(
        state.copyWith(
          status: LoadStatus.success,
          pairsBySymbol: by,
          allPairs: all,
          refreshFailed: false,
          clearError: true,
          updatedAt: _now(),
        ),
        symbols,
      ),);
    } catch (err) {
      final String msg = err is AppException ? err.message : 'Something went wrong.';
      if (state.status == LoadStatus.success) {
        emit(state.copyWith(refreshFailed: true, errorMessage: msg));
      } else {
        emit(state.copyWith(status: LoadStatus.failure, errorMessage: msg));
      }
    }
  }

  Future<void> _onRemoved(
      WatchlistPairRemoved e, Emitter<WatchlistState> emit,) async {
    final List<String> next =
        state.symbols.where((String s) => s != e.symbol).toList();
    emit(_withSymbols(state, next));
    await _remove(e.symbol);
  }

  Future<void> _onAdded(
      WatchlistPairAdded e, Emitter<WatchlistState> emit,) async {
    if (state.symbols.contains(e.symbol)) return;
    emit(_withSymbols(state, <String>[e.symbol, ...state.symbols]));
    await _add(e.symbol);
  }

  Future<void> _onReordered(
      WatchlistReordered e, Emitter<WatchlistState> emit,) async {
    final List<String> next = List<String>.of(state.symbols);
    if (e.oldIndex < 0 || e.oldIndex >= next.length) return;
    int to = e.newIndex;
    if (to > e.oldIndex) to -= 1;
    if (to < 0 || to >= next.length || to == e.oldIndex) return;
    next.insert(to, next.removeAt(e.oldIndex));
    emit(_withSymbols(state, next));
    await _reorder(e.oldIndex, e.newIndex);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
