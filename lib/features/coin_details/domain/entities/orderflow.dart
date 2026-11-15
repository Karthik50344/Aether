import 'package:equatable/equatable.dart';

/// Taker (aggressive) activity of the latest daily candle (UTC day).
///  * [takerBuyShare]  = takerBuyBaseVolume / volume, 0..1
///  * [netQuoteFlow]   = taker-buy quote volume - taker-sell quote volume
///                     = 2 * takerBuyQuote - quoteVolume
class Orderflow extends Equatable {
  const Orderflow({required this.takerBuyShare, required this.netQuoteFlow});

  final double takerBuyShare;
  final double netQuoteFlow;

  @override
  List<Object?> get props => <Object?>[takerBuyShare, netQuoteFlow];
}
