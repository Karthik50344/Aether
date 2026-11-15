import 'package:aether_app/core/storage/key_value_store.dart';
import 'package:aether_app/core/theme/app_theme.dart';
import 'package:aether_app/features/coin_details/domain/usecases/build_chart_series.dart';
import 'package:aether_app/features/coin_details/domain/usecases/compute_pair_stats.dart';
import 'package:aether_app/features/coin_details/domain/usecases/get_candlesticks.dart';
import 'package:aether_app/features/coin_details/domain/usecases/get_daily_candles.dart';
import 'package:aether_app/features/coin_details/domain/usecases/get_order_book_depth.dart';
import 'package:aether_app/features/coin_details/domain/usecases/get_recent_trades.dart';
import 'package:aether_app/features/coin_details/presentation/bloc/coin_details_bloc.dart';
import 'package:aether_app/features/coin_details/presentation/pages/coin_details_page.dart';
import 'package:aether_app/features/coin_details/presentation/widgets/chart_panels.dart';
import 'package:aether_app/features/market/data/repositories/market_repository_impl.dart';
import 'package:aether_app/features/market/domain/usecases/get_trading_pair.dart';
import 'package:aether_app/features/watchlist/data/watchlist_repository_impl.dart';
import 'package:aether_app/features/watchlist/domain/usecases/watchlist_usecases.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/fake_market_data_source.dart';

void main() {
  late FakeMarketDataSource source;
  late InMemoryStore store;

  CoinDetailsBloc buildBloc(String symbol) {
    final repo = MarketRepositoryImpl(source);
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
    );
  }

  Future<void> pumpPage(WidgetTester tester, {String symbol = 'BTCUSDT'}) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/pair/$symbol',
      routes: [
        GoRoute(
          path: '/pair/:symbol',
          builder: (_, s) => BlocProvider<CoinDetailsBloc>(
            create: (_) =>
                buildBloc(s.pathParameters['symbol']!)..add(const CoinDetailsStarted()),
            child: CoinDetailsPage(
              symbol: s.pathParameters['symbol']!,
              now: () => DateTime.utc(2026, 11, 14, 15),
            ),
          ),
        ),
        GoRoute(path: '/watchlist', builder: (_, __) => const Text('WATCHLIST PAGE')),
        GoRoute(path: '/market', builder: (_, __) => const Text('MARKET PAGE')),
        GoRoute(path: '/explore', builder: (_, __) => const Text('EXPLORE PAGE')),
        GoRoute(path: '/settings', builder: (_, __) => const Text('SETTINGS PAGE')),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox.shrink());

  setUp(() {
    source = FakeMarketDataSource();
    store = InMemoryStore();
  });

  testWidgets('shows price, delta, chart, stats, depth and trades',
      (tester) async {
    await pumpPage(tester);
    expect(find.text('Asset Detail'), findsOneWidget);
    expect(find.text('BTC/USDT'), findsOneWidget);
    expect(find.text('\$67,420.50'), findsWidgets);
    expect(find.textContaining('(+3.42%)'), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('24H Market Statistics'), findsOneWidget);
    expect(find.text('24h High'), findsOneWidget);
    expect(find.text('Matched Trades'), findsOneWidget);
    expect(find.textContaining('Bid Depth: 60%'), findsOneWidget);
    expect(find.textContaining('Taker buy share: 60%'), findsOneWidget);
    expect(find.text('BUY'), findsWidgets);
    expect(find.text('SELL'), findsWidgets);
    expect(find.text('Recent Trades'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('indicator toggles add and remove the VOL and RSI panels',
      (tester) async {
    await pumpPage(tester);
    expect(find.byKey(const ValueKey<String>('panel-vol')), findsNothing);
    expect(find.byKey(const ValueKey<String>('panel-rsi')), findsNothing);

    await tester.tap(find.text('VOL'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('panel-vol')), findsOneWidget);
    expect(find.byType(VolumePanel), findsOneWidget);

    await tester.tap(find.text('RSI'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('panel-rsi')), findsOneWidget);

    await tester.tap(find.text('VOL').first); // the chip (panel label comes later)
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('panel-vol')), findsNothing);
    await unmount(tester);
  });

  testWidgets('period selector switches range and High/Low tag wording',
      (tester) async {
    await pumpPage(tester);
    // 1D is the default: the real 24h window.
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.extraLinesData.horizontalLines.first.label.labelResolver(
            chart.data.extraLinesData.horizontalLines.first,),
        startsWith('24h High'),);

    await tester.tap(find.text('1W'));
    await tester.pumpAndSettle();
    final week = tester.widget<LineChart>(find.byType(LineChart));
    expect(week.data.extraLinesData.horizontalLines.first.label.labelResolver(
            week.data.extraLinesData.horizontalLines.first,),
        startsWith('Period High'),);
    await unmount(tester);
  });

  testWidgets('star toggles the watchlist and persists it', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.byTooltip('Add to watchlist'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove from watchlist'), findsOneWidget);
    expect(await WatchlistRepositoryImpl(store).contains('BTCUSDT'), isTrue);

    await tester.tap(find.byTooltip('Remove from watchlist'));
    await tester.pumpAndSettle();
    expect(await WatchlistRepositoryImpl(store).contains('BTCUSDT'), isFalse);
    await unmount(tester);
  });

  testWidgets('already-watched pair opens pinned', (tester) async {
    await WatchlistRepositoryImpl(store).toggle('BTCUSDT');
    await pumpPage(tester);
    expect(find.text('Pinned'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('share copies a summary; arrow and nav buttons navigate',
      (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),);

    await pumpPage(tester);
    await tester.tap(find.byIcon(Icons.ios_share));
    await tester.pumpAndSettle();
    expect(find.text('Summary copied to clipboard'), findsOneWidget);
    expect(copied, contains('BTC/USDT'));
    expect(copied, contains('\$67,420.50'));

    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();
    expect(find.text('WATCHLIST PAGE'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('floating nav and avatar navigate', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    expect(find.text('EXPLORE PAGE'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a failing trades section shows an inline retry only',
      (tester) async {
    source = FakeMarketDataSource(failTrades: true);
    await pumpPage(tester);
    expect(find.text('Could not load recent trades.'), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget); // rest still works

    source.failTrades = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Could not load recent trades.'), findsNothing);
    expect(find.text('BUY'), findsWidgets);
    await unmount(tester);
  });

  testWidgets('unknown pair shows an error view with retry', (tester) async {
    await pumpPage(tester, symbol: 'NOPEUSDT');
    expect(find.text('Could not load NOPEUSDT'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    await unmount(tester);
  });
}
