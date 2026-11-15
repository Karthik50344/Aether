import 'package:flutter/material.dart';

import '../../../../core/formatters/formatters.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/market_flow.dart';

/// "Aggregate Market Flow" card, bound to real data: a breadth bar
/// (advancing vs declining pairs) and Binance Spot volume facts.
class MarketFlowCard extends StatelessWidget {
  const MarketFlowCard({required this.flow, this.compact = true, super.key});

  final MarketFlow flow;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final String scope = flow.quoteAsset ?? 'all quotes';
    final int up = flow.advancing;
    final int down = flow.declining;
    final int rest = flow.unchanged;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadii.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(AppIcons.breadth, size: 18, color: p.primaryLight),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Market Breadth',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.symbol.copyWith(color: p.textPrimary),
                ),
              ),
              Flexible(
                child: Text(
                  scope.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.micro.copyWith(color: p.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Advancing: ${(flow.advancingShare * 100).toStringAsFixed(1)}%',
                  style: AppTypography.label.copyWith(color: p.positive),
                ),
              ),
              Text(
                'Declining: ${(flow.decliningShare * 100).toStringAsFixed(1)}%',
                style: AppTypography.label.copyWith(color: p.negative),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _BreadthBar(up: up, down: down, flat: rest),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  flow.totalQuoteVolume == null
                      ? 'Pick a quote asset for volume'
                      : 'Spot ${flow.quoteAsset} 24h Vol: ${Fmt.quoteAmount(flow.totalQuoteVolume!, flow.quoteAsset!, compact: compact)}',
                  style: AppTypography.label
                      .copyWith(color: p.textSecondary, fontSize: 10),
                ),
              ),
              if (flow.btcShare != null)
                Text(
                  'BTC share: ${(flow.btcShare! * 100).toStringAsFixed(1)}%',
                  style: AppTypography.label
                      .copyWith(color: p.textSecondary, fontSize: 10),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Binance Spot pairs only · not global market data',
            style: AppTypography.label
                .copyWith(color: p.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _BreadthBar extends StatelessWidget {
  const _BreadthBar({required this.up, required this.down, required this.flat});

  final int up;
  final int down;
  final int flat;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final int total = up + down + flat;
    return Semantics(
      label: '$up advancing, $down declining, $flat unchanged',
      child: ClipRRect(
        borderRadius: AppRadii.pillRadius,
        child: SizedBox(
          height: 6,
          child: total == 0
              ? ColoredBox(color: p.surfaceHighest)
              : Row(
                  children: <Widget>[
                    if (up > 0)
                      Expanded(flex: up, child: ColoredBox(color: p.positive)),
                    if (flat > 0)
                      Expanded(
                          flex: flat,
                          child: ColoredBox(color: p.surfaceHighest)),
                    if (down > 0)
                      Expanded(flex: down, child: ColoredBox(color: p.negative)),
                  ],
                ),
        ),
      ),
    );
  }
}
