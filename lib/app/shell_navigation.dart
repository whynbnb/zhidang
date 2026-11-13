import 'package:flutter/foundation.dart';

import '../settings/app_settings.dart';

/// Lets pages pushed above the root shell ask it to switch tabs.
class ShellNavigation {
  ShellNavigation._();

  static final ValueNotifier<ShellNavDestination?> tabRequest =
      ValueNotifier<ShellNavDestination?>(null);

  static void selectTab(ShellNavDestination destination) {
    tabRequest.value = destination;
  }
}
