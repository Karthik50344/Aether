import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// The round user avatar in headers. The app has no accounts, so it opens
/// Settings.
class AvatarButton extends StatelessWidget {
  const AvatarButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Semantics(
      button: true,
      label: 'Open settings',
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: p.primaryLight, shape: BoxShape.circle),
          child: Icon(Icons.person, size: 16, color: p.onPrimary),
        ),
      ),
    );
  }
}
