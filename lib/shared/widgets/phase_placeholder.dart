import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Temporary body for screens that are built in later phases. Each page that
/// uses it is replaced by the real screen in its own phase, so this widget
/// disappears by Phase 6.
class PhasePlaceholder extends StatelessWidget {
  const PhasePlaceholder({
    required this.title,
    required this.phase,
    super.key,
  });

  final String title;
  final String phase;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              style: AppTypography.sectionTitle.copyWith(color: p.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Built in $phase',
              style: AppTypography.label.copyWith(color: p.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
