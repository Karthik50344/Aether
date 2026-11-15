import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/market_state.dart';

/// Top Gainers / Top Losers / 24h Vol segmented control.
class TrendTabs extends StatelessWidget {
  const TrendTabs({required this.selected, required this.onSelected, super.key});

  final TrendKind selected;
  final ValueChanged<TrendKind> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadii.badgeRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final TrendKind k in TrendKind.all)
            Semantics(
              button: true,
              selected: k == selected,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(k),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 28),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: k == selected ? p.surfaceHigh : Colors.transparent,
                    borderRadius: AppRadii.badgeRadius,
                  ),
                  child: Text(
                    k.label,
                    maxLines: 1,
                    style: (k == selected
                            ? AppTypography.labelStrong
                            : AppTypography.label)
                        .copyWith(
                      color: k == selected ? p.primaryLight : p.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
