import 'package:aether_app/core/storage/key_value_store.dart';
import 'package:aether_app/features/coin_details/domain/entities/chart_period.dart';
import 'package:aether_app/features/settings/data/settings_repository_impl.dart';
import 'package:aether_app/features/settings/domain/entities/app_settings.dart';
import 'package:aether_app/features/settings/domain/entities/theme_preference.dart';
import 'package:aether_app/features/settings/domain/usecases/settings_usecases.dart';
import 'package:aether_app/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SettingsRepositoryImpl', () {
    test('returns defaults on an empty store', () async {
      final SettingsRepositoryImpl r = SettingsRepositoryImpl(InMemoryStore());
      expect(await r.load(), const AppSettings());
    });

    test('round-trips every field', () async {
      final InMemoryStore store = InMemoryStore();
      final SettingsRepositoryImpl r = SettingsRepositoryImpl(store);
      const AppSettings s = AppSettings(
        theme: ThemePreference.light,
        defaultQuote: 'BTC',
        defaultPeriod: ChartPeriod.week1,
        compactMetrics: false,
      );
      await r.save(s);
      expect(await SettingsRepositoryImpl(store).load(), s);
    });

    test('unknown / corrupt values fall back to defaults', () async {
      final InMemoryStore store = InMemoryStore();
      await store.writeString(SettingsRepositoryImpl.themeKey, 'neon');
      await store.writeString(SettingsRepositoryImpl.quoteKey, 'DOGE');
      await store.writeString(SettingsRepositoryImpl.periodKey, '9Z');
      final AppSettings s = await SettingsRepositoryImpl(store).load();
      expect(s, const AppSettings());
    });
  });

  group('SettingsBloc', () {
    late InMemoryStore store;
    late SettingsBloc bloc;

    setUp(() {
      store = InMemoryStore();
      bloc = SettingsBloc(
        saveSettings: SaveSettings(SettingsRepositoryImpl(store)),
      );
    });
    tearDown(() => bloc.close());

    test('applies a change and persists it', () async {
      bloc.add(const ThemeChanged(ThemePreference.light));
      bloc.add(const DefaultQuoteChanged('FDUSD'));
      bloc.add(const DefaultPeriodChanged(ChartPeriod.month1));
      bloc.add(const CompactMetricsChanged(compact: false));
      await bloc.stream.firstWhere((SettingsState s) =>
          !s.settings.compactMetrics &&
          s.settings.defaultPeriod == ChartPeriod.month1,);
      await Future<void>.delayed(Duration.zero);

      final AppSettings saved = await SettingsRepositoryImpl(store).load();
      expect(saved.theme, ThemePreference.light);
      expect(saved.defaultQuote, 'FDUSD');
      expect(saved.defaultPeriod, ChartPeriod.month1);
      expect(saved.compactMetrics, isFalse);
    });

    test('an unchanged value emits nothing', () async {
      final List<SettingsState> seen = <SettingsState>[];
      final sub = bloc.stream.listen(seen.add);
      bloc.add(const ThemeChanged(ThemePreference.defaultValue));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(seen, isEmpty);
      await sub.cancel();
    });
  });

  test('ThemePreference.fromId falls back to dark', () {
    expect(ThemePreference.fromId('light'), ThemePreference.light);
    expect(ThemePreference.fromId(null), ThemePreference.dark);
  });
}
