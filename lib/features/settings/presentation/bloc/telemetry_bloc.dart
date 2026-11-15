import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/state/load_status.dart';
import '../../../../shared/ui/data_reset_signal.dart';
import '../../../market/domain/usecases/clear_market_cache.dart';
import '../../../market/domain/usecases/ping_market.dart';

sealed class TelemetryEvent extends Equatable {
  const TelemetryEvent();
  @override
  List<Object?> get props => const <Object?>[];
}

/// Measure latency (on open and on tap).
final class TelemetryPinged extends TelemetryEvent {
  const TelemetryPinged();
}

/// Clear caches, tell every screen to reload, and re-measure latency.
final class CacheClearRequested extends TelemetryEvent {
  const CacheClearRequested();
}

class TelemetryState extends Equatable {
  const TelemetryState({
    this.status = LoadStatus.initial,
    this.latency,
    this.average,
    this.clearing = false,
    this.clearedCount = 0,
  });

  final LoadStatus status;
  final Duration? latency;

  /// Mean of the latest measurements made in this session (max 5).
  final Duration? average;
  final bool clearing;

  /// Increments on every completed clear (lets the UI show a confirmation).
  final int clearedCount;

  TelemetryState copyWith({
    LoadStatus? status,
    Duration? latency,
    Duration? average,
    bool? clearing,
    int? clearedCount,
  }) =>
      TelemetryState(
        status: status ?? this.status,
        latency: latency ?? this.latency,
        average: average ?? this.average,
        clearing: clearing ?? this.clearing,
        clearedCount: clearedCount ?? this.clearedCount,
      );

  @override
  List<Object?> get props =>
      <Object?>[status, latency, average, clearing, clearedCount];
}

class TelemetryBloc extends Bloc<TelemetryEvent, TelemetryState> {
  TelemetryBloc({
    required PingMarket pingMarket,
    required ClearMarketCache clearCache,
    required DataResetSignal resetSignal,
  })  : _ping = pingMarket,
        _clear = clearCache,
        _signal = resetSignal,
        super(const TelemetryState()) {
    on<TelemetryPinged>((e, emit) => _measure(emit));
    on<CacheClearRequested>(_onClear);
  }

  final PingMarket _ping;
  final ClearMarketCache _clear;
  final DataResetSignal _signal;
  final List<Duration> _samples = <Duration>[];

  Future<void> _measure(Emitter<TelemetryState> emit) async {
    if (state.latency == null) emit(state.copyWith(status: LoadStatus.loading));
    try {
      final Duration d = await _ping();
      _samples.add(d);
      if (_samples.length > 5) _samples.removeAt(0);
      final int totalUs =
          _samples.fold<int>(0, (int s, Duration x) => s + x.inMicroseconds);
      emit(state.copyWith(
        status: LoadStatus.success,
        latency: d,
        average: Duration(microseconds: totalUs ~/ _samples.length),
      ),);
    } catch (_) {
      emit(TelemetryState(
        status: LoadStatus.failure,
        average: state.average,
        clearing: state.clearing,
        clearedCount: state.clearedCount,
      ),);
    }
  }

  Future<void> _onClear(
    CacheClearRequested e,
    Emitter<TelemetryState> emit,
  ) async {
    if (state.clearing) return;
    emit(state.copyWith(clearing: true));
    _clear();
    _signal.fire();
    await _measure(emit);
    emit(state.copyWith(clearing: false, clearedCount: state.clearedCount + 1));
  }
}
