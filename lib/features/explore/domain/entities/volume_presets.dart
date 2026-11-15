import '../../../../core/constants/quote_assets.dart';

/// Selectable "minimum 24h quote volume" values per quote asset. Volumes are
/// in units of the quote asset, so the presets differ (1 BTC is not 1 USDT).
abstract final class VolumePresets {
  static const List<double> _dollar = <double>[
    100e3,
    1e6,
    10e6,
    100e6,
  ];
  static const List<double> _btc = <double>[1, 10, 100, 1000];
  static const List<double> _eth = <double>[10, 100, 1000, 10000];

  /// Empty when [quote] is null (All Pairs mixes units) or has no presets.
  static List<double> forQuote(String? quote) {
    switch (quote) {
      case QuoteAssets.usdt:
      case QuoteAssets.fdusd:
      case QuoteAssets.eur:
        return _dollar;
      case QuoteAssets.btc:
        return _btc;
      case QuoteAssets.eth:
        return _eth;
      default:
        return const <double>[];
    }
  }
}
