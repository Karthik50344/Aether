import 'package:get_it/get_it.dart';

import '../../core/info/app_info.dart';
import '../../features/market/domain/usecases/clear_market_cache.dart';
import '../../features/settings/data/settings_repository_impl.dart';
import '../../features/settings/domain/entities/app_settings.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/settings_usecases.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';
import '../../features/settings/presentation/bloc/telemetry_bloc.dart';
import '../../features/watchlist/domain/entities/watchlist_summary.dart';
import '../../features/watchlist/presentation/bloc/watchlist_bloc.dart';
import '../../shared/ui/data_reset_signal.dart';

import '../../core/storage/key_value_store.dart';
import '../../features/coin_details/domain/usecases/build_chart_series.dart';
import '../../features/coin_details/domain/usecases/compute_pair_stats.dart';
import '../../features/coin_details/domain/usecases/get_candlesticks.dart';
import '../../features/coin_details/domain/usecases/get_daily_candles.dart';
import '../../features/coin_details/presentation/bloc/coin_details_bloc.dart';
import '../../features/watchlist/data/watchlist_repository_impl.dart';
import '../../features/watchlist/domain/repositories/watchlist_repository.dart';
import '../../features/watchlist/domain/usecases/watchlist_usecases.dart';
import '../../features/coin_details/domain/usecases/get_order_book_depth.dart';
import '../../features/coin_details/domain/usecases/get_recent_trades.dart';
import '../../features/explore/domain/usecases/filter_sort_pairs.dart';
import '../../features/market/data/datasources/market_datasource.dart';
import '../../core/network/api_client.dart';
import '../../features/market/data/datasources/market_remote_datasource.dart';
import '../../features/market/data/repositories/market_repository_impl.dart';
import '../../features/market/domain/repositories/market_repository.dart';
import '../../features/market/domain/usecases/compute_market_overview.dart';
import '../../features/market/domain/usecases/get_sparkline.dart';
import '../../features/market/domain/usecases/get_trading_pair.dart';
import '../../features/market/domain/usecases/get_trading_pairs.dart';
import '../../features/market/domain/usecases/ping_market.dart';
import '../../features/market/domain/usecases/select_market_movers.dart';
import '../../features/explore/domain/usecases/compute_market_flow.dart';
import '../../features/explore/presentation/bloc/explore_bloc.dart';
import '../../features/market/presentation/bloc/market_bloc.dart';
import '../../shared/ui/search_focus_signal.dart';
import '../config/app_config.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies({
  AppConfig? config,
  MarketDataSource? marketDataSource,
  KeyValueStore? store,
  AppInfo appInfo = const AppInfo(),
  Duration? autoRefreshInterval = const Duration(seconds: 15),
}) async {
  await sl.reset();
  final AppConfig cfg = config ?? const AppConfig();
  sl.registerSingleton<AppConfig>(cfg);
  sl.registerSingleton<KeyValueStore>(store ?? InMemoryStore());
  sl.registerSingleton<AppInfo>(appInfo);
  sl.registerSingleton<RefreshPolicy>(RefreshPolicy(autoRefreshInterval));
  sl.registerSingleton<DataResetSignal>(DataResetSignal());

  // Settings: one app-wide bloc, created with the persisted values so the
  // very first frame already uses the saved theme.
  sl.registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(sl<KeyValueStore>()),);
  sl.registerLazySingleton<GetSettings>(
      () => GetSettings(sl<SettingsRepository>()),);
  sl.registerLazySingleton<SaveSettings>(
      () => SaveSettings(sl<SettingsRepository>()),);
  final AppSettings loadedSettings = await sl<GetSettings>()();
  sl.registerSingleton<SettingsBloc>(
    SettingsBloc(saveSettings: sl<SaveSettings>(), initial: loadedSettings),
    dispose: (SettingsBloc b) => b.close(),
  );

  // Data source: the only place that knows mock vs remote.
  sl.registerLazySingleton<MarketDataSource>(() {
    if (marketDataSource != null) return marketDataSource;
    return MarketRemoteDataSource(sl<ApiClient>());
  });
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient.forBaseUrl(AppConfig.binanceBaseUrl),
  );

  sl.registerLazySingleton<MarketRepository>(
    () => MarketRepositoryImpl(sl<MarketDataSource>()),
  );

  // Use cases
  sl.registerLazySingleton<GetTradingPairs>(
      () => GetTradingPairs(sl<MarketRepository>()),);
  sl.registerLazySingleton<GetTradingPair>(
      () => GetTradingPair(sl<MarketRepository>()),);
  sl.registerLazySingleton<GetSparkline>(
      () => GetSparkline(sl<MarketRepository>()),);
  sl.registerLazySingleton<PingMarket>(
      () => PingMarket(sl<MarketRepository>()),);
  sl.registerLazySingleton<ComputeMarketOverview>(
      () => const ComputeMarketOverview(),);
  sl.registerLazySingleton<SelectMarketMovers>(
      () => const SelectMarketMovers(),);
  sl.registerLazySingleton<FilterSortPairs>(() => const FilterSortPairs());
  sl.registerLazySingleton<ComputeMarketFlow>(() => const ComputeMarketFlow());
  sl.registerLazySingleton<SearchFocusSignal>(SearchFocusSignal.new);
  sl.registerLazySingleton<GetCandlesticks>(
      () => GetCandlesticks(sl<MarketRepository>()),);
  sl.registerLazySingleton<GetRecentTrades>(
      () => GetRecentTrades(sl<MarketRepository>()),);
  sl.registerLazySingleton<GetOrderBookDepth>(
      () => GetOrderBookDepth(sl<MarketRepository>()),);

  sl.registerLazySingleton<GetDailyCandles>(
      () => GetDailyCandles(sl<MarketRepository>()),);
  sl.registerLazySingleton<BuildChartSeries>(() => const BuildChartSeries());
  sl.registerLazySingleton<ComputePairStats>(() => const ComputePairStats());

  sl.registerLazySingleton<ClearMarketCache>(
      () => ClearMarketCache(sl<MarketRepository>()),);
  sl.registerLazySingleton<ComputeWatchlistSummary>(
      () => const ComputeWatchlistSummary(),);

  // Watchlist (persistent)
  sl.registerLazySingleton<WatchlistRepository>(
      () => WatchlistRepositoryImpl(sl<KeyValueStore>()),);
  sl.registerLazySingleton<IsInWatchlist>(
      () => IsInWatchlist(sl<WatchlistRepository>()),);
  sl.registerLazySingleton<ToggleWatchlist>(
      () => ToggleWatchlist(sl<WatchlistRepository>()),);
  sl.registerLazySingleton<GetWatchlist>(
      () => GetWatchlist(sl<WatchlistRepository>()),);
  sl.registerLazySingleton<AddToWatchlist>(
      () => AddToWatchlist(sl<WatchlistRepository>()),);
  sl.registerLazySingleton<RemoveFromWatchlist>(
      () => RemoveFromWatchlist(sl<WatchlistRepository>()),);
  sl.registerLazySingleton<ReorderWatchlist>(
      () => ReorderWatchlist(sl<WatchlistRepository>()),);

  // Blocs are factories: each screen instance gets its own.
  sl.registerFactory<MarketBloc>(
    () => MarketBloc(
      getTradingPairs: sl<GetTradingPairs>(),
      getSparkline: sl<GetSparkline>(),
      pingMarket: sl<PingMarket>(),
      computeOverview: sl<ComputeMarketOverview>(),
      selectMovers: sl<SelectMarketMovers>(),
      filterSort: sl<FilterSortPairs>(),
      autoRefreshInterval: autoRefreshInterval,
    ),
  );
  sl.registerFactory<ExploreBloc>(
    () => ExploreBloc(
      getTradingPairs: sl<GetTradingPairs>(),
      getSparkline: sl<GetSparkline>(),
      pingMarket: sl<PingMarket>(),
      filterSort: sl<FilterSortPairs>(),
      computeFlow: sl<ComputeMarketFlow>(),
      initialQuote: sl<SettingsBloc>().state.settings.defaultQuote,
      autoRefreshInterval: autoRefreshInterval,
    ),
  );
  // One bloc per opened pair: sl<CoinDetailsBloc>(param1: 'BTCUSDT').
  sl.registerFactoryParam<CoinDetailsBloc, String, void>(
    (String symbol, _) => CoinDetailsBloc(
      symbol: symbol,
      initialPeriod: sl<SettingsBloc>().state.settings.defaultPeriod,
      getPair: sl<GetTradingPair>(),
      getCandlesticks: sl<GetCandlesticks>(),
      getDailyCandles: sl<GetDailyCandles>(),
      getRecentTrades: sl<GetRecentTrades>(),
      getDepth: sl<GetOrderBookDepth>(),
      buildSeries: sl<BuildChartSeries>(),
      computeStats: sl<ComputePairStats>(),
      isInWatchlist: sl<IsInWatchlist>(),
      toggleWatchlist: sl<ToggleWatchlist>(),
      autoRefreshInterval: autoRefreshInterval,
    ),
  );

  sl.registerFactory<WatchlistBloc>(
    () => WatchlistBloc(
      getWatchlist: sl<GetWatchlist>(),
      addToWatchlist: sl<AddToWatchlist>(),
      removeFromWatchlist: sl<RemoveFromWatchlist>(),
      reorderWatchlist: sl<ReorderWatchlist>(),
      getTradingPairs: sl<GetTradingPairs>(),
      computeSummary: sl<ComputeWatchlistSummary>(),
      autoRefreshInterval: autoRefreshInterval,
    ),
  );
  sl.registerFactory<TelemetryBloc>(
    () => TelemetryBloc(
      pingMarket: sl<PingMarket>(),
      clearCache: sl<ClearMarketCache>(),
      resetSignal: sl<DataResetSignal>(),
    ),
  );
}
