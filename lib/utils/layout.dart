import 'package:flutter/foundation.dart';
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

/// Repairs implausible system insets reported by some Android ROMs after a
/// freeform window is restored. The stale value is usually the caption bar of
/// the small window, which can be mistaken for a huge top safe-area inset.
MediaQueryData sanitizeAndroidWindowInsets(MediaQueryData data) {
  if (defaultTargetPlatform != TargetPlatform.android) return data;
  EdgeInsets repair(EdgeInsets value) {
    if (value.top <= 72 && value.bottom <= 120) return value;
    return value.copyWith(
      top: value.top > 72 ? 48 : value.top,
      bottom: value.bottom > 120 ? 48 : value.bottom,
    );
  }

  final padding = repair(data.padding);
  final viewPadding = repair(data.viewPadding);
  final viewInsets = data.viewInsets.top > 72
      ? data.viewInsets.copyWith(top: 0)
      : data.viewInsets;
  if (padding == data.padding &&
      viewPadding == data.viewPadding &&
      viewInsets == data.viewInsets) {
    return data;
  }
  return data.copyWith(
    padding: padding,
    viewPadding: viewPadding,
    viewInsets: viewInsets,
  );
}
