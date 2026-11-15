import 'package:aether_app/core/errors/app_exception.dart';
import 'package:aether_app/core/state/load_status.dart';
import 'package:aether_app/core/storage/key_value_store.dart';
import 'package:aether_app/features/market/domain/repositories/market_repository.dart';
import 'package:aether_app/features/market/domain/usecases/get_trading_pairs.dart';
import 'package:aether_app/features/watchlist/data/watchlist_repository_impl.dart';
import 'package:aether_app/features/watchlist/domain/entities/watchlist_summary.dart';
import 'package:aether_app/features/watchlist/domain/usecases/watchlist_usecases.dart';
import 'package:aether_app/features/watchlist/presentation/bloc/watchlist_bloc.dart';
import 'package:aether_app/shared/domain/entities/trading_pair.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fixtures.dart';

class _MockRepo extends Mock implements MarketRepository {}

void main() {
  late _MockRepo market;
  late WatchlistRepositoryImpl store;
  late WatchlistBloc bloc;

  WatchlistBloc build() => WatchlistBloc(
        getWatchlist: GetWatchlist(store),
        addToWatchlist: AddToWatchlist(store),
        removeFromWatchlist: RemoveFromWatchlist(store),
        reorderWatchlist: ReorderWatchlist(store),
        getTradingPairs: GetTradingPairs(market),
        computeSummary: const ComputeWatchlistSummary(),
      );

  setUp(() async {
    market = _MockRepo();
    store = WatchlistRepositoryImpl(InMemoryStore());
    when(() => market.getTradingPairs(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => <TradingPair>[
              pair('BTC', 'USDT', percent: 4),
              pair('ETH', 'USDT', percent: -2),
              pair('SOL', 'USDT', percent: 6),
            ],);
    await store.toggle('SOLUSDT');
    await store.toggle('ETHUSDT');
    await store.toggle('BTCUSDT'); // order: BTC, ETH, SOL
    bloc = build();
  });
  tearDown(() => bloc.close());

  Future<WatchlistState> loaded() async {
    bloc.add(const WatchlistStarted());
    return bloc.stream.firstWhere((s) => s.status == LoadStatus.success);
  }

  test('loads saved symbols in order with a summary', () async {
    final WatchlistState s = await loaded();
    expect(s.symbols, <String>['BTCUSDT', 'ETHUSDT', 'SOLUSDT']);
    expect(s.summary.count, 3);
    expect(s.summary.averageReturn, closeTo(8 / 3, 1e-9));
    expect(s.summary.advancing, 2);
    expect(s.summary.declining, 1);
  });

  test('remove updates state and storage', () async {
    await loaded();
    bloc.add(const WatchlistPairRemoved('ETHUSDT'));
    final WatchlistState s = await bloc.stream
        .firstWhere((s) => !s.symbols.contains('ETHUSDT'));
    expect(s.summary.count, 2);
    await Future<void>.delayed(Duration.zero);
    expect(await store.getSymbols(), <String>['BTCUSDT', 'SOLUSDT']);
  });

  test('add puts the symbol first and never duplicates', () async {
    await loaded();
    bloc.add(const WatchlistPairAdded('XRPUSDT'));
    await bloc.stream.firstWhere((s) => s.symbols.contains('XRPUSDT'));
    bloc.add(const WatchlistPairAdded('XRPUSDT'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(bloc.state.symbols.first, 'XRPUSDT');
    expect(bloc.state.symbols.where((x) => x == 'XRPUSDT').length, 1);
    expect(await store.getSymbols(), hasLength(4));
  });

  test('reorder uses ReorderableListView semantics and persists', () async {
    await loaded();
    bloc.add(const WatchlistReordered(0, 3)); // move first to the end
    final WatchlistState s =
        await bloc.stream.firstWhere((s) => s.symbols.first == 'ETHUSDT');
    expect(s.symbols, <String>['ETHUSDT', 'SOLUSDT', 'BTCUSDT']);
    await Future<void>.delayed(Duration.zero);
    expect(await store.getSymbols(), s.symbols);
  });

  test('edit mode toggles', () async {
    await loaded();
    bloc.add(const WatchlistEditToggled());
    expect((await bloc.stream.first).editing, isTrue);
  });

  test('a symbol with no live pair is kept but not counted', () async {
    await store.toggle('GONEUSDT');
    final WatchlistState s = await loaded();
    expect(s.symbols, contains('GONEUSDT'));
    expect(s.summary.count, 3);
  });

  test('first load failure -> failure; later refresh failure keeps data', () async {
    when(() => market.getTradingPairs(forceRefresh: any(named: 'forceRefresh')))
        .thenThrow(const NetworkUnavailableException());
    bloc.add(const WatchlistStarted());
    final WatchlistState f =
        await bloc.stream.firstWhere((s) => s.status == LoadStatus.failure);
    expect(f.errorMessage, isNotNull);
  });

  test('refresh failure after success keeps the list and flags it', () async {
    await loaded();
    when(() => market.getTradingPairs(forceRefresh: any(named: 'forceRefresh')))
        .thenThrow(const NetworkUnavailableException());
    bloc.add(const WatchlistRefreshed(force: true));
    final WatchlistState s =
        await bloc.stream.firstWhere((s) => s.refreshFailed);
    expect(s.status, LoadStatus.success);
    expect(s.symbols, isNotEmpty);
  });

  test('summary of an empty list is zeroed', () {
    expect(const ComputeWatchlistSummary()(const []),
        const WatchlistSummary.empty(),);
  });
}
