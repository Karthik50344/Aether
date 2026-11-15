import '../../../core/storage/key_value_store.dart';
import '../../coin_details/domain/entities/chart_period.dart';
import '../domain/entities/app_settings.dart';
import '../domain/entities/theme_preference.dart';
import '../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._store);

  static const String themeKey = 'settings_theme_v1';
  static const String quoteKey = 'settings_default_quote_v1';
  static const String periodKey = 'settings_default_period_v1';
  static const String compactKey = 'settings_compact_metrics_v1';

  final KeyValueStore _store;

  @override
  Future<AppSettings> load() async {
    const AppSettings defaults = AppSettings();
    try {
      final String? quote = await _store.readString(quoteKey);
      return AppSettings(
        theme: ThemePreference.fromId(await _store.readString(themeKey)),
        defaultQuote: (quote != null && AppSettings.quoteOptions.contains(quote))
            ? quote
            : defaults.defaultQuote,
        defaultPeriod: ChartPeriod.fromId(await _store.readString(periodKey)),
        compactMetrics:
            await _store.readBool(compactKey) ?? defaults.compactMetrics,
      );
    } catch (_) {
      return defaults;
    }
  }

  @override
  Future<void> save(AppSettings s) async {
    await _store.writeString(themeKey, s.theme.id);
    await _store.writeString(quoteKey, s.defaultQuote);
    await _store.writeString(periodKey, s.defaultPeriod.id);
    await _store.writeBool(compactKey, s.compactMetrics);
  }
}
