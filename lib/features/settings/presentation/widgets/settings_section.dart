import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';

/// Section label + rounded card holding rows.
class SettingsSection extends StatelessWidget {
  const SettingsSection({required this.title, required this.children, super.key});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title.toUpperCase(),
              style: AppTypography.micro.copyWith(color: p.textSecondary),),
        ),
        Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: AppRadii.cardRadius,
          ),
          child: Column(children: <Widget>[
            for (int i = 0; i < children.length; i++) ...<Widget>[
              if (i > 0) Divider(height: 1, color: p.surfaceHighest),
              children[i],
            ],
          ],),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

/// Label (+ optional hint) on the left, control on the right.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.label,
    this.hint,
    this.trailing,
    this.onTap,
    super.key,
  });
  final String label;
  final String? hint;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(label,
                      style: AppTypography.body.copyWith(color: p.textPrimary),),
                  if (hint != null)
                    Text(hint!,
                        style: AppTypography.label
                            .copyWith(color: p.textSecondary),),
                ],
              ),
            ),
            if (trailing != null) ...<Widget>[
              const SizedBox(width: 12),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact segmented selector built from typed options.
class SegmentRow<T> extends StatelessWidget {
  const SegmentRow({
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    super.key,
  });
  final List<T> options;
  final T selected;
  final String Function(T) labelOf;
  final void Function(T) onSelected;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          for (final T o in options)
            ChoiceChip(
              label: Text(labelOf(o)),
              selected: o == selected,
              onSelected: (_) => onSelected(o),
              selectedColor: p.primary,
              labelStyle: AppTypography.labelStrong.copyWith(
                color: o == selected ? p.onPrimary : p.textPrimary,
              ),
              backgroundColor: p.surfaceHigh,
              showCheckmark: false,
            ),
        ],
      ),
    );
  }
}
