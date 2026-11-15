import 'package:flutter/widgets.dart';

/// Corner radii from Figma.
abstract final class AppRadii {
  static const double card = 12; // cards, rows, trend cards
  static const double tile = 8; // inner metric tiles
  static const double badge = 4; // % badges, small buttons, tabs
  static const double pill = 9999; // chips, avatars, switchers

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(card));
  static const BorderRadius tileRadius = BorderRadius.all(Radius.circular(tile));
  static const BorderRadius badgeRadius =
      BorderRadius.all(Radius.circular(badge));
  static const BorderRadius pillRadius = BorderRadius.all(Radius.circular(pill));
}
