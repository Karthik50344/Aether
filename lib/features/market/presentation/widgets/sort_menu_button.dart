import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../explore/domain/entities/explore_query.dart';

/// "Vol 24h ↓" dropdown. Picking the active field flips the direction.
class SortMenuButton extends StatelessWidget {
  const SortMenuButton({
    required this.field,
    required this.ascending,
    required this.onChanged,
    super.key,
  });

  final SortField field;
  final bool ascending;
  final void Function(SortField field, bool ascending) onChanged;

  static String shortLabel(SortField f) {
    if (f == SortField.volume) return 'Vol 24h';
    if (f == SortField.price) return 'Price';
    if (f == SortField.change) return '24h Chg';
    return 'Name';
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return PopupMenuButton<SortField>(
      tooltip: 'Sort markets',
      color: p.surfaceHigh,
      position: PopupMenuPosition.under,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.cardRadius),
      onSelected: (SortField f) {
        // Same field -> flip direction. New field -> sensible default
        // (name ascending, everything else descending).
        if (f == field) {
          onChanged(f, !ascending);
        } else {
          onChanged(f, f == SortField.name);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<SortField>>[
        for (final SortField f in SortField.all)
          PopupMenuItem<SortField>(
            value: f,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    shortLabel(f),
                    style: AppTypography.label.copyWith(
                      color: f == field ? p.primaryLight : p.textPrimary,
                    ),
                  ),
                ),
                if (f == field)
                  Icon(
                    ascending ? AppIcons.sortUp : AppIcons.sortDown,
                    size: 14,
                    color: p.primaryLight,
                  ),
              ],
            ),
          ),
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: AppRadii.badgeRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              shortLabel(field),
              style: AppTypography.label.copyWith(color: p.textSecondary),
            ),
            const SizedBox(width: 2),
            Icon(
              ascending ? AppIcons.sortUp : AppIcons.sortDown,
              size: 12,
              color: p.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
