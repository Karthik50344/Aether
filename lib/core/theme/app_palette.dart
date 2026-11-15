import 'package:flutter/material.dart';

/// Semantic colour set for the whole app, attached to [ThemeData] as a
/// [ThemeExtension]. Widgets read it with `context.palette`.
///
/// [AppPalette.dark] is taken 1:1 from Figma (see DESIGN_TOKENS.md).
/// [AppPalette.light] is DERIVED by us from the same roles - Figma has no
/// light design. Assumption documented in README.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.surfaceHighest,
    required this.primary,
    required this.primaryLight,
    required this.onPrimary,
    required this.positive,
    required this.positiveBg,
    required this.negative,
    required this.negativeLight,
    required this.negativeBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.headerBg,
    required this.navBg,
    required this.glow,
    required this.shadow,
  });

  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color surfaceHighest;
  final Color primary;
  final Color primaryLight;
  final Color onPrimary;
  final Color positive;
  final Color positiveBg;
  final Color negative;
  final Color negativeLight;
  final Color negativeBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color headerBg;
  final Color navBg;
  final Color glow;
  final Color shadow;

  /// Figma "Market Dashboard" tokens.
  static const AppPalette dark = AppPalette(
    background: Color(0xFF0D131E),
    surface: Color(0xFF1A202B),
    surfaceHigh: Color(0xFF242A36),
    surfaceHighest: Color(0xFF2F3541),
    primary: Color(0xFF8B9CFF),
    primaryLight: Color(0xFFBAC3FF),
    onPrimary: Color(0xFF1B2E8D),
    positive: Color(0xFF44DFAB),
    positiveBg: Color(0x3300BF8E), // rgba(0,191,142,0.20)
    negative: Color(0xFFFF788A),
    negativeLight: Color(0xFFFFB2B9),
    negativeBg: Color(0x33FF788A), // rgba(255,120,138,0.20)
    textPrimary: Color(0xFFDDE2F2),
    textSecondary: Color(0xFFC5C5D4),
    headerBg: Color(0xD90D131E), // 85 %
    navBg: Color(0xF2161C27), // 95 %
    glow: Color(0x1ABAC3FF), // 10 %
    shadow: Color(0x4D000000),
  );

  /// Derived light palette (not in Figma).
  static const AppPalette light = AppPalette(
    background: Color(0xFFF5F6FB),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFEEF0F8),
    surfaceHighest: Color(0xFFE2E6F3),
    primary: Color(0xFF4A5BE0),
    primaryLight: Color(0xFF3F4EC4),
    onPrimary: Color(0xFFFFFFFF),
    positive: Color(0xFF00835F),
    positiveBg: Color(0x2600BF8E),
    negative: Color(0xFFD2314A),
    negativeLight: Color(0xFFC23A52),
    negativeBg: Color(0x26FF788A),
    textPrimary: Color(0xFF141A2A),
    textSecondary: Color(0xFF59607A),
    headerBg: Color(0xD9F5F6FB),
    navBg: Color(0xF2FFFFFF),
    glow: Color(0x1A4A5BE0),
    shadow: Color(0x1A000000),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceHigh,
    Color? surfaceHighest,
    Color? primary,
    Color? primaryLight,
    Color? onPrimary,
    Color? positive,
    Color? positiveBg,
    Color? negative,
    Color? negativeLight,
    Color? negativeBg,
    Color? textPrimary,
    Color? textSecondary,
    Color? headerBg,
    Color? navBg,
    Color? glow,
    Color? shadow,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      surfaceHighest: surfaceHighest ?? this.surfaceHighest,
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      onPrimary: onPrimary ?? this.onPrimary,
      positive: positive ?? this.positive,
      positiveBg: positiveBg ?? this.positiveBg,
      negative: negative ?? this.negative,
      negativeLight: negativeLight ?? this.negativeLight,
      negativeBg: negativeBg ?? this.negativeBg,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      headerBg: headerBg ?? this.headerBg,
      navBg: navBg ?? this.navBg,
      glow: glow ?? this.glow,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      surfaceHighest: Color.lerp(surfaceHighest, other.surfaceHighest, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      positiveBg: Color.lerp(positiveBg, other.positiveBg, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      negativeLight: Color.lerp(negativeLight, other.negativeLight, t)!,
      negativeBg: Color.lerp(negativeBg, other.negativeBg, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      headerBg: Color.lerp(headerBg, other.headerBg, t)!,
      navBg: Color.lerp(navBg, other.navBg, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// Current [AppPalette]. Falls back to dark if the extension is missing.
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}
