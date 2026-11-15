import 'package:equatable/equatable.dart';

/// Aggregate statistics for ONE quote asset on Binance Spot.
///
/// How each field is computed (documented for the UI labels):
///  * [totalQuoteVolume] - sum of `quoteVolume` (24h) of every active Spot
///    pair whose quote asset is [quoteAsset]. Each pair is counted once, in its
///    own quote units, so nothing is double-counted across quotes.
///  * [quotePairCount]   - number of those pairs.
///  * [activePairCount]  - number of active Spot pairs across ALL quotes.
///  * advancing / declining / unchanged - pairs of [quoteAsset] whose 24h
///    change is > 0, < 0, or == 0.
/// These describe Binance Spot only - not the global crypto market.
class MarketOverview extends Equatable {
  const MarketOverview({
    required this.quoteAsset,
    required this.totalQuoteVolume,
    required this.quotePairCount,
    required this.activePairCount,
    required this.advancing,
    required this.declining,
    required this.unchanged,
  });

  final String quoteAsset;
  final double totalQuoteVolume;
  final int quotePairCount;
  final int activePairCount;
  final int advancing;
  final int declining;
  final int unchanged;

  /// Share of pairs with a positive 24h change, 0..1 (0 when no pairs).
  double get advancingShare =>
      quotePairCount == 0 ? 0 : advancing / quotePairCount;

  @override
  List<Object?> get props => <Object?>[
        quoteAsset,
        totalQuoteVolume,
        quotePairCount,
        activePairCount,
        advancing,
        declining,
        unchanged,
      ];
}
