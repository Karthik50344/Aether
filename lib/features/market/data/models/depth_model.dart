import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/safe_parse.dart';
import '../../../../shared/domain/entities/order_book_depth.dart';

/// `GET /api/v3/depth` response:
/// `{lastUpdateId, bids: [[price, qty], ...], asks: [[price, qty], ...]}`.
class DepthModel {
  const DepthModel({
    required this.lastUpdateId,
    required this.bids,
    required this.asks,
  });

  final int lastUpdateId;
  final List<DepthLevel> bids;
  final List<DepthLevel> asks;

  static DepthModel parse(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const ParseException('depth: expected a JSON object.');
    }
    final int? updateId = parseInt(json['lastUpdateId']);
    if (updateId == null) {
      throw const ParseException('depth: "lastUpdateId" is missing.');
    }
    return DepthModel(
      lastUpdateId: updateId,
      bids: _levels(json['bids'], 'bids'),
      asks: _levels(json['asks'], 'asks'),
    );
  }

  static List<DepthLevel> _levels(Object? raw, String name) {
    if (raw is! List<dynamic>) {
      throw ParseException('depth: "$name" is missing.');
    }
    final List<DepthLevel> out = <DepthLevel>[];
    for (final Object? entry in raw) {
      if (entry is List<dynamic> && entry.length >= 2) {
        final double? price = parseDouble(entry[0]);
        final double? qty = parseDouble(entry[1]);
        if (price != null && qty != null) {
          out.add(DepthLevel(price: price, quantity: qty));
        }
      }
    }
    return out;
  }

  OrderBookDepth toEntity() => OrderBookDepth(
        lastUpdateId: lastUpdateId,
        bids: bids,
        asks: asks,
      );
}
