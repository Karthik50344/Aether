import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/quote_assets.dart';
import '../../core/info/app_info.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';
import '../../features/settings/presentation/bloc/telemetry_bloc.dart';
import '../../features/settings/presentation/pages/privacy_page.dart';
import '../../features/watchlist/presentation/bloc/watchlist_bloc.dart';
import '../../shared/ui/data_reset_signal.dart';
import '../../shared/ui/reset_listener.dart';
import '../config/app_config.dart';
import '../di/injection.dart';
import '../../features/coin_details/presentation/bloc/coin_details_bloc.dart';
import '../../features/explore/presentation/bloc/explore_bloc.dart';
import '../../features/market/presentation/bloc/market_bloc.dart';
import '../../shared/ui/search_focus_signal.dart';

import '../../features/coin_details/presentation/pages/coin_details_page.dart';
import '../../features/explore/presentation/pages/explore_page.dart';
import '../../features/market/presentation/pages/market_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/watchlist/presentation/pages/watchlist_page.dart';
import '../../shared/widgets/app_shell.dart';
import 'route_names.dart';

/// Builds the application router.
///
/// * Four tabs live in a [StatefulShellRoute.indexedStack] so each tab keeps
///   its scroll position / state while switching.
/// * The pair-details page is a root-level route pushed above the shell
///   (Figma shows it with a back arrow and its own floating navigation).
GoRouter buildAppRouter({String initialLocation = RoutePaths.market}) {
  final GlobalKey<NavigatorState> rootKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: initialLocation,
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (BuildContext context, GoRouterState state,
            StatefulNavigationShell shell,) {
          return AppShell(navigationShell: shell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.market,
                name: RouteNames.market,
                builder: (_, __) => BlocProvider<MarketBloc>(
                  create: (_) {
                    final MarketBloc b = sl<MarketBloc>()..add(const MarketStarted());
                    final String q = sl<SettingsBloc>().state.settings.defaultQuote;
                    if (QuoteAssets.dashboard.contains(q)) {
                      b.add(MarketQuoteSelected(q));
                    }
                    return b;
                  },
                  child: BlocListener<SettingsBloc, SettingsState>(
                    bloc: sl<SettingsBloc>(),
                    listenWhen: (SettingsState a, SettingsState b) =>
                        a.settings.defaultQuote != b.settings.defaultQuote,
                    listener: (BuildContext ctx, SettingsState st) {
                      final String q = st.settings.defaultQuote;
                      if (QuoteAssets.dashboard.contains(q)) {
                        ctx.read<MarketBloc>().add(MarketQuoteSelected(q));
                      }
                    },
                    child: ResetListener(
                      signal: sl<DataResetSignal>(),
                      onReset: (BuildContext c) =>
                          c.read<MarketBloc>().add(const MarketRefreshed()),
                      child: MarketPage(
                    sourceLabel:
                        sl<AppConfig>().useMock ? 'SAMPLE DATA' : 'SPOT',
                  ),
                  ),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.explore,
                name: RouteNames.explore,
                builder: (_, __) => BlocProvider<ExploreBloc>(
                  create: (_) => sl<ExploreBloc>()..add(const ExploreStarted()),
                  child: BlocListener<SettingsBloc, SettingsState>(
                    bloc: sl<SettingsBloc>(),
                    listenWhen: (SettingsState a, SettingsState b) =>
                        a.settings.defaultQuote != b.settings.defaultQuote,
                    listener: (BuildContext ctx, SettingsState st) => ctx
                        .read<ExploreBloc>()
                        .add(ExploreQuoteSelected(st.settings.defaultQuote)),
                    child: ResetListener(
                      signal: sl<DataResetSignal>(),
                      onReset: (BuildContext c) =>
                          c.read<ExploreBloc>().add(const ExploreRefreshed()),
                      child: ExplorePage(
                        sourceLabel:
                            sl<AppConfig>().useMock ? 'SAMPLE DATA' : 'REST',
                        focusSignal: sl<SearchFocusSignal>(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.watchlist,
                name: RouteNames.watchlist,
                builder: (_, __) => BlocProvider<WatchlistBloc>(
                  create: (_) =>
                      sl<WatchlistBloc>()..add(const WatchlistStarted()),
                  child: WatchlistPage(resetSignal: sl<DataResetSignal>()),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.settings,
                name: RouteNames.settings,
                builder: (_, __) => BlocProvider<TelemetryBloc>(
                  create: (_) =>
                      sl<TelemetryBloc>()..add(const TelemetryPinged()),
                  child: SettingsPage(
                    appInfo: sl<AppInfo>(),
                    refreshPolicy: sl<RefreshPolicy>(),
                    dataSourceLabel: sl<AppConfig>().useMock
                        ? 'Sample data (offline JSON)'
                        : 'Binance Spot REST',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: RoutePaths.privacy,
        name: RouteNames.privacy,
        builder: (_, __) => const PrivacyPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: RoutePaths.pairDetails,
        name: RouteNames.pairDetails,
        builder: (BuildContext context, GoRouterState state) {
          final String symbol = state.pathParameters['symbol'] ?? '';
          return BlocProvider<CoinDetailsBloc>(
            key: ValueKey<String>(symbol),
            create: (_) => sl<CoinDetailsBloc>(param1: symbol)
              ..add(const CoinDetailsStarted()),
            child: CoinDetailsPage(symbol: symbol.toUpperCase()),
          );
        },
      ),
    ],
  );
}
