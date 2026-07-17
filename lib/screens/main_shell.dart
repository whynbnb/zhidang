import 'package:flutter/material.dart';

import '../screens/compare_page.dart';
import '../screens/home_page.dart';
import '../l10n/app_strings.dart';

/// Root shell: products tab + cross-product compare tab.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomePage(),
          ComparePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
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
