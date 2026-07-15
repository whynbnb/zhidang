import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_navigator.dart';
import '../l10n/app_strings.dart';

class MacosMenuBar extends StatelessWidget {
  const MacosMenuBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) {
      return child;
    }

    final s = AppStrings.of(context);
    final appName = s.appName;

    return PlatformMenuBar(
      menus: [
        PlatformMenu(
          label: appName,
          menus: [
            if (PlatformProvidedMenuItem.hasMenu(
              PlatformProvidedMenuItemType.about,
            ))
              const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.about,
              ),
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: s.menuSettings,
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.comma,
                    meta: true,
                  ),
                  onSelected: AppNavigator.openSettings,
                ),
              ],
            ),
            if (PlatformProvidedMenuItem.hasMenu(
              PlatformProvidedMenuItemType.servicesSubmenu,
            ))
              const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.servicesSubmenu,
              ),
            PlatformMenuItemGroup(
              members: [
                if (PlatformProvidedMenuItem.hasMenu(
                  PlatformProvidedMenuItemType.hide,
                ))
                  const PlatformProvidedMenuItem(
                    type: PlatformProvidedMenuItemType.hide,
                  ),
                if (PlatformProvidedMenuItem.hasMenu(
                  PlatformProvidedMenuItemType.hideOtherApplications,
                ))
                  const PlatformProvidedMenuItem(
                    type: PlatformProvidedMenuItemType.hideOtherApplications,
                  ),
                if (PlatformProvidedMenuItem.hasMenu(
                  PlatformProvidedMenuItemType.showAllApplications,
                ))
                  const PlatformProvidedMenuItem(
                    type: PlatformProvidedMenuItemType.showAllApplications,
                  ),
              ],
            ),
            if (PlatformProvidedMenuItem.hasMenu(
              PlatformProvidedMenuItemType.quit,
            ))
              const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.quit,
              ),
          ],
        ),
        PlatformMenu(
          label: s.menuEdit,
          menus: [
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: s.menuUndo,
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyZ,
                    meta: true,
                  ),
                  onSelected: () => _invoke(const UndoTextIntent(
                    SelectionChangedCause.keyboard,
                  )),
                ),
                PlatformMenuItem(
                  label: s.menuRedo,
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyZ,
                    meta: true,
                    shift: true,
                  ),
                  onSelected: () => _invoke(const RedoTextIntent(
                    SelectionChangedCause.keyboard,
                  )),
                ),
              ],
            ),
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: s.menuCut,
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyX,
                    meta: true,
                  ),
                  onSelected: () => _invoke(
                    const CopySelectionTextIntent.cut(
                      SelectionChangedCause.keyboard,
                    ),
                  ),
                ),
                PlatformMenuItem(
                  label: s.menuCopy,
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyC,
                    meta: true,
                  ),
                  onSelected: () => _invoke(CopySelectionTextIntent.copy),
                ),
                PlatformMenuItem(
                  label: s.menuPaste,
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyV,
                    meta: true,
                  ),
                  onSelected: () => _invoke(
                    const PasteTextIntent(SelectionChangedCause.keyboard),
                  ),
                ),
                PlatformMenuItem(
                  label: s.menuSelectAll,
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyA,
                    meta: true,
                  ),
                  onSelected: () => _invoke(
                    const SelectAllTextIntent(SelectionChangedCause.keyboard),
                  ),
                ),
              ],
            ),
          ],
        ),
        PlatformMenu(
          label: s.menuView,
          menus: [
            if (PlatformProvidedMenuItem.hasMenu(
              PlatformProvidedMenuItemType.toggleFullScreen,
            ))
              const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.toggleFullScreen,
              ),
          ],
        ),
        PlatformMenu(
          label: s.menuWindow,
          menus: [
            if (PlatformProvidedMenuItem.hasMenu(
              PlatformProvidedMenuItemType.minimizeWindow,
            ))
              const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.minimizeWindow,
              ),
            if (PlatformProvidedMenuItem.hasMenu(
              PlatformProvidedMenuItemType.zoomWindow,
            ))
              const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.zoomWindow,
              ),
            if (PlatformProvidedMenuItem.hasMenu(
              PlatformProvidedMenuItemType.arrangeWindowsInFront,
            ))
              const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.arrangeWindowsInFront,
              ),
          ],
        ),
      ],
      child: child,
    );
  }

  void _invoke(Intent intent) {
    final focused = FocusManager.instance.primaryFocus?.context;
    if (focused == null) return;
    Actions.maybeInvoke(focused, intent);
  }
}
