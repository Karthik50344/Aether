import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/injection.dart';
import '../../app/router/route_names.dart';
import '../ui/search_focus_signal.dart';
import '../../core/theme/app_spacing.dart';
import 'aether_bottom_nav.dart';
import 'aether_header.dart';

/// Frame around the four tab screens: header on top, tab content in the
/// middle (centred and width-capped on tablets), bottom navigation below.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const List<AetherNavItem> _items = <AetherNavItem>[
    AetherNavItem(
      label: 'Market',
      icon: Icons.trending_up,
      activeIcon: Icons.trending_up,
    ),
    AetherNavItem(
      label: 'Explore',
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
    ),
    AetherNavItem(
      label: 'Watchlist',
      icon: Icons.star_border,
      activeIcon: Icons.star,
    ),
    AetherNavItem(
      label: 'Settings',
      icon: Icons.tune,
      activeIcon: Icons.tune,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final int index = navigationShell.currentIndex;
    return Scaffold(
      body: Column(
        children: <Widget>[
          AetherHeader(
            sectionLabel: _items[index].label,
            onSearchTap: () {
              sl<SearchFocusSignal>().request();
              context.go(RoutePaths.explore);
            },
            onAvatarTap: () => context.go(RoutePaths.settings),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.maxContentWidth,
                ),
                child: navigationShell,
              ),
            ),
          ),
          AetherBottomNav(
            items: _items,
            currentIndex: index,
            onTap: (int i) => navigationShell.goBranch(
              i,
              // Tapping the active tab returns it to its root route.
              initialLocation: i == navigationShell.currentIndex,
            ),
          ),
        ],
      ),
    );
  }
}
