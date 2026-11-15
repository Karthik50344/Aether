import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';

/// Pill switcher (USDT / BTC / FDUSD) on the overview card.
class QuoteAssetSwitcher extends StatelessWidget {
  const QuoteAssetSwitcher({
    required this.quotes,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<String> quotes;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: p.surfaceHighest,
        borderRadius: AppRadii.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final String q in quotes)
            Semantics(
              button: true,
              selected: q == selected,
              label: 'Show $q pairs',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(q),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 28, minWidth: 44),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: q == selected ? p.primary : Colors.transparent,
                    borderRadius: AppRadii.pillRadius,
                  ),
                  child: Text(
                    q,
                    style: (q == selected
                            ? AppTypography.labelStrong
                            : AppTypography.label)
                        .copyWith(
                      color: q == selected ? p.onPrimary : p.textSecondary,
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
