import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/explore_query.dart';

/// MARKET / VOLUME  ·  TREND (24H)  ·  LAST PRICE. Volume and price headers
/// sort the list (tap again to flip direction).
class MarketTableHeader extends StatelessWidget {
  const MarketTableHeader({
    required this.sortField,
    required this.ascending,
    required this.onSort,
    super.key,
  });

  final SortField sortField;
  final bool ascending;
  final ValueChanged<SortField> onSort;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    TextStyle style(bool active) => AppTypography.micro
        .copyWith(color: active ? p.primaryLight : p.textSecondary, fontSize: 10);

    Widget sortable(String label, SortField f) {
      final bool active = sortField == f;
      return Semantics(
        button: true,
        label: 'Sort by $label',
        child: InkWell(
          onTap: () => onSort(f),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 32),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(label, style: style(active)),
                const SizedBox(width: 2),
                Icon(
                  active
                      ? (ascending ? AppIcons.triangleUp : AppIcons.triangleDown)
                      : Icons.unfold_more,
                  size: active ? 18 : 12,
                  color: active ? p.primaryLight : p.textSecondary,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: <Widget>[
          Expanded(child: sortable('MARKET / VOLUME', SortField.volume)),
          Text('TREND (24H)', style: style(false)),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: sortable('LAST PRICE', SortField.price),
            ),
          ),
        ],
      ),
    );
  }
}
