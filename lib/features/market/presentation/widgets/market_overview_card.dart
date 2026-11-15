import 'package:flutter/material.dart';

import '../../../../core/formatters/formatters.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/market_overview.dart';
import 'quote_asset_switcher.dart';

/// Hero card. Every figure is computed from the loaded Binance Spot pairs of
/// the selected quote asset (see [MarketOverview] for the exact formulas).
class MarketOverviewCard extends StatelessWidget {
  const MarketOverviewCard({
    required this.overview,
    required this.quotes,
    required this.onQuoteSelected,
    this.compact = true,
    super.key,
  });

  final MarketOverview overview;
  final List<String> quotes;
  final ValueChanged<String> onQuoteSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final double share = overview.advancingShare * 100;
    final bool mostlyUp = share >= 50;
    return ClipRRect(
      borderRadius: AppRadii.cardRadius,
      child: Stack(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: AppRadii.cardRadius,
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 15,
                  offset: Offset(0, 10),
                  spreadRadius: -3,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'BINANCE SPOT RESEARCH',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.micro
                            .copyWith(color: p.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    QuoteAssetSwitcher(
                      quotes: quotes,
                      selected: overview.quoteAsset,
                      onSelected: onQuoteSelected,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '24H ${overview.quoteAsset} PAIR VOLUME',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.micro
                      .copyWith(color: p.textSecondary, letterSpacing: 0.275),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: <Widget>[
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          Fmt.quoteAmount(overview.totalQuoteVolume,
                              overview.quoteAsset,
                              compact: compact),
                          style: AppTypography.heroValue
                              .copyWith(color: p.textPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Replaces the invented "+5.18%" volume delta.
                    Text(
                      '${mostlyUp ? '▲' : '▼'} ${share.round()}% advancing',
                      maxLines: 1,
                      style: AppTypography.valueMedium.copyWith(
                          color: mostlyUp ? p.positive : p.negative),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _MetricTile(
                        label: 'ACTIVE PAIRS',
                        value: Fmt.integer(overview.quotePairCount),
                        caption: 'of ${Fmt.integer(overview.activePairCount)} listed',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricTile(
                        label: 'ADVANCING',
                        value: '${share.toStringAsFixed(1)}%',
                        caption:
                            '${Fmt.integer(overview.advancing)} up · ${Fmt.integer(overview.declining)} down',
                        valueColor: mostlyUp ? p.positive : p.negative,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: -48,
            right: -48,
            child: IgnorePointer(
              child: Container(
                width: 176,
                height: 176,
                decoration: BoxDecoration(color: p.glow, shape: BoxShape.circle),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.caption,
    this.valueColor,
  });

  final String label;
  final String value;
  final String caption;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: p.surfaceHigh.withAlpha(178),
        borderRadius: AppRadii.tileRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.micro
                  .copyWith(color: p.textSecondary, letterSpacing: 0.3)),
          const SizedBox(height: 2),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.price
                  .copyWith(color: valueColor ?? p.textPrimary)),
          Text(caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label
                  .copyWith(color: p.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }
}

/// Small explanatory note used under the card (also exercised by tests).
class OverviewFootnote extends StatelessWidget {
  const OverviewFootnote({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Row(
      children: <Widget>[
        Icon(AppIcons.info, size: 12, color: p.textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'Binance Spot only · not global market data',
            style: AppTypography.label.copyWith(color: p.textSecondary, fontSize: 10),
          ),
        ),
      ],
    );
  }
}
