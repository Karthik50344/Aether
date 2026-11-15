import 'package:equatable/equatable.dart';

/// Breadth and volume summary of the pairs currently loaded (Binance Spot
/// only). Replaces the design's "Net inflow / Bids vs Asks / Global volume /
/// Dominance", none of which Binance's public endpoints provide.
///
///  * [advancing]/[declining]/[unchanged]: pairs by sign of 24h change.
///  * [totalQuoteVolume]: sum of 24h quote volume - only meaningful for ONE
///    quote asset, so it is `null` when [quoteAsset] is `null` (All Pairs).
///  * [baseShare]: 24h quote volume of the pair `BTC/<quote>` divided by
///    [totalQuoteVolume] (the "BTC share of <quote> volume"), `null` when
///    unknown or when the quote is BTC itself.
class MarketFlow extends Equatable {
  const MarketFlow({
    required this.quoteAsset,
    required this.advancing,
    required this.declining,
    required this.unchanged,
    this.totalQuoteVolume,
    this.btcShare,
  });

  final String? quoteAsset;
  final int advancing;
  final int declining;
  final int unchanged;
  final double? totalQuoteVolume;
  final double? btcShare;

  int get total => advancing + declining + unchanged;

  /// Advancing share of ALL pairs, 0..1 (0 when empty).
  double get advancingShare => total == 0 ? 0 : advancing / total;

  /// Declining share of ALL pairs, 0..1 (0 when empty).
  double get decliningShare => total == 0 ? 0 : declining / total;

  @override
  List<Object?> get props => <Object?>[
        quoteAsset,
        advancing,
        declining,
        unchanged,
        totalQuoteVolume,
        btcShare,
      ];
}
