import 'package:aether_app/core/theme/app_theme.dart';
import 'package:aether_app/features/explore/domain/usecases/compute_market_flow.dart';
import 'package:aether_app/features/explore/domain/usecases/filter_sort_pairs.dart';
import 'package:aether_app/features/explore/presentation/bloc/explore_bloc.dart';
import 'package:aether_app/features/explore/presentation/pages/explore_page.dart';
import 'package:aether_app/features/explore/presentation/widgets/explore_pair_tile.dart';
import 'package:aether_app/features/explore/presentation/widgets/explore_search_field.dart';
import 'package:aether_app/features/market/data/repositories/market_repository_impl.dart';
import 'package:aether_app/features/market/domain/usecases/get_sparkline.dart';
import 'package:aether_app/features/market/domain/usecases/get_trading_pairs.dart';
import 'package:aether_app/features/market/domain/usecases/ping_market.dart';
import 'package:aether_app/shared/ui/search_focus_signal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/fake_market_data_source.dart';

void main() {
  late FakeMarketDataSource source;
  late SearchFocusSignal signal;

  ExploreBloc buildBloc() {
    final repo = MarketRepositoryImpl(source);
    return ExploreBloc(
      getTradingPairs: GetTradingPairs(repo),
      getSparkline: GetSparkline(repo),
      pingMarket: PingMarket(repo),
      filterSort: const FilterSortPairs(),
      computeFlow: const ComputeMarketFlow(),
    );
  }

  Future<void> pumpPage(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/explore',
      routes: [
        GoRoute(
          path: '/explore',
          builder: (_, __) => Scaffold(
            body: BlocProvider<ExploreBloc>(
              create: (_) => buildBloc()..add(const ExploreStarted()),
              child: ExplorePage(
                sourceLabel: 'SAMPLE DATA',
                focusSignal: signal,
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/pair/:symbol',
          builder: (_, s) => Text('DETAILS ${s.pathParameters['symbol']}'),
        ),
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
    signal = SearchFocusSignal();
  });

  testWidgets('renders header, USDT rows, breadth card and tip', (tester) async {
    await pumpPage(tester);
    expect(find.text('Explore Markets'), findsOneWidget);
    expect(find.text('BINANCE SPOT · SAMPLE DATA'), findsOneWidget);
    expect(find.text('18ms'), findsNothing);
    expect(find.text('24ms'), findsOneWidget);
    expect(find.text('Showing 4 pairs'), findsOneWidget);
    expect(find.byType(ExplorePairTile), findsWidgets);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(find.text('Market Breadth'), findsOneWidget);
    expect(find.textContaining('Pro-tip'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('typing filters after the debounce; clearing restores',
      (tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byType(TextField), 'sol');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Showing 4 pairs'), findsOneWidget); // not applied yet
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Showing 1 pair'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Showing 4 pairs'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('no match shows the empty state; reset brings rows back',
      (tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('No pairs found'), findsOneWidget);

    await tester.tap(find.text('Reset search & filters'));
    await tester.pumpAndSettle();
    expect(find.text('No pairs found'), findsNothing);
    expect(find.text('Showing 4 pairs'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('quote tabs switch the market', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('BTC'));
    await tester.pumpAndSettle();
    expect(find.text('Showing 1 pair'), findsOneWidget);

    await tester.tap(find.text('All Pairs'));
    await tester.pumpAndSettle();
    expect(find.text('Showing 5 pairs'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('filter sheet applies Gainers and shows a removable chip',
      (tester) async {
    await pumpPage(tester);
    await tester.tap(find.byType(FilterButton));
    await tester.pumpAndSettle();
    expect(find.text('Filters & sort'), findsOneWidget);

    await tester.tap(find.text('Gainers'));
    await tester.pump();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('Showing 2 pairs'), findsOneWidget); // BTC and SOL
    expect(find.text('Gainers'), findsOneWidget); // the chip
    expect(find.text('1'), findsOneWidget); // filter badge

    await tester.tap(find.text('Gainers')); // tapping the chip removes it
    await tester.pumpAndSettle();
    expect(find.text('Showing 4 pairs'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('table header sorts by price', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('LAST PRICE'));
    await tester.pumpAndSettle();
    expect(find.text('Sort: Price ↓'), findsOneWidget);
    await tester.tap(find.text('LAST PRICE'));
    await tester.pumpAndSettle();
    expect(find.text('Sort: Price ↑'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('tapping a row opens the details route', (tester) async {
    await pumpPage(tester);
    final row = find.byType(ExplorePairTile).first;
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.textContaining('DETAILS '), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a pending header-search request focuses the field',
      (tester) async {
    signal.request(); // made before the tab exists
    await pumpPage(tester);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode!.hasFocus, isTrue);
    expect(signal.pending, isFalse);
    await unmount(tester);
  });

  testWidgets('error view offers retry', (tester) async {
    source = FakeMarketDataSource(failTickers: true);
    await pumpPage(tester);
    expect(find.text('Retry'), findsOneWidget);
    source.failTickers = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Explore Markets'), findsOneWidget);
    await unmount(tester);
  });
}
