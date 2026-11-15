import 'package:flutter/material.dart';

import '../../../../core/formatters/formatters.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/entities/trading_pair.dart';
import '../../../../shared/widgets/coin_avatar.dart';
import '../../../../shared/widgets/price_change_badge.dart';
import '../../../../shared/widgets/sparkline.dart';

/// 176-wide card in the horizontal trend scroller.
class TrendCard extends StatelessWidget {
  const TrendCard({
    required this.pair,
    required this.sparkline,
    required this.onTap,
    this.compact = true,
    super.key,
  });

  final TradingPair pair;
  final List<double> sparkline;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Semantics(
      button: true,
      label:
          '${pair.displayName}, ${Fmt.percent(pair.priceChangePercent)}, open details',
      child: Material(
        color: p.surface,
        borderRadius: AppRadii.cardRadius,
        child: InkWell(
          borderRadius: AppRadii.cardRadius,
          onTap: onTap,
          child: SizedBox(
            width: 176,
            height: 118,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      CoinAvatar(
                        baseAsset: pair.baseAsset,
                        size: 28,
                        tinted: true,
                        negative: !pair.isPositive,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
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
                      ),
                      const SizedBox(width: 4),
                      PriceChangeBadge(percent: pair.priceChangePercent),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Sparkline(
                    values: sparkline,
                    positive: pair.isPositive,
                    height: 22,
                  ),
                  const Spacer(),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          Fmt.pricedIn(pair.lastPrice, pair.quoteAsset),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.price
                              .copyWith(color: p.textPrimary),
                        ),
                      ),
                      Text(
                        Fmt.volume(pair.quoteVolume, compact: compact),
                        maxLines: 1,
                        style: AppTypography.label
                            .copyWith(color: p.textSecondary, fontSize: 10),
                      ),
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
