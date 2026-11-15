import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';

/// "All Pairs | USDT | BTC | ..." scroller. [selected] null = All Pairs.
class QuoteTabs extends StatelessWidget {
  const QuoteTabs({
    required this.quotes,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<String> quotes;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final List<String?> items = <String?>[null, ...quotes];
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int i) {
          final String? q = items[i];
          final bool active = q == selected;
          final String label = q ?? 'All Pairs';
          return Semantics(
            button: true,
            selected: active,
            label: q == null ? 'All pairs' : 'Quote asset $q',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(q),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? p.primary : p.surface,
                  borderRadius: AppRadii.pillRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (active && q != null) ...<Widget>[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: p.onPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label,
                      maxLines: 1,
                      style: (active
                              ? AppTypography.labelStrong
                              : AppTypography.label)
                          .copyWith(
                        color: active ? p.onPrimary : p.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
