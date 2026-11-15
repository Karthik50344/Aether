import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/safe_parse.dart';

/// One entry of `GET /api/v3/ticker/24hr` (FULL response type).
/// Binance sends the numeric fields as strings.
class Ticker24hrModel {
  const Ticker24hrModel({
    required this.symbol,
    required this.priceChange,
    required this.priceChangePercent,
    required this.lastPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.volume,
    required this.quoteVolume,
    this.openPrice,
    this.weightedAvgPrice,
    this.count,
  });

  final String symbol;
  final double priceChange;
  final double priceChangePercent;
  final double lastPrice;
  final double highPrice;
  final double lowPrice;
  final double volume;
  final double quoteVolume;
  final double? openPrice;
  final double? weightedAvgPrice;
  final int? count;

  /// Returns null when a required value is missing or not a number.
  static Ticker24hrModel? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final String? symbol = parseString(json['symbol']);
    final double? priceChange = parseDouble(json['priceChange']);
    final double? percent = parseDouble(json['priceChangePercent']);
    final double? last = parseDouble(json['lastPrice']);
    final double? high = parseDouble(json['highPrice']);
    final double? low = parseDouble(json['lowPrice']);
    final double? volume = parseDouble(json['volume']);
    final double? quoteVolume = parseDouble(json['quoteVolume']);
    if (symbol == null ||
        priceChange == null ||
        percent == null ||
        last == null ||
        high == null ||
        low == null ||
        volume == null ||
        quoteVolume == null) {
      return null;
    }
    return Ticker24hrModel(
      symbol: symbol,
      priceChange: priceChange,
      priceChangePercent: percent,
      lastPrice: last,
      highPrice: high,
      lowPrice: low,
      volume: volume,
      quoteVolume: quoteVolume,
      openPrice: parseDouble(json['openPrice']),
      weightedAvgPrice: parseDouble(json['weightedAvgPrice']),
      count: parseInt(json['count']),
    );
  }

  /// Parses the array response (all symbols) or a single object (one symbol).
  /// Throws [ParseException] for any other shape; bad rows are skipped.
  static List<Ticker24hrModel> parseList(Object? json) {
    if (json is Map<String, dynamic>) {
      final Ticker24hrModel? one = tryFromJson(json);
      if (one == null) throw const ParseException('ticker/24hr: bad object.');
      return <Ticker24hrModel>[one];
    }
    if (json is! List<dynamic>) {
      throw const ParseException('ticker/24hr: expected an array.');
    }
    return <Ticker24hrModel>[
      for (final Object? item in json)
        if (Ticker24hrModel.tryFromJson(item) case final Ticker24hrModel m) m,
    ];
  }
}
