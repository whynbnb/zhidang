import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../services/category_store.dart';
import '../services/comparison_store.dart';
import '../services/data_revision.dart';
import '../services/quick_calc_store.dart';
import '../services/storage_service.dart';
import '../services/supplier_store.dart';
import '../services/unit_store.dart';
import 'categories_page.dart';
import 'data_manage_page.dart';
import 'quick_calc_page.dart';
import 'suppliers_page.dart';
import 'unit_conversions_page.dart';
import 'units_page.dart';

/// Data maintenance area: overview, tools and the stored data pages.
class DataCenterPage extends StatefulWidget {
  const DataCenterPage({super.key, this.embedded = false});

  /// When true (nav-bar tab), omit the back affordance.
  final bool embedded;

  static const routeName = '/data-center';

  @override
  State<DataCenterPage> createState() => _DataCenterPageState();
}

class _DataCenterPageState extends State<DataCenterPage> {
  final _storage = StorageService();
  List<Product>? _products;
  late final Listenable _stores = Listenable.merge([
    UnitStore.instance,
    CategoryStore.instance,
    SupplierStore.instance,
    ComparisonStore.instance,
    QuickCalcStore.instance,
  ]);

  @override
  void initState() {
    super.initState();
    _load();
    DataRevision.notifier.addListener(_onRevision);
  }

  @override
  void dispose() {
    DataRevision.notifier.removeListener(_onRevision);
    super.dispose();
  }

  void _onRevision() {
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _storage.loadProducts();
      if (!mounted) return;
      setState(() => _products = items);
    } catch (_) {
      if (!mounted) return;
      setState(() => _products = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: Text(s.dataCenter)),
      body: ListenableBuilder(
        listenable: _stores,
        builder: (context, _) {
          final products = _products;
          final offers = products?.fold<int>(
            0,
            (total, product) => total + product.offers.length,
          );
          final pinned = QuickCalcStore.instance.entries
              .where((entry) => entry.pinned)
              .length;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              widget.embedded ? 16 : 8,
              16,
              32,
            ),
            children: [
              if (widget.embedded) ...[
                Text(
                  s.dataCenter,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 16),
              ],
              _Overview(
                products: products?.length,
                offers: offers,
                suppliers: SupplierStore.instance.suppliers.length,
                categories: CategoryStore.instance.categories.length,
                units: UnitStore.instance.units.length,
                groups: ComparisonStore.instance.groups.length,
              ),
              const SizedBox(height: 20),
              _SectionTitle(s.dataTools),
              _Panel(
                children: [
                  ListTile(
                    leading: Icon(Icons.swap_horiz, color: scheme.primary),
                    title: Text(s.unitConversions),
                    subtitle: Text(
                      UnitStore.instance.relations.isEmpty
                          ? s.noUnitConversions
                          : s.unitConversionsCount(
                              UnitStore.instance.relations.length,
                            ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _push(
                      context,
                      UnitConversionsPage.routeName,
                      const UnitConversionsPage(),
                    ),
                  ),
                  _divider(scheme),
                  ListTile(
                    leading:
                        Icon(Icons.calculate_outlined, color: scheme.primary),
                    title: Text(s.quickCalcTitle),
                    subtitle: Text(
                      pinned == 0
                          ? s.quickCalcNoPinned
                          : s.quickCalcPinnedCount(pinned),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _push(
                      context,
                      QuickCalcPage.routeName,
                      const QuickCalcPage(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionTitle(s.dataMaintenance),
              _Panel(
                children: [
                  ListTile(
                    leading:
                        Icon(Icons.storefront_outlined, color: scheme.primary),
                    title: Text(s.suppliersManage),
                    subtitle: Text(s.suppliersManageHint),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _push(
                      context,
                      SuppliersPage.routeName,
                      const SuppliersPage(),
                    ),
                  ),
                  _divider(scheme),
                  ListTile(
                    leading:
                        Icon(Icons.category_outlined, color: scheme.primary),
                    title: Text(s.categoriesManage),
                    subtitle: Text(s.categoriesManageHint),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _push(
                      context,
                      CategoriesPage.routeName,
                      const CategoriesPage(),
                    ),
                  ),
                  _divider(scheme),
                  ListTile(
                    leading:
                        Icon(Icons.straighten_outlined, color: scheme.primary),
                    title: Text(s.unitsManage),
                    subtitle: Text(s.unitsManageHint),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _push(
                      context,
                      UnitsPage.routeName,
                      const UnitsPage(),
                    ),
                  ),
                  _divider(scheme),
                  ListTile(
                    leading: Icon(
                      Icons.folder_special_outlined,
                      color: scheme.primary,
                    ),
                    title: Text(s.dataManage),
                    subtitle: Text(s.dataManageHint),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _push(
                      context,
                      DataManagePage.routeName,
                      const DataManagePage(),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
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

  void _push(BuildContext context, String routeName, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: routeName),
        builder: (_) => page,
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({
    required this.products,
    required this.offers,
    required this.suppliers,
    required this.categories,
    required this.units,
    required this.groups,
  });

  final int? products;
  final int? offers;
  final int suppliers;
  final int categories;
  final int units;
  final int groups;

  String _value(int? value) => value == null ? '—' : '$value';

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final items = [
      ('products', Icons.inventory_2_outlined, s.tabProducts, _value(products)),
      ('offers', Icons.local_offer_outlined, s.offersStat, _value(offers)),
      ('suppliers', Icons.storefront_outlined, s.suppliers, '$suppliers'),
      ('categories', Icons.category_outlined, s.categories, '$categories'),
      ('units', Icons.straighten_outlined, s.units, '$units'),
      (
        'groups',
        Icons.balance_outlined,
        s.comparisonGroupsStat,
        '$groups',
      ),
    ];

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 860
                ? 6
                : constraints.maxWidth >= 560
                    ? 3
                    : 2;
            const spacing = 10.0;
            final width =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final item in items)
                  SizedBox(
                    width: width,
                    child: _StatTile(
                      id: item.$1,
                      icon: item.$2,
                      label: item.$3,
                      value: item.$4,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.id,
    required this.icon,
    required this.label,
    required this.value,
  });

  final String id;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: scheme.primary),
              const Spacer(),
              Text(
                value,
                key: ValueKey('stat-$id-value'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.children});

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
