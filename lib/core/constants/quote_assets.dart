abstract final class QuoteAssets {
  static const String usdt = 'USDT';
  static const String btc = 'BTC';
  static const String eth = 'ETH';
  static const String fdusd = 'FDUSD';
  static const String eur = 'EUR';
  static const List<String> primary = <String>[usdt, btc, eth, fdusd, eur];
  static const List<String> dashboard = <String>[usdt, btc, fdusd];
  static const String defaultQuote = usdt;

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
