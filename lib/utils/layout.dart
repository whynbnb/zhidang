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

/// Repairs implausible system insets reported by some Android ROMs after a
/// freeform window is restored. The stale value is usually the caption bar of
/// the small window, which can be mistaken for a huge top safe-area inset.
MediaQueryData sanitizeAndroidWindowInsets(MediaQueryData data) {
  if (defaultTargetPlatform != TargetPlatform.android) return data;
  EdgeInsets repair(EdgeInsets value) {
    // Some HyperOS / MIUI builds report the floating-window caption as an
    // enormous top inset. Cap it at a normal status-bar size instead of
    // letting SafeArea collapse the page body.
    const maxTop = 48.0;
    const maxBottom = 72.0;
    return value.copyWith(
      top: value.top > maxTop ? maxTop : value.top,
      bottom: value.bottom > maxBottom ? 48 : value.bottom,
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
