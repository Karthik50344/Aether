import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_typography.dart';

/// Builds Material 3 [ThemeData] from an [AppPalette].
/// Custom widgets read colours from the palette extension; the Material
/// colour scheme is kept consistent so stock widgets (dialogs, sheets,
/// snackbars, switches) match the design.
abstract final class AppTheme {
  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark);
  static ThemeData get light => _build(AppPalette.light, Brightness.light);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      secondary: p.primaryLight,
      onSecondary: p.onPrimary,
      error: p.negative,
      onError: p.background,
      surface: p.surface,
      onSurface: p.textPrimary,
      surfaceContainerHighest: p.surfaceHighest,
      onSurfaceVariant: p.textSecondary,
      outline: p.surfaceHighest,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      fontFamily: 'Inter',
      splashFactory: InkRipple.splashFactory,
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
            fontFamily: 'Inter',
            bodyColor: p.textPrimary,
            displayColor: p.textPrimary,
          ),
      dividerTheme: DividerThemeData(color: p.surfaceHighest, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surfaceHighest,
        contentTextStyle:
            AppTypography.body.copyWith(color: p.textPrimary),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
      ),
      extensions: <ThemeExtension<dynamic>>[p],
    );
  }
}
