import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../screens/compare_page.dart';
import '../screens/home_page.dart';

/// Root shell: products tab + cross-product compare tab.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _compareKey = GlobalKey<ComparePageState>();

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const HomePage(),
          ComparePage(key: _compareKey),
        ],
      ),
      bottomNavigationBar: NavigationBar(
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
      ),
    );
  }
}
