import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';

class ProTipBanner extends StatelessWidget {
  const ProTipBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadii.cardRadius,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: p.surfaceHighest,
              borderRadius: AppRadii.tileRadius,
            ),
            child: Icon(Icons.lightbulb_outline, size: 16, color: p.primaryLight),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(children: <InlineSpan>[
                TextSpan(
                  text: 'Pro-tip: ',
                  style: AppTypography.labelStrong.copyWith(color: p.textPrimary),
                ),
                TextSpan(
                  text:
                      'Search a pair like BTCUSDT or a name like "bitcoin", or switch the quote asset tabs to explore other markets.',
                  style: AppTypography.label.copyWith(color: p.textSecondary),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
