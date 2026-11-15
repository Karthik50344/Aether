import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/safe_parse.dart';
import '../../../../shared/domain/entities/candlestick.dart';

/// One kline row of `GET /api/v3/klines`.
///
/// Binance returns each candle as a POSITIONAL array:
/// ```
/// [0] open time (ms)        [1] open       [2] high     [3] low     [4] close
/// [5] volume (base)         [6] close time (ms)
/// [7] quote asset volume    [8] number of trades
/// [9] taker buy base volume [10] taker buy quote volume  [11] ignore
/// ```
class KlineModel {
  const KlineModel({
    required this.openTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.closeTime,
    required this.quoteAssetVolume,
    this.numberOfTrades,
    this.takerBuyBaseVolume,
    this.takerBuyQuoteVolume,
  });

  final DateTime openTime;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final DateTime closeTime;
  final double quoteAssetVolume;
  final int? numberOfTrades;
  final double? takerBuyBaseVolume;
  final double? takerBuyQuoteVolume;

  /// Returns null if the row is too short or a core value is not parseable.
  static KlineModel? tryFromList(Object? row) {
    if (row is! List<dynamic> || row.length < 8) return null;
    final DateTime? openTime = parseEpochMillis(row[0]);
    final double? open = parseDouble(row[1]);
    final double? high = parseDouble(row[2]);
    final double? low = parseDouble(row[3]);
    final double? close = parseDouble(row[4]);
    final double? volume = parseDouble(row[5]);
    final DateTime? closeTime = parseEpochMillis(row[6]);
    final double? quoteVolume = parseDouble(row[7]);
    if (openTime == null ||
        open == null ||
        high == null ||
        low == null ||
        close == null ||
        volume == null ||
        closeTime == null ||
        quoteVolume == null) {
      return null;
    }
    return KlineModel(
      openTime: openTime,
      open: open,
      high: high,
      low: low,
      close: close,
      volume: volume,
      closeTime: closeTime,
      quoteAssetVolume: quoteVolume,
      numberOfTrades: row.length > 8 ? parseInt(row[8]) : null,
      takerBuyBaseVolume: row.length > 9 ? parseDouble(row[9]) : null,
      takerBuyQuoteVolume: row.length > 10 ? parseDouble(row[10]) : null,
    );
  }

  /// Parses the whole response. Throws [ParseException] if it is not an
  /// array; malformed rows are skipped.
  static List<KlineModel> parseList(Object? json) {
    if (json is! List<dynamic>) {
      throw const ParseException('klines: expected an array.');
    }
    return <KlineModel>[
      for (final Object? row in json)
        if (KlineModel.tryFromList(row) case final KlineModel m) m,
    ];
  }

  Candlestick toEntity() => Candlestick(
        openTime: openTime,
        open: open,
        high: high,
        low: low,
        close: close,
        volume: volume,
        closeTime: closeTime,
        quoteAssetVolume: quoteAssetVolume,
        numberOfTrades: numberOfTrades,
        takerBuyBaseVolume: takerBuyBaseVolume,
        takerBuyQuoteVolume: takerBuyQuoteVolume,
      );
}
