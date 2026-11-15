import 'package:flutter/material.dart';

import '../../../../core/constants/asset_names.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/entities/trading_pair.dart';
import '../../../../shared/widgets/ago_text.dart';
import '../../../../shared/widgets/coin_avatar.dart';
import '../../domain/entities/orderflow.dart';

/// Pair identity, action chips, price, 24h delta and refresh time.
class PairOverview extends StatelessWidget {
  const PairOverview({
    required this.pair,
    required this.isWatched,
    required this.lastUpdated,
    required this.onToggleWatch,
    required this.onOpenWatchlist,
    required this.onShare,
    super.key,
  });

  final TradingPair pair;
  final bool isWatched;
  final DateTime? lastUpdated;
  final VoidCallback onToggleWatch;
  final VoidCallback onOpenWatchlist;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final bool up = pair.isPositive;
    final Color dir = up ? p.positive : p.negative;
    final String q = pair.quoteAsset;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            CoinAvatar(baseAsset: pair.baseAsset, size: 40, negative: !up),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          '${pair.baseAsset}/$q',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.sectionTitle
                              .copyWith(color: p.textPrimary, fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: p.surfaceHighest,
                          borderRadius: AppRadii.badgeRadius,
                        ),
                        child: Text('Spot',
                            style: AppTypography.label
                                .copyWith(color: p.primaryLight, fontSize: 10),),
                      ),
                    ],
                  ),
                  Text(
                    'Binance Spot',
                    style: AppTypography.label.copyWith(color: p.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            _ActionChip(
              icon: isWatched ? Icons.star : Icons.star_border,
              label: isWatched ? 'Pinned' : 'Pin',
              active: isWatched,
              semantics: isWatched ? 'Remove from watchlist' : 'Add to watchlist',
              onTap: onToggleWatch,
            ),
            const SizedBox(width: 8),
            _ActionChip(
              icon: Icons.arrow_forward,
              semantics: 'Open watchlist',
              onTap: onOpenWatchlist,
            ),
            const SizedBox(width: 8),
            _ActionChip(
              icon: Icons.ios_share,
              semantics: 'Copy summary',
              onTap: onShare,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 6,
          children: <Widget>[
            Text(
              Fmt.pricedIn(pair.lastPrice, q),
              style: AppTypography.heroValue
                  .copyWith(color: p.textPrimary, fontSize: 28),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: up ? p.positiveBg : p.negativeBg,
                borderRadius: AppRadii.badgeRadius,
              ),
              child: Text(
                '${Fmt.signedAmount(pair.priceChange, q)} (${Fmt.percent(pair.priceChangePercent)})',
                style: AppTypography.labelStrong.copyWith(color: dir),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                pair.weightedAvgPrice == null
                    ? 'Quote: ${AssetNames.nameOf(q)}'
                    : 'Quote: ${AssetNames.nameOf(q)} · 24h VWAP ${Fmt.pricedIn(pair.weightedAvgPrice!, q)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.label.copyWith(color: p.textSecondary),
              ),
            ),
            const SizedBox(width: 8),
            AgoText(
              since: lastUpdated,
              prefix: 'Refreshed ',
              style: AppTypography.label.copyWith(color: p.textSecondary, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.semantics,
    required this.onTap,
    this.label,
    this.active = false,
  });

  final IconData icon;
  final String? label;
  final bool active;
  final String semantics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Semantics(
      button: true,
      label: semantics,
      child: Material(
        color: p.surface,
        borderRadius: AppRadii.tileRadius,
        child: InkWell(
          borderRadius: AppRadii.tileRadius,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 18, color: active ? p.primaryLight : p.textSecondary),
                if (label != null) ...<Widget>[
                  const SizedBox(width: 6),
                  Text(label!,
                      style: AppTypography.label
                          .copyWith(color: active ? p.primaryLight : p.textPrimary),),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Taker buy share 54%" + "Net taker flow +$142.4M" strip.
class OrderflowBanner extends StatelessWidget {
  const OrderflowBanner({
    required this.flow,
    required this.quote,
    this.compact = true,
    super.key,
  });

  final Orderflow flow;
  final String quote;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final bool net = flow.netQuoteFlow >= 0;
    final String amount = Fmt.quoteAmount(flow.netQuoteFlow.abs(), quote, compact: compact);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadii.cardRadius,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: net ? p.positive : p.negative,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Taker buy share: ${(flow.takerBuyShare * 100).round()}% (UTC day)',
              style: AppTypography.label.copyWith(color: p.textPrimary),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Net taker flow ${net ? '+' : '-'}$amount',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label
                  .copyWith(color: net ? p.positive : p.negative, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
