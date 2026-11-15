import 'package:flutter/material.dart';

import '../../../../core/formatters/formatters.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/entities/trading_pair.dart';
import '../../../../shared/widgets/coin_avatar.dart';
import '../../../../shared/widgets/price_change_badge.dart';

/// One row of the "Spot Markets" list (358 x 64 in Figma).
class SpotMarketTile extends StatelessWidget {
  const SpotMarketTile({
    required this.pair,
    required this.onTap,
    this.compact = true,
    super.key,
  });

  final TradingPair pair;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Semantics(
      button: true,
      label:
          '${pair.displayName}, price ${Fmt.price(pair.lastPrice)}, ${Fmt.percent(pair.priceChangePercent)}',
      child: Material(
        color: p.surface,
        borderRadius: AppRadii.cardRadius,
        child: InkWell(
          borderRadius: AppRadii.cardRadius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: <Widget>[
                  CoinAvatar(
                    baseAsset: pair.baseAsset,
                    negative: !pair.isPositive,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
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
                          ],),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Vol ${Fmt.quoteAmount(pair.quoteVolume, pair.quoteAsset, compact: compact)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.label
                              .copyWith(color: p.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        Fmt.pricedIn(pair.lastPrice, pair.quoteAsset),
                        maxLines: 1,
                        style:
                            AppTypography.price.copyWith(color: p.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      PriceChangeBadge(percent: pair.priceChangePercent),
                    ],
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
