import 'package:flutter/material.dart';

import '../../../../core/formatters/formatters.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/entities/order_book_depth.dart';

/// Bid vs ask notional of the returned order-book levels (top N per side).
class DepthMeter extends StatelessWidget {
  const DepthMeter({
    required this.depth,
    required this.quote,
    this.levels = 100,
    this.compact = true,
    super.key,
  });

  final OrderBookDepth depth;
  final String quote;
  final int levels;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final double bidShare = depth.bidShare;
    final int bidPct = (bidShare * 100).round();
    final int askPct = 100 - bidPct;
    final int bidFlex = (bidShare * 1000).round().clamp(1, 999);
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
              Expanded(
                child: Text(
                  'Bid Depth: $bidPct% (${Fmt.quoteAmount(depth.bidNotional, quote, compact: compact)})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label.copyWith(color: p.positive),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Ask Depth: $askPct% (${Fmt.quoteAmount(depth.askNotional, quote, compact: compact)})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTypography.label.copyWith(color: p.negative),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Bids $bidPct percent, asks $askPct percent',
            child: ClipRRect(
              borderRadius: AppRadii.pillRadius,
              child: SizedBox(
                height: 8,
                child: Row(
                  children: <Widget>[
                    Expanded(flex: bidFlex, child: ColoredBox(color: p.positive)),
                    Expanded(flex: 1000 - bidFlex, child: ColoredBox(color: p.negative)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Order book snapshot · top $levels levels per side',
            style: AppTypography.label.copyWith(color: p.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
