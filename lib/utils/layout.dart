import 'package:flutter/material.dart';

/// Shared wide-layout rules for product and compare shells.
class AppLayout {
  AppLayout._();

  /// Split list | detail when width is at least this.
  static const double wideBreakpoint = 840;

  /// Left : right = 1 : 1.5 → flex 2 : 3.
  static const int splitLeftFlex = 2;
  static const int splitRightFlex = 3;

  static bool isWide(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= wideBreakpoint;
  }

  static bool isWideWidth(double width) => width >= wideBreakpoint;
}
