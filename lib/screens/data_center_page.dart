import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import 'categories_page.dart';
import 'data_manage_page.dart';
import 'suppliers_page.dart';
import 'units_page.dart';

/// Data maintenance area: suppliers, categories, units and backup/restore.
class DataCenterPage extends StatelessWidget {
  const DataCenterPage({super.key, this.embedded = false});

  /// When true (nav-bar tab), omit the back affordance.
  final bool embedded;

  static const routeName = '/data-center';

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: embedded ? null : AppBar(title: Text(s.dataCenter)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, embedded ? 16 : 8, 16, 32),
        children: [
          if (embedded) ...[
            Text(
              s.dataCenter,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            elevation: 0,
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            child: Column(
              children: [
                ListTile(
                  leading:
                      Icon(Icons.storefront_outlined, color: scheme.primary),
                  title: Text(s.suppliersManage),
                  subtitle: Text(s.suppliersManageHint),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(context, SuppliersPage.routeName),
                ),
                _divider(scheme),
                ListTile(
                  leading:
                      Icon(Icons.category_outlined, color: scheme.primary),
                  title: Text(s.categoriesManage),
                  subtitle: Text(s.categoriesManageHint),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(context, CategoriesPage.routeName),
                ),
                _divider(scheme),
                ListTile(
                  leading:
                      Icon(Icons.straighten_outlined, color: scheme.primary),
                  title: Text(s.unitsManage),
                  subtitle: Text(s.unitsManageHint),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(context, UnitsPage.routeName),
                ),
                _divider(scheme),
                ListTile(
                  leading:
                      Icon(Icons.folder_special_outlined, color: scheme.primary),
                  title: Text(s.dataManage),
                  subtitle: Text(s.dataManageHint),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(context, DataManagePage.routeName),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(ColorScheme scheme) {
    return Divider(
      height: 1,
      indent: 56,
      color: scheme.outlineVariant.withValues(alpha: 0.6),
    );
  }

  void _open(BuildContext context, String routeName) {
    final Widget page;
    switch (routeName) {
      case SuppliersPage.routeName:
        page = const SuppliersPage();
        break;
      case CategoriesPage.routeName:
        page = const CategoriesPage();
        break;
      case UnitsPage.routeName:
        page = const UnitsPage();
        break;
      default:
        page = const DataManagePage();
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: routeName),
        builder: (_) => page,
      ),
    );
  }
}
