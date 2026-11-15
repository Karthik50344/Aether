import 'package:flutter/material.dart';

import '../../../../core/formatters/formatters.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/watchlist_summary.dart';

/// "24h Avg Return +4.81%" | "Market Breadth 4 Up / 1 Down" (saved pairs only).
class WatchlistSummaryPill extends StatelessWidget {
  const WatchlistSummaryPill({required this.summary, super.key});
  final WatchlistSummary summary;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final Color avgColor =
        summary.averageReturn >= 0 ? p.positive : p.negativeLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadii.cardRadius,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _cell(
              p,
              '24h Avg Return',
              Fmt.percent(summary.averageReturn),
              avgColor,
              CrossAxisAlignment.start,
            ),
          ),
          Container(width: 1, height: 30, color: p.surfaceHighest),
          Expanded(
            child: _cell(
              p,
              'Market Breadth',
              '${summary.advancing} Up / ${summary.declining} Down',
              p.textPrimary,
              CrossAxisAlignment.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(AppPalette p, String label, String value, Color color,
      CrossAxisAlignment align) {
    return Column(
      crossAxisAlignment: align,
      children: <Widget>[
        Text(label,
            maxLines: 1,
            style: AppTypography.label.copyWith(color: p.textSecondary)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              maxLines: 1,
              style: AppTypography.valueMedium.copyWith(color: color)),
        ),
      ],
    );
  }
}
