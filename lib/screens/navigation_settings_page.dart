import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../settings/app_settings.dart';

/// Dedicated page for compare / settings entry placement and sidebar.
class NavigationSettingsPage extends StatelessWidget {
  const NavigationSettingsPage({super.key});

  static const routeName = '/settings/navigation';

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(s.navMode)),
      body: ListenableBuilder(
        listenable: AppSettings.instance,
        builder: (context, _) {
          final settings = AppSettings.instance;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                s.navBarEmptyHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              _SectionTitle(s.compareEntry),
              _OptionCard(
                children: [
                  _ModeTile(
                    icon: Icons.view_agenda_outlined,
                    title: s.compareNavBottom,
                    subtitle: s.compareNavBottomHint,
                    selected: settings.compareNavMode == CompareNavMode.bottomNav,
                    onTap: () =>
                        settings.setCompareNavMode(CompareNavMode.bottomNav),
                  ),
                  _ModeTile(
                    icon: Icons.balance_outlined,
                    title: s.compareNavHeader,
                    subtitle: s.compareNavHeaderHint,
                    selected: settings.compareNavMode == CompareNavMode.headerIcon,
                    onTap: () =>
                        settings.setCompareNavMode(CompareNavMode.headerIcon),
                  ),
                  _ModeTile(
                    icon: Icons.visibility_off_outlined,
                    title: s.compareNavDisabled,
                    subtitle: s.compareNavDisabledHint,
                    selected: settings.compareNavMode == CompareNavMode.disabled,
                    onTap: () =>
                        settings.setCompareNavMode(CompareNavMode.disabled),
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionTitle(s.settingsEntry),
              _OptionCard(
                children: [
                  _ModeTile(
                    icon: Icons.view_agenda_outlined,
                    title: s.settingsNavBar,
                    subtitle: s.settingsNavBarHint,
                    selected:
                        settings.settingsEntryMode == SettingsEntryMode.navBar,
                    onTap: () => settings
                        .setSettingsEntryMode(SettingsEntryMode.navBar),
                  ),
                  _ModeTile(
                    icon: Icons.settings_outlined,
                    title: s.settingsNavHeader,
                    subtitle: s.settingsNavHeaderHint,
                    selected: settings.settingsEntryMode ==
                        SettingsEntryMode.headerIcon,
                    onTap: () => settings
                        .setSettingsEntryMode(SettingsEntryMode.headerIcon),
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                s.sidebarAutoHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Column(children: children),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: scheme.primary),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: selected
              ? Icon(Icons.check_circle, color: scheme.primary)
              : null,
          onTap: onTap,
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 56,
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
      ],
    );
  }
}
