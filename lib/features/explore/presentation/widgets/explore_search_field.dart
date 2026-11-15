import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';

/// Search box (Figma 302x48). The controller is owned by the page so it can
/// also be cleared by "Reset filters".
class ExploreSearchField extends StatelessWidget {
  const ExploreSearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadii.cardRadius,
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(width: 14),
          Icon(AppIcons.search, size: 18, color: p.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              style: AppTypography.valueMedium.copyWith(color: p.textPrimary),
              cursorColor: p.primary,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintText: 'Search trading pairs (e.g. BTC)',
                hintStyle:
                    AppTypography.valueMedium.copyWith(color: p.textSecondary),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (BuildContext context, TextEditingValue v, _) {
              if (v.text.isEmpty) return const SizedBox(width: 14);
              return IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: Icon(Icons.close, size: 18, color: p.textSecondary),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 48x48 button that opens the filter sheet, with a count badge.
class FilterButton extends StatelessWidget {
  const FilterButton({required this.count, required this.onTap, super.key});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Semantics(
      button: true,
      label: count == 0 ? 'Filters' : 'Filters, $count active',
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Material(
              color: p.surface,
              borderRadius: AppRadii.cardRadius,
              child: InkWell(
                borderRadius: AppRadii.cardRadius,
                onTap: onTap,
                child: Center(
                  child: Icon(AppIcons.filter, size: 20, color: p.primaryLight),
                ),
              ),
            ),
            if (count > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration:
                      BoxDecoration(color: p.primary, shape: BoxShape.circle),
                  child: Text(
                    '$count',
                    style: AppTypography.labelStrong
                        .copyWith(color: p.onPrimary, fontSize: 10, height: 1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
