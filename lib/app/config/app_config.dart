/// Which data source the repositories use. Not an enum (project rule): a
/// small set of typed string constants.
abstract final class DataSourceMode {
  static const String mock = 'mock';
  static const String remote = 'remote';
}

/// Build-time configuration.
///
/// Switch the data source without touching code:
///   flutter run --dart-define=DATA_SOURCE=mock     (default)
///   flutter run --dart-define=DATA_SOURCE=remote   (Binance public REST)
class AppConfig {
  const AppConfig({required this.dataSource});

  /// Reads `--dart-define` values.
  factory AppConfig.fromEnvironment() {
    const String raw =
        String.fromEnvironment('DATA_SOURCE', defaultValue: DataSourceMode.mock);
    return AppConfig(
      dataSource: raw == DataSourceMode.remote
          ? DataSourceMode.remote
          : DataSourceMode.mock,
    );
  }

  final String dataSource;

  bool get useMock => dataSource == DataSourceMode.mock;
  bool get useRemote => dataSource == DataSourceMode.remote;

  /// Binance market-data-only host (no API key needed).
  static const String binanceBaseUrl = 'https://data-api.binance.vision';
}
