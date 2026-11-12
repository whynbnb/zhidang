import 'package:flutter/material.dart';

import '../screens/categories_page.dart';
import '../screens/compare_page.dart';
import '../screens/data_center_page.dart';
import '../screens/data_manage_page.dart';
import '../screens/navigation_settings_page.dart';
import '../screens/quick_calc_page.dart';
import '../screens/settings_page.dart';
import '../screens/suppliers_page.dart';
import '../screens/units_page.dart';

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
        topName == SuppliersPage.routeName ||
        topName == CategoriesPage.routeName ||
        topName == UnitsPage.routeName ||
        topName == DataManagePage.routeName ||
        topName == NavigationSettingsPage.routeName) {
      return;
    }

    await navigator.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: SettingsPage.routeName),
        builder: (_) => const SettingsPage(),
      ),
    );
  }

  static Future<void> openCompare() async {
    final navigator = key.currentState;
    if (navigator == null) return;
    await navigator.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: ComparePage.routeName),
        builder: (_) => const ComparePage(),
      ),
    );
  }

  static Future<void> openDataCenter() async {
    final navigator = key.currentState;
    if (navigator == null) return;
    String? topName;
    navigator.popUntil((route) {
      topName = route.settings.name;
      return true;
    });
    if (topName == DataCenterPage.routeName) return;
    await navigator.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: DataCenterPage.routeName),
        builder: (_) => const DataCenterPage(),
      ),
    );
  }

  static Future<void> openQuickCalc() async {
    final navigator = key.currentState;
    if (navigator == null) return;
    String? topName;
    navigator.popUntil((route) {
      topName = route.settings.name;
      return true;
    });
    if (topName == QuickCalcPage.routeName) return;
    await navigator.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: QuickCalcPage.routeName),
        builder: (_) => const QuickCalcPage(),
      ),
    );
  }
}
