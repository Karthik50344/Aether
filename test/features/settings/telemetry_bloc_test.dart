import 'package:aether_app/core/errors/app_exception.dart';
import 'package:aether_app/core/state/load_status.dart';
import 'package:aether_app/features/market/domain/repositories/market_repository.dart';
import 'package:aether_app/features/market/domain/usecases/clear_market_cache.dart';
import 'package:aether_app/features/market/domain/usecases/ping_market.dart';
import 'package:aether_app/features/settings/presentation/bloc/telemetry_bloc.dart';
import 'package:aether_app/shared/ui/data_reset_signal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements MarketRepository {}

void main() {
  late _MockRepo repo;
  late DataResetSignal signal;
  late TelemetryBloc bloc;

  setUp(() {
    repo = _MockRepo();
    signal = DataResetSignal();
    bloc = TelemetryBloc(
      pingMarket: PingMarket(repo),
      clearCache: ClearMarketCache(repo),
      resetSignal: signal,
    );
  });
  tearDown(() => bloc.close());

  test('ping success stores latency and average', () async {
    when(() => repo.ping()).thenAnswer((_) async => const Duration(milliseconds: 30));
    bloc.add(const TelemetryPinged());
    final TelemetryState s = await bloc.stream
        .firstWhere((TelemetryState s) => s.status == LoadStatus.success);
    expect(s.latency, const Duration(milliseconds: 30));
    expect(s.average, const Duration(milliseconds: 30));
  });

  test('ping failure becomes a failure state', () async {
    when(() => repo.ping()).thenThrow(const NetworkUnavailableException());
    bloc.add(const TelemetryPinged());
    final TelemetryState s = await bloc.stream
        .firstWhere((TelemetryState s) => s.status == LoadStatus.failure);
    expect(s.latency, isNull);
  });

  test('clear: clears cache, fires the reset signal, re-pings', () async {
    when(() => repo.ping()).thenAnswer((_) async => const Duration(milliseconds: 10));
    int fired = 0;
    signal.addListener(() => fired++);
    bloc.add(const CacheClearRequested());
    final TelemetryState s = await bloc.stream
        .firstWhere((TelemetryState s) => s.clearedCount == 1 && !s.clearing);
    verify(() => repo.clearCache()).called(1);
    verify(() => repo.ping()).called(1);
    expect(fired, 1);
    expect(s.status, LoadStatus.success);
  });
}
