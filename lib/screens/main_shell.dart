import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../screens/compare_page.dart';
import '../screens/home_page.dart';
import '../settings/app_settings.dart';

/// Root shell: products + optional compare entry (bottom / header / off).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _compareKey = GlobalKey<ComparePageState>();

  @override
  void initState() {
    super.initState();
    AppSettings.instance.addListener(_onSettings);
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_onSettings);
    super.dispose();
  }

  void _onSettings() {
    final mode = AppSettings.instance.compareNavMode;
    if (mode != CompareNavMode.bottomNav && _index != 0) {
      setState(() => _index = 0);
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final mode = AppSettings.instance.compareNavMode;
    final useBottom = mode == CompareNavMode.bottomNav;

    return Scaffold(
      body: useBottom
          ? IndexedStack(
              index: _index,
              children: [
                const HomePage(),
                ComparePage(key: _compareKey),
              ],
            )
          : const HomePage(),
      bottomNavigationBar: useBottom
          ? NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) {
                setState(() => _index = i);
                if (i == 1) {
                  _compareKey.currentState?.reload();
                }
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.inventory_2_outlined),
                  selectedIcon: const Icon(Icons.inventory_2),
                  label: s.tabProducts,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.balance_outlined),
                  selectedIcon: const Icon(Icons.balance),
                  label: s.tabCompare,
                ),
              ],
            )
          : null,
    );
  }
}
