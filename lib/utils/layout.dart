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

/// Supplies a MediaQuery width from the actual layout constraints.
///
/// Android freeform / split-screen resizes can leave MediaQuery with a stale
/// window size on some ROMs. The constraints, however, are updated by the
/// layout system, so resolving page-level breakpoints through them keeps
/// headers and split layouts consistent after restoring a small window.
class ResponsiveWidthScope extends StatelessWidget {
  const ResponsiveWidthScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.of(context);
        if (!constraints.hasBoundedWidth) return child;
        final width = constraints.maxWidth;
        if (width <= 0) return child;
        if ((media.size.width - width).abs() < 0.5) return child;
        return MediaQuery(
          data: media.copyWith(size: Size(width, media.size.height)),
          child: child,
        );
      },
    );
  }
}
