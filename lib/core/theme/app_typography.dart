import 'package:flutter/material.dart';

/// Typography tokens from Figma. Colour is NOT set here; widgets apply it from
/// the palette (`AppTypography.price.copyWith(color: context.palette.textPrimary)`).
///
/// Families are bundled in assets/fonts (no runtime font download):
///  - Inter          : names, headings, hero value
///  - JetBrainsMono  : prices, labels, chips, badges, navigation
abstract final class AppTypography {
  static const String _sans = 'Inter';
  static const String _mono = 'JetBrainsMono';

  /// "$34.82B" - Inter 600, 26/32, -0.65
  static const TextStyle heroValue = TextStyle(
    fontFamily: _sans,
    fontSize: 26,
    height: 32 / 26,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.65,
  );

  /// Header wordmark "Aether" - Inter 600, 18/18, -0.45
  static const TextStyle headerTitle = TextStyle(
    fontFamily: _sans,
    fontSize: 18,
    height: 1,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.45,
  );

  /// Section title "Spot Markets" - Inter 600, 16/22
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: _sans,
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w600,
  );

  /// Asset symbol in rows - Inter 600, 14/20, +0.14
  static const TextStyle symbol = TextStyle(
    fontFamily: _sans,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.14,
  );

  /// Price / metric value - JetBrains Mono Bold, 13/18, -0.13
  static const TextStyle price = TextStyle(
    fontFamily: _mono,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.13,
  );

  /// Medium-weight 13 px mono (e.g. hero change %) - 13/18, -0.13
  static const TextStyle valueMedium = TextStyle(
    fontFamily: _mono,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.13,
  );

  /// Label / caption / chip - JetBrains Mono Medium, 11/14
  static const TextStyle label = TextStyle(
    fontFamily: _mono,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w500,
  );

  /// Active chip / badge / active tab - JetBrains Mono Bold, 11/14
  static const TextStyle labelStrong = TextStyle(
    fontFamily: _mono,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w700,
  );

  /// Uppercase micro label - JetBrains Mono Medium, 11/14, +0.55
  static const TextStyle micro = TextStyle(
    fontFamily: _mono,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.55,
  );

  /// Body text used by generic state views (Inter 400, 14/20).
  static const TextStyle body = TextStyle(
    fontFamily: _sans,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
  );
}
