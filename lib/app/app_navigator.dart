import 'package:flutter/material.dart';

import '../screens/settings_page.dart';
import '../screens/suppliers_page.dart';

class AppNavigator {
  static final key = GlobalKey<NavigatorState>();

  static Future<void> openSettings() async {
    final navigator = key.currentState;
    if (navigator == null) return;

    String? topName;
    navigator.popUntil((route) {
      topName = route.settings.name;
      return true;
    });
    if (topName == SettingsPage.routeName ||
        topName == SuppliersPage.routeName) {
      return;
    }

    await navigator.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: SettingsPage.routeName),
        builder: (_) => const SettingsPage(),
      ),
    );
  }
}
