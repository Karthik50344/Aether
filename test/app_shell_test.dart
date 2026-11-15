import 'package:aether_app/app/app.dart';
import 'package:aether_app/app/config/app_config.dart';
import 'package:aether_app/app/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_market_data_source.dart';

void main() {
  setUp(() async {
    await configureDependencies(
      config: const AppConfig(dataSource: DataSourceMode.mock),
      marketDataSource: FakeMarketDataSource(),
      autoRefreshInterval: null,
    );
  });

  /// Unmount so timers owned by widgets/blocs are cancelled.
  Future<void> unmount(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox.shrink());

  testWidgets('starts on Market and shows all four navigation tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AetherApp());
    await tester.pumpAndSettle();

    expect(find.text('Spot Markets'), findsOneWidget);
    for (final String label in <String>[
      'Market',
      'Explore',
      'Watchlist',
      'Settings',
    ]) {
      expect(find.text(label), findsWidgets);
    }
    await unmount(tester);
  });

  testWidgets('tapping a tab switches the screen and header label',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AetherApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Explore').last);
    await tester.pumpAndSettle();
    expect(find.text('Explore Markets'), findsOneWidget);

    await tester.tap(find.text('Watchlist').last);
    await tester.pumpAndSettle();
    expect(find.text('My Watchlist'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('header search button opens Explore',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AetherApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Search trading pairs'));
    await tester.pumpAndSettle();
    expect(find.text('Explore Markets'), findsOneWidget);
    await unmount(tester);
  });

  test('AppConfig exposes the selected data source', () {
    const AppConfig mock = AppConfig(dataSource: DataSourceMode.mock);
    const AppConfig remote = AppConfig(dataSource: DataSourceMode.remote);
    expect(mock.useMock, isTrue);
    expect(remote.useRemote, isTrue);
  });
}
