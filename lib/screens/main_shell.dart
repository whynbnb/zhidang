import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../screens/compare_page.dart';
import '../screens/data_center_page.dart';
import '../screens/home_page.dart';
import '../screens/settings_page.dart';
import '../settings/app_settings.dart';

/// Root shell: products + optional compare / settings on nav bar or header.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _compareKey = GlobalKey<ComparePageState>();
  List<ShellNavDestination> _destinations = const [];

  @override
  void initState() {
    super.initState();
    AppSettings.instance.addListener(_onSettings);
    _destinations = AppSettings.instance.navDestinations;
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_onSettings);
    super.dispose();
  }

  void _onSettings() {
    final next = AppSettings.instance.navDestinations;
    var index = _index;
    if (next.isEmpty) {
      index = 0;
    } else if (index >= next.length) {
      index = 0;
    } else if (_destinations.isNotEmpty &&
        index < _destinations.length &&
        !next.contains(_destinations[index])) {
      index = 0;
    }
    setState(() {
      _destinations = next;
      _index = index;
    });
  }

  void _select(int i) {
    if (i < 0 || i >= _destinations.length) return;
    setState(() => _index = i);
    if (_destinations[i] == ShellNavDestination.compare) {
      _compareKey.currentState?.reload();
    }
  }

  Widget _pageFor(ShellNavDestination d) {
    switch (d) {
      case ShellNavDestination.products:
        return const HomePage();
      case ShellNavDestination.dataCenter:
        return const DataCenterPage(embedded: true);
      case ShellNavDestination.compare:
        return ComparePage(key: _compareKey);
      case ShellNavDestination.settings:
        return const SettingsPage(embedded: true);
    }
  }

  NavigationDestination _navDestination(
    AppStrings s,
    ShellNavDestination d,
  ) {
    switch (d) {
      case ShellNavDestination.products:
        return NavigationDestination(
          icon: const Icon(Icons.inventory_2_outlined),
          selectedIcon: const Icon(Icons.inventory_2),
          label: s.tabProducts,
        );
      case ShellNavDestination.dataCenter:
        return NavigationDestination(
          icon: const Icon(Icons.dataset_outlined),
          selectedIcon: const Icon(Icons.dataset),
          label: s.tabData,
        );
      case ShellNavDestination.compare:
        return NavigationDestination(
          icon: const Icon(Icons.balance_outlined),
          selectedIcon: const Icon(Icons.balance),
          label: s.tabCompare,
        );
      case ShellNavDestination.settings:
        return NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: s.settings,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final settings = AppSettings.instance;
    final dests = settings.navDestinations;
    final showNav = dests.isNotEmpty;
    final useSidebar = showNav && settings.useSidebarNav(context);

    // Keep destinations list in sync without relying solely on listener race.
    if (dests.length != _destinations.length ||
        !_listEq(dests, _destinations)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onSettings();
      });
    }

    final body = showNav
        ? IndexedStack(
            index: _index.clamp(0, dests.length - 1),
            children: [for (final d in dests) _pageFor(d)],
          )
        : const HomePage();

    final navDestinations = [
      for (final d in dests) _navDestination(s, d),
    ];

    if (useSidebar) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index.clamp(0, dests.length - 1),
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in navDestinations)
                  NavigationRailDestination(
                    icon: d.icon,
                    selectedIcon: d.selectedIcon,
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: showNav
          ? NavigationBar(
              selectedIndex: _index.clamp(0, dests.length - 1),
              onDestinationSelected: _select,
              destinations: navDestinations,
            )
          : null,
    );
  }

  bool _listEq(List<ShellNavDestination> a, List<ShellNavDestination> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
