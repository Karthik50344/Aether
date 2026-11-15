import 'package:flutter/material.dart';

import '../../../../core/constants/sectors.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';

/// Horizontally scrolling sector chips. Sectors are APP-CURATED (Binance has
/// no category data); the chip counts are pairs of the selected quote asset.
class SectorChips extends StatelessWidget {
  const SectorChips({
    required this.selected,
    required this.counts,
    required this.onSelected,
    super.key,
  });

  final Sector selected;
  final Map<String, int> counts;
  final ValueChanged<Sector> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return SizedBox(
      height: 26,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: Sector.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int i) {
          final Sector s = Sector.values[i];
          final bool active = s == selected;
          final String label = identical(s, Sector.all)
              ? 'All (${Fmt.integer(counts[s.id] ?? 0)})'
              : s.label;
          return Semantics(
            button: true,
            selected: active,
            label: 'Sector ${s.label}',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? p.primary : p.surface,
                  borderRadius: AppRadii.pillRadius,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  style: (active ? AppTypography.labelStrong : AppTypography.label)
                      .copyWith(color: active ? p.onPrimary : p.textSecondary),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
