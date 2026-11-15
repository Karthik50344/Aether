import 'package:flutter/material.dart';

import '../../../../core/formatters/formatters.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/entities/trading_pair.dart';
import '../../domain/entities/pair_stats.dart';

/// 2 x 3 grid of "24H Market Statistics". Every caption is a fact derived from
/// Binance data (no editorial text like "Strong support floor").
class StatGrid extends StatelessWidget {
  const StatGrid({
    required this.pair,
    required this.stats,
    this.compact = true,
    super.key,
  });

  final TradingPair pair;
  final PairStats stats;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final String q = pair.quoteAsset;
    final double? vs = stats.volumeVs7dAvgPercent;
    final bool up = stats.priceChange >= 0;

    final List<_Stat> tiles = <_Stat>[
      _Stat(
        label: '24h High',
        value: Fmt.pricedIn(stats.high, q),
        caption: '${Fmt.percent(stats.fromHighPercent)} from high',
        captionColor: p.textSecondary,
      ),
      _Stat(
        label: '24h Low',
        value: Fmt.pricedIn(stats.low, q),
        caption: '${Fmt.percent(stats.aboveLowPercent)} above low',
        captionColor: p.textSecondary,
      ),
      _Stat(
        label: 'Base Volume (${pair.baseAsset})',
        value: '${Fmt.volume(stats.baseVolume, compact: compact)} ${pair.baseAsset}',
        caption: vs == null ? '24h rolling' : '${Fmt.percent(vs)} vs 7D avg',
        captionColor: vs == null ? p.textSecondary : (vs >= 0 ? p.positive : p.negative),
      ),
      _Stat(
        label: 'Quote Volume ($q)',
        value: Fmt.quoteAmount(stats.quoteVolume, q, compact: compact),
        caption: stats.vwap == null ? '24h rolling' : 'VWAP ${Fmt.pricedIn(stats.vwap!, q)}',
        captionColor: p.primaryLight,
      ),
      _Stat(
        label: '24h Price Change',
        value: Fmt.signedAmount(stats.priceChange, q),
        valueColor: up ? p.positive : p.negative,
        caption: Fmt.percent(stats.priceChangePercent),
        captionColor: up ? p.positive : p.negative,
      ),
      _Stat(
        label: 'Matched Trades',
        value: stats.tradeCount == null ? '--' : Fmt.integer(stats.tradeCount!),
        caption: stats.tradesPerSecond == null
            ? '24h rolling'
            : '${stats.tradesPerSecond!.toStringAsFixed(1)} avg trades/sec',
        captionColor: p.textSecondary,
      ),
    ];

    return Column(
      children: <Widget>[
        for (int row = 0; row < tiles.length; row += 2) ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(child: _Tile(stat: tiles[row])),
              const SizedBox(width: 4),
              Expanded(child: _Tile(stat: tiles[row + 1])),
            ],
          ),
          if (row + 2 < tiles.length) const SizedBox(height: 4),
        ],
      ],
    );
  }
}

class _Stat {
  const _Stat({
    required this.label,
    required this.value,
    required this.caption,
    required this.captionColor,
    this.valueColor,
  });

  final String label;
  final String value;
  final String caption;
  final Color captionColor;
  final Color? valueColor;
}

class _Tile extends StatelessWidget {
  const _Tile({required this.stat});
  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadii.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              stat.value,
              maxLines: 1,
              style: AppTypography.price
                  .copyWith(color: stat.valueColor ?? p.textPrimary, fontSize: 14),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label.copyWith(color: stat.captionColor, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
