import 'package:flutter/material.dart';

import '../../core/formatters/formatters.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_typography.dart';

/// "+3.42%" pill: green when >= 0, red when negative (as in Figma).
class PriceChangeBadge extends StatelessWidget {
  const PriceChangeBadge({required this.percent, super.key});

  final double percent;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final bool up = percent >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: up ? p.positiveBg : p.negativeBg,
        borderRadius: AppRadii.badgeRadius,
      ),
      child: Text(
        Fmt.percent(percent),
        maxLines: 1,
        style: AppTypography.labelStrong
            .copyWith(color: up ? p.positive : p.negative),
      ),
    );
  }
}
