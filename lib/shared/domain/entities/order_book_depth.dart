import 'package:equatable/equatable.dart';

/// One price level of the order book.
class DepthLevel extends Equatable {
  const DepthLevel({required this.price, required this.quantity});

  final double price;

  /// Base-asset quantity resting at [price].
  final double quantity;

  /// Value of this level in quote units.
  double get notional => price * quantity;

  @override
  List<Object?> get props => <Object?>[price, quantity];
}

/// Order-book snapshot (Binance `GET /api/v3/depth`), limited to the levels
/// that were requested - NOT the whole book.
class OrderBookDepth extends Equatable {
  const OrderBookDepth({
    required this.lastUpdateId,
    required this.bids,
    required this.asks,
  });

  final int lastUpdateId;
  final List<DepthLevel> bids;
  final List<DepthLevel> asks;

  /// Sum of bid notional over the returned levels (quote units).
  double get bidNotional =>
      bids.fold<double>(0, (double sum, DepthLevel l) => sum + l.notional);

  /// Sum of ask notional over the returned levels (quote units).
  double get askNotional =>
      asks.fold<double>(0, (double sum, DepthLevel l) => sum + l.notional);

  /// Bid share of total returned depth, 0..1 (0.5 when both sides are empty).
  double get bidShare {
    final double total = bidNotional + askNotional;
    return total == 0 ? 0.5 : bidNotional / total;
  }

  @override
  List<Object?> get props => <Object?>[lastUpdateId, bids, asks];
}
