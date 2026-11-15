import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';

/// "● CONNECTED · 24ms" pill on the left, data-source label on the right.
class StatusStrip extends StatelessWidget {
  const StatusStrip({
    required this.latency,
    required this.stale,
    required this.sourceLabel,
    super.key,
  });

  final Duration? latency;

  /// The latest refresh failed; older data is on screen.
  final bool stale;
  final String sourceLabel;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final Color dot = stale ? p.negative : p.positive;
    final String text = stale
        ? 'OFFLINE · SHOWING LAST DATA'
        : latency == null
            ? 'CONNECTED'
            : 'CONNECTED · ${latency!.inMilliseconds}ms';
    return Row(
      children: <Widget>[
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: AppRadii.pillRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.micro
                        .copyWith(color: p.textSecondary, letterSpacing: 0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          sourceLabel,
          maxLines: 1,
          style: AppTypography.micro.copyWith(color: p.textSecondary),
        ),
        const SizedBox(width: 4),
        Icon(
          stale ? AppIcons.offline : AppIcons.signal,
          size: 14,
          color: p.textSecondary,
        ),
      ],
    );
  }
}
