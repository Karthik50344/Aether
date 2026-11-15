import '../entities/app_settings.dart';

abstract interface class SettingsRepository {
  /// Never throws: missing or corrupt values fall back to defaults.
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}
