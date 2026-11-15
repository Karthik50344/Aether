import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'aether_logo.dart';
import 'avatar_button.dart';

/// Top bar shown on the four tab screens (Figma "Header", 64 px).
///
/// Left : "Aether" wordmark + small uppercase section label (MARKET, ...).
/// Right: search button (opens Explore) and avatar (opens Settings).
/// The bell from the design is intentionally omitted - the app has no
/// notification feature (approved decision in PHASE0_SPEC section 9).
class AetherHeader extends StatelessWidget {
  const AetherHeader({
    required this.sectionLabel,
    required this.onSearchTap,
    required this.onAvatarTap,
    super.key,
  });

  final String sectionLabel;
  final VoidCallback onSearchTap;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Material(
      color: p.headerBg,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: AppSpacing.headerHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Row(
              children: <Widget>[
                const AetherLogo(size: 28, tile: true),
                const SizedBox(width: AppSpacing.md),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Aether',
                      style: AppTypography.headerTitle
                          .copyWith(color: p.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    // Figma wraps long labels (WATCHL/IST) - a design bug.
                    // Force a single line instead.
                    Text(
                      sectionLabel.toUpperCase(),
                      maxLines: 1,
                      softWrap: false,
                      style: AppTypography.micro.copyWith(
                        color: p.textSecondary,
                        height: 11 / 11,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _HeaderIconButton(
                  tooltip: 'Search trading pairs',
                  icon: Icons.search,
                  onTap: onSearchTap,
                ),
                const SizedBox(width: AppSpacing.md),
                AvatarButton(onTap: onAvatarTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return SizedBox(
      width: AppSpacing.touchTarget,
      height: AppSpacing.touchTarget,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        iconSize: 18,
        color: p.textSecondary,
        icon: Icon(icon),
      ),
    );
  }
}
