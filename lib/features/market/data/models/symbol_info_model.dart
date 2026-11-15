import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/safe_parse.dart';

/// One entry of `GET /api/v3/exchangeInfo` -> `symbols[]`.
/// Only the fields the app needs are read.
class SymbolInfoModel {
  const SymbolInfoModel({
    required this.symbol,
    required this.status,
    required this.baseAsset,
    required this.quoteAsset,
    required this.isSpotTradingAllowed,
  });

  final String symbol;

  /// e.g. `TRADING`, `BREAK`.
  final String status;
  final String baseAsset;
  final String quoteAsset;
  final bool isSpotTradingAllowed;

  /// Eligible to show: currently trading AND allowed on the Spot market.
  bool get isActiveSpot => status == 'TRADING' && isSpotTradingAllowed;

  /// Returns null when a required field is missing (row is skipped).
  static SymbolInfoModel? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final String? symbol = parseString(json['symbol']);
    final String? status = parseString(json['status']);
    final String? base = parseString(json['baseAsset']);
    final String? quote = parseString(json['quoteAsset']);
    final Object? spot = json['isSpotTradingAllowed'];
    if (symbol == null || status == null || base == null || quote == null) {
      return null;
    }
    return SymbolInfoModel(
      symbol: symbol,
      status: status,
      baseAsset: base,
      quoteAsset: quote,
      isSpotTradingAllowed: spot is bool && spot,
    );
  }

  /// Parses the whole `exchangeInfo` response body.
  /// Throws [ParseException] when `symbols` is missing; malformed individual
  /// symbols are skipped.
  static List<SymbolInfoModel> parseExchangeInfo(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const ParseException('exchangeInfo: expected a JSON object.');
    }
    final Object? symbols = json['symbols'];
    if (symbols is! List<dynamic>) {
      throw const ParseException('exchangeInfo: "symbols" is missing.');
    }
    return <SymbolInfoModel>[
      for (final Object? item in symbols)
        if (SymbolInfoModel.tryFromJson(item) case final SymbolInfoModel m) m,
    ];
  }
}
