/// Quote assets the UI offers as filters/switchers, in display order.
/// (Which ones actually exist comes from exchangeInfo; these are just the
/// ones we give first-class UI to.)
abstract final class QuoteAssets {
  static const String usdt = 'USDT';
  static const String btc = 'BTC';
  static const String eth = 'ETH';
  static const String fdusd = 'FDUSD';
  static const String eur = 'EUR';

  static const List<String> primary = <String>[usdt, btc, eth, fdusd, eur];

  /// Quote switcher on the dashboard (Figma: USDT / BTC / FDUSD).
  static const List<String> dashboard = <String>[usdt, btc, fdusd];

  /// Default quote asset for the dashboard.
  static const String defaultQuote = usdt;

  /// Minimum 24h quote volume for a pair to appear in "Top gainers/losers".
  /// Without a floor, illiquid pairs with huge percentage moves dominate.
  /// Expressed in units of the quote asset (roughly USD 1M equivalent).
  /// Heuristic chosen by the app, not a Binance value.
  static double defaultMinQuoteVolume(String quote) {
    switch (quote) {
      case usdt:
      case fdusd:
        return 1000000;
      case eur:
        return 1000000;
      case btc:
        return 15;
      case eth:
        return 300;
      default:
        return 0;
    }
  }
}
