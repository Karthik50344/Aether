import 'package:equatable/equatable.dart';

/// A recent public trade (Binance `GET /api/v3/trades`).
class RecentTrade extends Equatable {
  const RecentTrade({
    required this.id,
    required this.price,
    required this.quantity,
    required this.quoteQuantity,
    required this.time,
    required this.isBuyerMaker,
  });

  final int id;
  final double price;

  /// Base-asset quantity.
  final double quantity;
  final double quoteQuantity;

  /// UTC.
  final DateTime time;

  /// Binance semantics: `true` means the BUYER was the resting (maker) order,
  /// so the aggressor (taker) was a seller.
  final bool isBuyerMaker;

  /// Aggressor side: a market buy hits a resting sell, so `isBuyerMaker=false`.
  bool get isTakerBuy => !isBuyerMaker;

  @override
  List<Object?> get props =>
      <Object?>[id, price, quantity, quoteQuantity, time, isBuyerMaker];
}
