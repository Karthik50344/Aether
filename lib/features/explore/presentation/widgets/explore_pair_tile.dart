import 'package:flutter/material.dart';

import '../../../../core/formatters/formatters.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/entities/trading_pair.dart';
import '../../../../shared/widgets/coin_avatar.dart';
import '../../../../shared/widgets/price_change_badge.dart';
import '../../../../shared/widgets/sparkline.dart';

/// One Explore row (Figma 358x62). Asks for its sparkline once, when first
/// built, so only rows the user actually scrolls to cost a request.
class ExplorePairTile extends StatefulWidget {
  const ExplorePairTile({
    required this.pair,
    required this.sparkline,
    required this.onNeedSparkline,
    required this.onTap,
    this.compact = true,
    super.key,
  });

  final TradingPair pair;

  /// `null` = not loaded yet; empty = unavailable.
  final List<double>? sparkline;
  final void Function(String symbol) onNeedSparkline;
  final VoidCallback onTap;
  final bool compact;

  @override
  State<ExplorePairTile> createState() => _ExplorePairTileState();
}

class _ExplorePairTileState extends State<ExplorePairTile> {
  @override
  void initState() {
    super.initState();
    if (widget.sparkline == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onNeedSparkline(widget.pair.symbol);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final TradingPair pair = widget.pair;
    return Semantics(
      button: true,
      label:
          '${pair.displayName}, price ${Fmt.price(pair.lastPrice)}, ${Fmt.percent(pair.priceChangePercent)}',
      child: Material(
        color: p.surface,
        borderRadius: AppRadii.cardRadius,
        child: InkWell(
          borderRadius: AppRadii.cardRadius,
          onTap: widget.onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 62),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: <Widget>[
                  CoinAvatar(
                    baseAsset: pair.baseAsset,
                    size: 36,
                    negative: !pair.isPositive,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text.rich(
                          TextSpan(children: <InlineSpan>[
                            TextSpan(
                              text: pair.baseAsset,
                              style: AppTypography.symbol
                                  .copyWith(color: p.textPrimary),
                            ),
                            TextSpan(
                              text: ' /${pair.quoteAsset}',
                              style: AppTypography.label
                                  .copyWith(color: p.textSecondary),
                            ),
                          ]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Vol ${Fmt.volume(pair.quoteVolume, compact: widget.compact)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.label
                              .copyWith(color: p.textSecondary, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Sparkline(
                    values: widget.sparkline ?? const <double>[],
                    positive: pair.isPositive,
                    width: 64,
                    height: 28,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            Fmt.pricedIn(pair.lastPrice, pair.quoteAsset),
                            maxLines: 1,
                            style: AppTypography.price
                                .copyWith(color: p.textPrimary),
                          ),
                        ),
                        const SizedBox(height: 2),
                        PriceChangeBadge(percent: pair.priceChangePercent),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
