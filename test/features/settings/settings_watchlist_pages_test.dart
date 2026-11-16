import 'package:aether_app/app/app.dart';
import 'package:aether_app/app/config/app_config.dart';
import 'package:aether_app/app/di/injection.dart';
import 'package:aether_app/features/settings/domain/entities/theme_preference.dart';
import 'package:aether_app/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_market_data_source.dart';

void main() {
  setUp(() async {
    await configureDependencies(
      config: const AppConfig(),
      marketDataSource: FakeMarketDataSource(),
      autoRefreshInterval: null,
    );
  });

  Future<void> unmount(WidgetTester t) => t.pumpWidget(const SizedBox.shrink());

  Future<void> openTab(WidgetTester t, String label) async {
    await t.pumpWidget(const AetherApp());
    await t.pumpAndSettle();
    await t.tap(find.text(label).last);
    await t.pumpAndSettle();
  }

  testWidgets('Settings shows real telemetry and no fictional labels',
      (WidgetTester t) async {
    await openTab(t, 'Settings');
    expect(find.text('Aether Crypto Terminal'), findsOneWidget);
    expect(find.textContaining('Operational'), findsOneWidget);
    expect(find.textContaining('24 ms'), findsWidgets);
    expect(find.text('Flutter Component Preview'), findsNothing);
    expect(find.text('Display Currency'), findsNothing);
    await unmount(t);
  });

  testWidgets('theme choice is applied to the app and stored in the bloc',
      (WidgetTester t) async {
    await openTab(t, 'Settings');
    await t.tap(find.text('Light'));
    await t.pumpAndSettle();
    expect(sl<SettingsBloc>().state.settings.theme, ThemePreference.light);
    final MaterialApp app = t.widget(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
    await unmount(t);
  });

  testWidgets('compact metrics switch updates settings',
      (WidgetTester t) async {
    await openTab(t, 'Settings');
    await t.tap(find.byType(Switch));
    await t.pumpAndSettle();
    expect(sl<SettingsBloc>().state.settings.compactMetrics, isFalse);
    await unmount(t);
  });

  testWidgets('Clear Cache & Reset Datafeed shows confirmation',
      (WidgetTester t) async {
    await openTab(t, 'Settings');
    await t.scrollUntilVisible(
      find.text('Clear Cache & Reset Datafeed'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await t.tap(find.text('Clear Cache & Reset Datafeed'));
    await t.pumpAndSettle();
    expect(find.text('Cache cleared. Data reloaded.'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('Privacy opens the in-app page', (WidgetTester t) async {
    await openTab(t, 'Settings');
    await t.scrollUntilVisible(
      find.text('Privacy'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await t.tap(find.text('Privacy'));
    await t.pumpAndSettle();
    expect(find.text('Research only'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('empty watchlist shows the empty state; Add Pair saves a pair',
      (WidgetTester t) async {
    await openTab(t, 'Watchlist');
    expect(find.text('Your watchlist is empty'), findsOneWidget);
    expect(find.text('Explore Markets →'), findsOneWidget);

    await t.tap(find.text('Add Pair').first);
    await t.pumpAndSettle();
    await t.tap(find.text('BTC/USDT').first);
    await t.pumpAndSettle();
    await t.tapAt(const Offset(5, 5)); // dismiss the sheet
    await t.pumpAndSettle();

    expect(find.text('Your watchlist is empty'), findsNothing);
    expect(find.text('BTC / USDT'), findsNothing); // row uses displayName
    expect(find.text('BTC/USDT'), findsOneWidget);
    expect(find.textContaining('1 SAVED PAIRS'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('Edit toggles to Done and remove empties the list',
      (WidgetTester t) async {
    await openTab(t, 'Watchlist');
    await t.tap(find.text('Add Pair').first);
    await t.pumpAndSettle();
    await t.tap(find.text('BTC/USDT').first);
    await t.pumpAndSettle();
    await t.tapAt(const Offset(5, 5));
    await t.pumpAndSettle();

    await t.tap(find.text('Edit'));
    await t.pumpAndSettle();
    expect(find.text('Done'), findsOneWidget);
    await t.tap(find.byTooltip('Remove BTCUSDT from watchlist').first);
    await t.pumpAndSettle();
    expect(find.text('Your watchlist is empty'), findsOneWidget);
    await unmount(t);
  });
}
