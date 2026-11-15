import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_typography.dart';

class FloatingNavItem {
  const FloatingNavItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

/// Blurred floating pill navigation used on drill-down screens (Figma shows
/// Market / Explore / Watchlist on the details page).
class FloatingPillNav extends StatelessWidget {
  const FloatingPillNav({required this.items, super.key});

  final List<FloatingNavItem> items;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: AppRadii.pillRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 331),
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: p.navBg,
                borderRadius: AppRadii.pillRadius,
                border: Border.all(color: p.surfaceHighest.withAlpha(120)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final FloatingNavItem item in items)
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: item.label,
                        child: InkWell(
                          borderRadius: AppRadii.pillRadius,
                          onTap: item.onTap,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(item.icon, size: 16, color: p.textSecondary),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.label
                                      .copyWith(color: p.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
