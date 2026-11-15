import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Every icon the app uses, in one place. They are Material icons for now;
/// swapping to the exported Figma SVGs later only means changing this file
/// (the app does not depend on `flutter_svg` yet).
abstract final class AppIcons {
  static const IconData search = Icons.search;
  static const IconData starFilled = Icons.star;
  static const IconData starOutline = Icons.star_border;
  static const IconData filter = Icons.tune;
  static const IconData sortDown = Icons.arrow_downward;
  static const IconData sortUp = Icons.arrow_upward;
  static const IconData dropdown = Icons.keyboard_arrow_down;
  static const IconData chevronRight = Icons.chevron_right;
  static const IconData arrowRight = Icons.arrow_forward;
  static const IconData signal = CupertinoIcons.dot_radiowaves_left_right;
  static const IconData speed = Icons.speed;
  static const IconData offline = Icons.cloud_off;
  static const IconData info = Icons.info_outline;
  static const IconData refresh = Icons.refresh;
  static const IconData triangleUp = Icons.arrow_drop_up;
  static const IconData breadth = Icons.stacked_bar_chart;
  static const IconData triangleDown = Icons.arrow_drop_down;
}
