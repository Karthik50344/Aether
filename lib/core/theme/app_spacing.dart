/// Spacing scale and fixed layout metrics measured from Figma (390 px frame).
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 24;

  /// Horizontal screen padding.
  static const double screen = 16;

  /// Gap between list rows.
  static const double rowGap = 6;

  /// Header and bottom-navigation heights.
  static const double headerHeight = 64;
  static const double navHeight = 64;

  /// Minimum touch target.
  static const double touchTarget = 44;

  /// Content is centred and capped on wide screens (tablets / landscape).
  static const double maxContentWidth = 600;
}
