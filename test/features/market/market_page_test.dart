import 'package:aether_app/core/theme/app_theme.dart';
import 'package:aether_app/features/explore/domain/usecases/filter_sort_pairs.dart';
import 'package:aether_app/features/market/data/repositories/market_repository_impl.dart';
import 'package:aether_app/features/market/domain/usecases/compute_market_overview.dart';
import 'package:aether_app/features/market/domain/usecases/get_sparkline.dart';
import 'package:aether_app/features/market/domain/usecases/get_trading_pairs.dart';
import 'package:aether_app/features/market/domain/usecases/ping_market.dart';
import 'package:aether_app/features/market/domain/usecases/select_market_movers.dart';
import 'package:aether_app/features/market/presentation/bloc/market_bloc.dart';
import 'package:aether_app/features/market/presentation/pages/market_page.dart';
import 'package:aether_app/features/market/presentation/widgets/spot_market_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/fake_market_data_source.dart';

void main() {
  late FakeMarketDataSource source;

  MarketBloc buildBloc() {
    final repo = MarketRepositoryImpl(source);
    return MarketBloc(
      getTradingPairs: GetTradingPairs(repo),
      getSparkline: GetSparkline(repo),
      pingMarket: PingMarket(repo),
      computeOverview: const ComputeMarketOverview(),
      selectMovers: const SelectMarketMovers(),
      filterSort: const FilterSortPairs(),
    );
  }

  Future<void> pumpPage(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/market',
      routes: [
        GoRoute(
          path: '/market',
          builder: (_, __) => Scaffold(
            body: BlocProvider<MarketBloc>(
              create: (_) => buildBloc()..add(const MarketStarted()),
              child: const MarketPage(sourceLabel: 'SAMPLE DATA'),
            ),
          ),
        ),
        GoRoute(
          path: '/pair/:symbol',
          builder: (_, s) => Text('DETAILS ${s.pathParameters['symbol']}'),
        ),
        GoRoute(path: '/explore', builder: (_, __) => const Text('EXPLORE')),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox.shrink());

  setUp(() => source = FakeMarketDataSource());

  testWidgets('renders overview, status, trends and rows', (tester) async {
    await pumpPage(tester);
    expect(find.text('24H USDT PAIR VOLUME'), findsOneWidget);
    expect(find.textContaining('CONNECTED · 24ms'), findsOneWidget);
    expect(find.text('SAMPLE DATA'), findsOneWidget);
    expect(find.text('Spot Markets'), findsOneWidget);
    expect(find.textContaining('advancing'), findsOneWidget);
    expect(find.text('\$67,420.50'), findsWidgets);
    await unmount(tester);
  });

  testWidgets('quote switcher changes the list', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('BTC').first);
    await tester.pumpAndSettle();
    expect(find.text('24H BTC PAIR VOLUME'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('trend tab switches to losers', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('Top Losers'));
    await tester.pumpAndSettle();
    expect(find.text('-1.20%'), findsWidgets); // ETH is the biggest loser
    await unmount(tester);
  });

  testWidgets('tapping a row opens the pair details route', (tester) async {
    await pumpPage(tester);
    final row = find.byType(SpotMarketTile).first;
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.textContaining('DETAILS '), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('shows error view with retry on first-load failure',
      (tester) async {
    source = FakeMarketDataSource(failTickers: true);
    await pumpPage(tester);
    expect(find.text('Retry'), findsOneWidget);

    source.failTickers = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Spot Markets'), findsOneWidget);
    await unmount(tester);
  });
}
