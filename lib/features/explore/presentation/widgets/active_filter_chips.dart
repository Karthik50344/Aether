import 'package:flutter/material.dart';

import '../../../../core/formatters/formatters.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/explore_query.dart';
import '../bloc/explore_state.dart';
import 'explore_labels.dart';

/// "Sort: Vol ↓", "Min Vol: >$1M", "Gainers" chips + "Showing N pairs".
/// The sort chip opens the filter sheet; the others remove their filter.
class ActiveFilterChips extends StatelessWidget {
  const ActiveFilterChips({
    required this.state,
    required this.onSortTap,
    required this.onClearMove,
    required this.onClearMinVolume,
    super.key,
  });

  final ExploreState state;
  final VoidCallback onSortTap;
  final VoidCallback onClearMove;
  final VoidCallback onClearMinVolume;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final ExploreQuery q = state.query;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: <Widget>[
            _Chip(
              label:
                  'Sort: ${ExploreLabels.sort(state.effectiveSort)} ${q.ascending ? '↑' : '↓'}',
              onTap: onSortTap,
              semantics: 'Change sort',
            ),
            if (q.minQuoteVolume > 0)
              _Chip(
                label:
                    'Min Vol: >${Fmt.quoteAmount(q.minQuoteVolume, q.quoteAsset ?? '')}',
                onClear: onClearMinVolume,
                semantics: 'Remove minimum volume filter',
              ),
            if (q.move != MoveFilter.none)
              _Chip(
                label: q.move.label,
                onClear: onClearMove,
                semantics: 'Remove ${q.move.label} filter',
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Showing ${Fmt.integer(state.results.length)} ${state.results.length == 1 ? 'pair' : 'pairs'}',
          style: AppTypography.label.copyWith(color: p.textSecondary),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.semantics,
    this.onTap,
    this.onClear,
  });

  final String label;
  final String semantics;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Semantics(
      button: true,
      label: semantics,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap ?? onClear,
        child: Container(
          constraints: const BoxConstraints(minHeight: 26),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: AppRadii.badgeRadius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(label,
                  style: AppTypography.label.copyWith(color: p.textSecondary),),
              if (onClear != null) ...<Widget>[
                const SizedBox(width: 4),
                Icon(Icons.close, size: 12, color: p.textSecondary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
