import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/safe_parse.dart';
import '../../../../shared/domain/entities/recent_trade.dart';

/// One entry of `GET /api/v3/trades`:
/// `{id, price, qty, quoteQty, time, isBuyerMaker, isBestMatch}`.
class RecentTradeModel {
  const RecentTradeModel({
    required this.id,
    required this.price,
    required this.qty,
    required this.quoteQty,
    required this.time,
    required this.isBuyerMaker,
  });

  final int id;
  final double price;
  final double qty;
  final double quoteQty;
  final DateTime time;
  final bool isBuyerMaker;

  static RecentTradeModel? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final int? id = parseInt(json['id']);
    final double? price = parseDouble(json['price']);
    final double? qty = parseDouble(json['qty']);
    final DateTime? time = parseEpochMillis(json['time']);
    final Object? maker = json['isBuyerMaker'];
    if (id == null || price == null || qty == null || time == null) {
      return null;
    }
    if (maker is! bool) return null;
    return RecentTradeModel(
      id: id,
      price: price,
      qty: qty,
      // quoteQty is documented, but fall back to price * qty if absent.
      quoteQty: parseDouble(json['quoteQty']) ?? price * qty,
      time: time,
      isBuyerMaker: maker,
    );
  }

  static List<RecentTradeModel> parseList(Object? json) {
    if (json is! List<dynamic>) {
      throw const ParseException('trades: expected an array.');
    }
    return <RecentTradeModel>[
      for (final Object? item in json)
        if (RecentTradeModel.tryFromJson(item) case final RecentTradeModel m) m,
    ];
  }

  RecentTrade toEntity() => RecentTrade(
        id: id,
        price: price,
        quantity: qty,
        quoteQuantity: quoteQty,
        time: time,
        isBuyerMaker: isBuyerMaker,
      );
}
