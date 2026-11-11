import 'package:flutter/material.dart';

import '../app/app_navigator.dart';
import '../l10n/app_strings.dart';
import '../settings/app_settings.dart';

/// Shared top-right actions: quick convert, compare, then settings.
/// Settings is always the rightmost control so pages stay aligned.
class AppHeaderActions extends StatelessWidget {
  const AppHeaderActions({
    super.key,
    this.onOpenSettings,
    this.showCompare = false,
    this.onQuickCalc,
  });

  final VoidCallback? onOpenSettings;
  final bool showCompare;
  final VoidCallback? onQuickCalc;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final settings = AppSettings.instance;
        final compare = showCompare && settings.showCompareHeaderIcon;
        final settingsIcon =
            settings.showSettingsHeaderIcon && onOpenSettings != null;
        final quickCalc = onQuickCalc != null;
        if (!quickCalc && !compare && !settingsIcon) {
          return const SizedBox(width: 4);
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (quickCalc)
              IconButton(
                onPressed: onQuickCalc,
                icon: const Icon(Icons.calculate_outlined),
                tooltip: s.quickCalcTitle,
              ),
            if (compare)
              IconButton(
                onPressed: () => AppNavigator.openCompare(),
                icon: const Icon(Icons.balance_outlined),
                tooltip: s.tabCompare,
              ),
            if (settingsIcon)
              IconButton(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings_outlined),
                tooltip: s.settings,
              ),
          ],
        );
      },
    );
  }
}

/// Title row matching product / compare wide headers.
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.leading,
    this.onOpenSettings,
    this.showCompare = false,
    this.onQuickCalc,
    this.onTitleDoubleTap,
    this.titleTooltip,
  });

  final String title;
  final Widget? leading;
  final VoidCallback? onOpenSettings;
  final bool showCompare;
  final VoidCallback? onQuickCalc;
  final VoidCallback? onTitleDoubleTap;
  final String? titleTooltip;

  static const EdgeInsets padding = EdgeInsets.fromLTRB(20, 16, 12, 8);

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final titleText = Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
    );

    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 8),
          ],
          Expanded(
            child: onTitleDoubleTap == null
                ? titleText
                : Tooltip(
                    message: titleTooltip ?? s.quickCalcTitleHint,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onDoubleTap: onTitleDoubleTap,
                      child: titleText,
                    ),
                  ),
          ),
          AppHeaderActions(
            onOpenSettings: onOpenSettings,
            showCompare: showCompare,
            onQuickCalc: onQuickCalc,
          ),
        ],
      ),
    );
  }
}
