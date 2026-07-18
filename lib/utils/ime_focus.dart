import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// macOS cold-start / sheet open can race with system IME first-responder.
/// Prefer delayed requestFocus over immediate [autofocus] on desktop.
bool get prefersDelayedTextFocus {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;
}

/// Request focus after the current frame so the platform view is ready for IME.
void scheduleTextFocus(FocusNode node, {Duration delay = const Duration(milliseconds: 50)}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future<void>.delayed(delay, () {
      if (node.canRequestFocus) {
        node.requestFocus();
      }
    });
  });
}
