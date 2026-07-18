import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/app_navigator.dart';
import '../l10n/app_strings.dart';
import '../models/comparison_group.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../services/category_store.dart';
import '../services/comparison_store.dart';
import '../services/data_revision.dart';
import '../services/storage_service.dart';
import '../utils/comparison_logic.dart';
import '../utils/ime_focus.dart';
import '../utils/layout.dart';
import '../widgets/app_header_actions.dart';

final _currency = NumberFormat('#,##0.##');

class ComparePage extends StatefulWidget {
  const ComparePage({super.key});

  static const routeName = '/compare';

  @override
  State<ComparePage> createState() => ComparePageState();
}

class ComparePageState extends State<ComparePage> {
  final _storage = StorageService();
  List<Product> _products = [];
  bool _loading = true;
  int _seenRevision = DataRevision.notifier.value;

  /// Wide split: selected fixed group id (null = none / temp / category).
  String? _selectedGroupId;
  /// Wide split: selected auto category id.
  String? _selectedCategoryId;
  /// Wide split temporary session.
  List<Product>? _tempProducts;
  String? _tempTitle;

  @override
  void initState() {
    super.initState();
    DataRevision.notifier.addListener(_onRevision);
    _load();
  }

  @override
  void dispose() {
    DataRevision.notifier.removeListener(_onRevision);
    super.dispose();
  }

  void _onRevision() {
    if (DataRevision.notifier.value == _seenRevision) return;
    _seenRevision = DataRevision.notifier.value;
    _load();
  }

  /// Called when the compare tab becomes visible.
  Future<void> reload() => _load();

  Future<void> _load() async {
    final products = await _storage.loadProducts();
    await ComparisonStore.instance.pruneMissingProducts(
      products.map((p) => p.id).toSet(),
    );
    if (!mounted) return;
    setState(() {
      _products = products;
      _loading = false;
    });
  }

  Map<String, Product> get _byId => {
        for (final p in _products) p.id: p,
      };

  Future<void> _openSettings() => AppNavigator.openSettings();

  Future<void> _startTemporary() async {
    final s = AppStrings.of(context);
    final selected = await showProductMultiPicker(
      context,
      products: _products,
      initialIds: const [],
      title: s.tempCompare,
      requireCommonUnit: true,
    );
    if (selected == null || selected.length < 2 || !mounted) return;
    if (ComparisonLogic.commonUnits(selected).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.compareNeedCommonUnit)),
      );
      return;
    }
    if (AppLayout.isWide(context)) {
      setState(() {
        _selectedGroupId = null;
        _selectedCategoryId = null;
        _tempProducts = selected;
        _tempTitle = s.tempCompare;
      });
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CompareSessionPage(
          title: s.tempCompare,
          products: selected,
          temporary: true,
        ),
      ),
    );
  }

  Future<void> _addOrEditGroup([ComparisonGroup? group]) async {
    final s = AppStrings.of(context);
    final result = await showComparisonGroupForm(
      context,
      products: _products,
      group: group,
    );
    if (result == null) return;
    if (group == null) {
      await ComparisonStore.instance.add(result);
    } else {
      await ComparisonStore.instance.update(result);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(group == null ? s.groupSaved : s.groupUpdated)),
    );
  }

  Future<void> _deleteGroup(ComparisonGroup group) async {
    final s = AppStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.deleteGroup),
        content: Text(s.deleteGroupConfirm(group.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ComparisonStore.instance.remove(group.id);
    }
  }

  _GroupOpenIssue? _validateGroup(ComparisonGroup group) {
    final missing = group.productIds.where((id) => !_byId.containsKey(id)).length;
    final products = group.productIds
        .map((id) => _byId[id])
        .whereType<Product>()
        .toList();
    if (products.length < 2) {
      return _GroupOpenIssue.missing(
        missing: missing,
        remain: products.length,
      );
    }
    final common = ComparisonLogic.commonUnits(products);
    if (common.isEmpty) {
      return const _GroupOpenIssue.noCommonUnit();
    }
    return null;
  }

  Future<void> _showGroupInvalid(
    ComparisonGroup group,
    _GroupOpenIssue issue,
  ) async {
    final s = AppStrings.of(context);
    final message = switch (issue.kind) {
      _GroupOpenIssueKind.missing when issue.missing > 0 =>
        s.groupInvalidMissingPartial(issue.missing, issue.remain),
      _GroupOpenIssueKind.missing => s.groupInvalidMissing,
      _GroupOpenIssueKind.noCommonUnit => s.groupInvalidNoCommonUnit,
    };
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.groupInvalidTitle),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'edit'),
            child: Text(s.groupEditAction),
          ),
        ],
      ),
    );
    if (action == 'edit' && mounted) {
      await _addOrEditGroup(group);
    }
  }

  Future<void> _openGroup(ComparisonGroup group) async {
    final issue = _validateGroup(group);
    if (issue != null) {
      await _showGroupInvalid(group, issue);
      return;
    }
    final products = group.productIds
        .map((id) => _byId[id])
        .whereType<Product>()
        .toList();
    final common = ComparisonLogic.commonUnits(products);
    var preferred = group.preferredUnit.trim();
    if (preferred.isNotEmpty && !common.contains(preferred)) {
      preferred = '';
    }
    if (AppLayout.isWide(context)) {
      setState(() {
        _tempProducts = null;
        _tempTitle = null;
        _selectedCategoryId = null;
        _selectedGroupId = group.id;
      });
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CompareSessionPage(
          title: group.name,
          products: products,
          preferredUnit: preferred,
          temporary: false,
          group: group,
          onEditGroup: () => _addOrEditGroup(group),
        ),
      ),
    );
  }

  List<Product> _productsInCategory(ProductCategory category) {
    return _products
        .where((p) => p.categoryId == category.id)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<void> _openCategory(ProductCategory category) async {
    final s = AppStrings.of(context);
    final products = _productsInCategory(category);
    if (products.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.categoryNeedTwoProducts)),
      );
      return;
    }
    final preferred = category.unit;
    if (AppLayout.isWide(context)) {
      setState(() {
        _tempProducts = null;
        _tempTitle = null;
        _selectedGroupId = null;
        _selectedCategoryId = category.id;
      });
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CompareSessionPage(
          title: category.name,
          products: products,
          preferredUnit: preferred,
          temporary: true,
        ),
      ),
    );
  }

  ComparisonGroup? _groupById(String? id) {
    if (id == null) return null;
    for (final g in ComparisonStore.instance.groups) {
      if (g.id == id) return g;
    }
    return null;
  }

  Widget _buildSessionPane() {
    final s = AppStrings.of(context);
    if (_tempProducts != null && _tempProducts!.length >= 2) {
      return CompareSessionPage(
        key: ValueKey(
          'temp-${_tempProducts!.map((p) => p.id).join(',')}',
        ),
        title: _tempTitle ?? s.tempCompare,
        products: _tempProducts!,
        temporary: true,
        embedded: true,
      );
    }
    if (_selectedCategoryId != null) {
      final cat = CategoryStore.instance.byId(_selectedCategoryId);
      if (cat != null) {
        final products = _productsInCategory(cat);
        if (products.length >= 2) {
          return CompareSessionPage(
            key: ValueKey(
              'cat-${cat.id}-${products.map((p) => p.id).join(',')}',
            ),
            title: cat.name,
            products: products,
            preferredUnit: cat.unit,
            temporary: true,
            embedded: true,
          );
        }
      }
    }
    final group = _groupById(_selectedGroupId);
    if (group != null) {
      final issue = _validateGroup(group);
      if (issue == null) {
        final products = group.productIds
            .map((id) => _byId[id])
            .whereType<Product>()
            .toList();
        final common = ComparisonLogic.commonUnits(products);
        var preferred = group.preferredUnit.trim();
        if (preferred.isNotEmpty && !common.contains(preferred)) {
          preferred = '';
        }
        return CompareSessionPage(
          key: ValueKey('group-${group.id}'),
          title: group.name,
          products: products,
          preferredUnit: preferred,
          temporary: false,
          group: group,
          onEditGroup: () => _addOrEditGroup(group),
          embedded: true,
        );
      }
    }
    return Center(
      child: Text(
        s.selectGroupHint,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }

  Widget _buildGroupList({required bool showFabInList}) {
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: Listenable.merge([
        ComparisonStore.instance,
        CategoryStore.instance,
      ]),
      builder: (context, _) {
        final groups = ComparisonStore.instance.groups;
        final categories = CategoryStore.instance.categories
            .where((c) => _productsInCategory(c).length >= 2)
            .toList();
        // Drop selection if group was deleted.
        if (_selectedGroupId != null &&
            !groups.any((g) => g.id == _selectedGroupId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedGroupId = null);
          });
        }
        if (_selectedCategoryId != null &&
            !categories.any((c) => c.id == _selectedCategoryId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedCategoryId = null);
          });
        }
        return ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, showFabInList ? 100 : 24),
          children: [
            _QuickCompareCard(
              enabled: _products.length >= 2,
              onTap: _startTemporary,
            ),
            if (categories.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                s.categoryCompare,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                s.categoryCompareHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              ...categories.map((c) {
                final members = _productsInCategory(c);
                final names = members.map((p) => p.name).toList();
                final selected = c.id == _selectedCategoryId &&
                    _tempProducts == null &&
                    _selectedGroupId == null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    elevation: 0,
                    color: selected
                        ? scheme.primaryContainer.withValues(alpha: 0.35)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: selected
                            ? scheme.primary
                            : scheme.outlineVariant,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: scheme.tertiaryContainer,
                        foregroundColor: scheme.onTertiaryContainer,
                        child: const Icon(Icons.category_outlined),
                      ),
                      title: Text(
                        c.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        s.groupProductSummary(
                          names.length,
                          names.take(3).join(' · '),
                        ),
                      ),
                      trailing: Text(
                        c.units.join(' / '),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      onTap: () => _openCategory(c),
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 20),
            Text(
              s.fixedCompare,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              s.fixedCompareHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            if (groups.isEmpty)
              _EmptyGroups(
                canCreate: _products.length >= 2,
                onCreate: () => _addOrEditGroup(),
              )
            else
              ...groups.map((g) {
                final names = g.productIds
                    .map((id) => _byId[id]?.name)
                    .whereType<String>()
                    .toList();
                final invalid = _validateGroup(g) != null;
                final selected = g.id == _selectedGroupId &&
                    _tempProducts == null &&
                    _selectedCategoryId == null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    elevation: 0,
                    color: selected
                        ? scheme.primaryContainer.withValues(alpha: 0.35)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: selected
                            ? scheme.primary
                            : invalid
                                ? scheme.error.withValues(alpha: 0.45)
                                : scheme.outlineVariant,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: invalid
                            ? scheme.errorContainer
                            : scheme.secondaryContainer,
                        foregroundColor: invalid
                            ? scheme.onErrorContainer
                            : scheme.onSecondaryContainer,
                        child: Icon(
                          invalid
                              ? Icons.warning_amber_rounded
                              : Icons.balance,
                        ),
                      ),
                      title: Text(
                        g.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        invalid
                            ? s.groupStatusInvalid
                            : names.isEmpty
                                ? s.groupNoProducts
                                : s.groupProductSummary(
                                    names.length,
                                    names.take(3).join(' · '),
                                  ),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'open') _openGroup(g);
                          if (v == 'edit') _addOrEditGroup(g);
                          if (v == 'delete') _deleteGroup(g);
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'open',
                            child: Text(s.openCompare),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(s.edit),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(s.delete),
                          ),
                        ],
                      ),
                      onTap: () => _openGroup(g),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isWide = AppLayout.isWide(context);

    final header = AppPageHeader(
      title: s.tabCompare,
      onOpenSettings: _openSettings,
    );

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-compare-new-group',
        onPressed: _products.length < 2 ? null : () => _addOrEditGroup(),
        icon: const Icon(Icons.link),
        label: Text(s.addFixedGroup),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : isWide
                ? Row(
                    children: [
                      Expanded(
                        flex: AppLayout.splitLeftFlex,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            header,
                            Expanded(
                              child: _buildGroupList(showFabInList: true),
                            ),
                          ],
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        flex: AppLayout.splitRightFlex,
                        child: _buildSessionPane(),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      Expanded(
                        child: _buildGroupList(showFabInList: true),
                      ),
                    ],
                  ),
      ),
    );
  }
}

enum _GroupOpenIssueKind { missing, noCommonUnit }

class _GroupOpenIssue {
  const _GroupOpenIssue.missing({
    required this.missing,
    required this.remain,
  }) : kind = _GroupOpenIssueKind.missing;

  const _GroupOpenIssue.noCommonUnit()
      : kind = _GroupOpenIssueKind.noCommonUnit,
        missing = 0,
        remain = 0;

  final _GroupOpenIssueKind kind;
  final int missing;
  final int remain;
}

class _QuickCompareCard extends StatelessWidget {
  const _QuickCompareCard({
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: scheme.primaryContainer.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                child: const Icon(Icons.flash_on),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.tempCompare,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      enabled ? s.tempCompareHint : s.tempCompareNeedProducts,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: enabled ? scheme.primary : scheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyGroups extends StatelessWidget {
  const _EmptyGroups({
    required this.canCreate,
    required this.onCreate,
  });

  final bool canCreate;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.link_off,
            size: 48,
            color: scheme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 10),
          Text(s.noFixedGroups, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            s.noFixedGroupsHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          if (canCreate) ...[
            const SizedBox(height: 14),
            FilledButton.tonalIcon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: Text(s.addFixedGroup),
            ),
          ],
        ],
      ),
    );
  }
}

/// Live ranking session for fixed or temporary comparison.
class CompareSessionPage extends StatefulWidget {
  const CompareSessionPage({
    super.key,
    required this.title,
    required this.products,
    this.preferredUnit = '',
    this.temporary = false,
    this.group,
    this.onEditGroup,
    this.embedded = false,
  });

  final String title;
  final List<Product> products;
  final String preferredUnit;
  final bool temporary;
  final ComparisonGroup? group;
  final VoidCallback? onEditGroup;
  /// When true, no app bar (used inside wide split pane).
  final bool embedded;

  @override
  State<CompareSessionPage> createState() => _CompareSessionPageState();
}

class _CompareSessionPageState extends State<CompareSessionPage> {
  late String _unit;
  CompareViewMode _viewMode = CompareViewMode.all;

  @override
  void initState() {
    super.initState();
    _unit = ComparisonLogic.pickUnit(
      widget.products,
      preferred: widget.preferredUnit,
    );
  }

  List<String> get _unitOptions {
    final common = ComparisonLogic.commonUnits(widget.products);
    if (common.isNotEmpty) return common;
    final all = {
      for (final p in widget.products) ...p.measureUnits,
    }.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return all;
  }

  String get _activeUnit {
    final options = _unitOptions;
    if (options.contains(_unit)) return _unit;
    if (options.isNotEmpty) return options.first;
    return _unit;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final unitOptions = _unitOptions;
    final unit = _activeUnit;
    final rows = ComparisonLogic.rank(
      widget.products,
      unit: unit,
      mode: _viewMode,
    );
    final best = rows.where((r) => r.hasPrice).firstOrNull;
    final showPreferredBadge =
        best?.offer?.favorite == true && _viewMode != CompareViewMode.cheapest;

    final content = ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        if (widget.embedded) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (!widget.temporary && widget.onEditGroup != null)
                IconButton(
                  tooltip: s.edit,
                  onPressed: widget.onEditGroup,
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (widget.temporary)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              s.tempSessionHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
          if (unitOptions.length > 1) ...[
            Text(
              s.compareByUnit,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final u in unitOptions)
                  ChoiceChip(
                    label: Text(u),
                    selected: u == unit,
                    onSelected: (_) => setState(() => _unit = u),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Text(
            s.offerViewMode,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(s.offerViewAll),
                selected: _viewMode == CompareViewMode.all,
                onSelected: (_) =>
                    setState(() => _viewMode = CompareViewMode.all),
              ),
              ChoiceChip(
                label: Text(s.offerViewFavorites),
                selected: _viewMode == CompareViewMode.favorites,
                onSelected: (_) =>
                    setState(() => _viewMode = CompareViewMode.favorites),
              ),
              ChoiceChip(
                label: Text(s.offerViewCheapest),
                selected: _viewMode == CompareViewMode.cheapest,
                onSelected: (_) =>
                    setState(() => _viewMode = CompareViewMode.cheapest),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (best != null)
            Card(
              elevation: 0,
              color: scheme.primaryContainer.withValues(alpha: 0.55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      showPreferredBadge
                          ? s.preferredOfferNow
                          : s.bestValueNow,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      best.product.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (best.offer != null)
                      Text(
                        s.bestBrand(best.offer!.brand),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 6),
                    Text(
                      '¥${_currency.format(best.unitPrice ?? 0)} / $unit',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            s.compareRanking,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(
                    _viewMode == CompareViewMode.favorites
                        ? Icons.star_outline
                        : Icons.balance_outlined,
                    size: 48,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _viewMode == CompareViewMode.favorites
                        ? s.noFavoriteOffers
                        : s.noOffers,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _viewMode == CompareViewMode.favorites
                        ? s.noFavoriteOffersHint
                        : s.noOffersHint,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            )
          else
            ...List.generate(rows.length, (i) {
              final row = rows[i];
              final isBest = i == 0 && row.hasPrice;
              final isFav = row.offer?.favorite == true;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  elevation: 0,
                  color: isBest
                      ? scheme.primaryContainer.withValues(alpha: 0.45)
                      : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: isBest ? scheme.primary : scheme.outlineVariant,
                      width: isBest ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isBest
                          ? scheme.primary
                          : scheme.surfaceContainerHighest,
                      foregroundColor: isBest
                          ? scheme.onPrimary
                          : scheme.onSurfaceVariant,
                      child: Text(
                        isBest
                            ? (isFav ? s.favoriteBadge : s.bestBadge)
                            : '${i + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    title: Text(
                      row.offer == null
                          ? row.product.name
                          : '${row.product.name} · ${row.offer!.brand}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      () {
                        if (row.offer == null) return s.noOfferForUnit(unit);
                        final parts = <String>[
                          if (row.offer!.shop.isNotEmpty) row.offer!.shop,
                          if (isFav) '★',
                        ];
                        return parts.isEmpty
                            ? s.unitLabel(unit)
                            : parts.join(' · ');
                      }(),
                    ),
                    trailing: row.hasPrice
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '¥${_currency.format(row.unitPrice)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: isBest
                                          ? scheme.primary
                                          : scheme.onSurface,
                                    ),
                              ),
                              Text(
                                '/ $unit',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          )
                        : Text(
                            '—',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                  ),
                ),
              );
            }),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (!widget.temporary && widget.onEditGroup != null)
            IconButton(
              tooltip: s.edit,
              onPressed: widget.onEditGroup,
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: content,
    );
  }
}

Future<List<Product>?> showProductMultiPicker(
  BuildContext context, {
  required List<Product> products,
  List<String> initialIds = const [],
  required String title,
  bool requireCommonUnit = true,
}) {
  return showModalBottomSheet<List<Product>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ProductMultiPickerSheet(
      products: products,
      initialIds: initialIds,
      title: title,
      requireCommonUnit: requireCommonUnit,
    ),
  );
}

class _ProductMultiPickerSheet extends StatefulWidget {
  const _ProductMultiPickerSheet({
    required this.products,
    required this.initialIds,
    required this.title,
    this.requireCommonUnit = true,
  });

  final List<Product> products;
  final List<String> initialIds;
  final String title;
  final bool requireCommonUnit;

  @override
  State<_ProductMultiPickerSheet> createState() =>
      _ProductMultiPickerSheetState();
}

class _ProductMultiPickerSheetState extends State<_ProductMultiPickerSheet> {
  late Set<String> _selected;
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initialIds};
    _search.addListener(() {
      setState(() => _query = _search.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Product> get _pickedProducts => widget.products
      .where((p) => _selected.contains(p.id))
      .toList(growable: false);

  List<String> get _commonUnits =>
      ComparisonLogic.commonUnits(_pickedProducts);

  bool get _canConfirm {
    if (_selected.length < 2) return false;
    if (!widget.requireCommonUnit) return true;
    return _commonUnits.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final filtered = widget.products.where((p) {
      if (_query.isEmpty) return true;
      return p.name.toLowerCase().contains(_query) ||
          p.tags.any((t) => t.toLowerCase().contains(_query));
    }).toList();
    final common = _commonUnits;
    final showUnitStatus = _selected.length >= 2;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            s.pickProductsHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: s.searchHint,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.45,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final p = filtered[index];
                final checked = _selected.contains(p.id);
                return CheckboxListTile(
                  value: checked,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selected.add(p.id);
                      } else {
                        _selected.remove(p.id);
                      }
                    });
                  },
                  title: Text(p.name),
                  subtitle: Text(s.unitLabel(p.displayUnit)),
                  controlAffinity: ListTileControlAffinity.leading,
                );
              },
            ),
          ),
          if (showUnitStatus) ...[
            const SizedBox(height: 8),
            Text(
              common.isEmpty
                  ? s.compareNeedCommonUnit
                  : s.commonUnitsReady(common.join(' · ')),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: common.isEmpty ? scheme.error : scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
          const SizedBox(height: 8),
          FilledButton(
            onPressed: !_canConfirm
                ? null
                : () {
                    Navigator.pop(context, _pickedProducts);
                  },
            child: Text(s.confirmPick(_selected.length)),
          ),
        ],
      ),
    );
  }
}

Future<ComparisonGroup?> showComparisonGroupForm(
  BuildContext context, {
  required List<Product> products,
  ComparisonGroup? group,
}) {
  return showModalBottomSheet<ComparisonGroup>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ComparisonGroupFormSheet(
      products: products,
      group: group,
    ),
  );
}

class _ComparisonGroupFormSheet extends StatefulWidget {
  const _ComparisonGroupFormSheet({
    required this.products,
    this.group,
  });

  final List<Product> products;
  final ComparisonGroup? group;

  @override
  State<_ComparisonGroupFormSheet> createState() =>
      _ComparisonGroupFormSheetState();
}

class _ComparisonGroupFormSheetState extends State<_ComparisonGroupFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameFocus = FocusNode();
  late final TextEditingController _name;
  late final TextEditingController _note;
  late Set<String> _selected;
  late String _preferredUnit;

  @override
  void initState() {
    super.initState();
    final g = widget.group;
    _name = TextEditingController(text: g?.name ?? '');
    _note = TextEditingController(text: g?.note ?? '');
    _selected = {...(g?.productIds ?? const [])};
    _preferredUnit = g?.preferredUnit ?? '';
    if (g == null) {
      scheduleTextFocus(_nameFocus);
    }
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  List<Product> get _selectedProducts => widget.products
      .where((p) => _selected.contains(p.id))
      .toList(growable: false);

  void _submit() {
    final s = AppStrings.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_selected.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.groupNeedTwoProducts)),
      );
      return;
    }
    final common = ComparisonLogic.commonUnits(_selectedProducts);
    if (common.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.compareNeedCommonUnit)),
      );
      return;
    }
    final preferred =
        common.contains(_preferredUnit) ? _preferredUnit : '';
    final base = widget.group;
    final result = base == null
        ? ComparisonGroup(
            name: _name.text.trim(),
            productIds: _selected.toList(),
            note: _note.text.trim(),
            preferredUnit: preferred,
          )
        : base.copyWith(
            name: _name.text.trim(),
            productIds: _selected.toList(),
            note: _note.text.trim(),
            preferredUnit: preferred,
          );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final editing = widget.group != null;
    final common = ComparisonLogic.commonUnits(_selectedProducts);
    final canSave = _selected.length >= 2 && common.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                editing ? s.editFixedGroup : s.addFixedGroup,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                focusNode: _nameFocus,
                autofocus: !editing && !prefersDelayedTextFocus,
                decoration: InputDecoration(
                  labelText: s.groupName,
                  hintText: s.groupNameHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? s.groupNameRequired : null,
              ),
              const SizedBox(height: 16),
              Text(
                s.groupProducts,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                s.groupProductsHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.products.length,
                  itemBuilder: (context, index) {
                    final p = widget.products[index];
                    return CheckboxListTile(
                      dense: true,
                      value: _selected.contains(p.id),
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selected.add(p.id);
                          } else {
                            _selected.remove(p.id);
                          }
                          final commonNow =
                              ComparisonLogic.commonUnits(_selectedProducts);
                          if (_preferredUnit.isNotEmpty &&
                              !commonNow.contains(_preferredUnit)) {
                            _preferredUnit = '';
                          }
                        });
                      },
                      title: Text(p.name),
                      subtitle: Text(p.displayUnit),
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
              ),
              if (_selected.length >= 2) ...[
                const SizedBox(height: 8),
                Text(
                  common.isEmpty
                      ? s.compareNeedCommonUnit
                      : s.commonUnitsReady(common.join(' · ')),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: common.isEmpty ? scheme.error : scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
              if (common.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  s.groupPreferredUnit,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.groupPreferredUnitHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(s.autoUnit),
                      selected: _preferredUnit.isEmpty,
                      onSelected: (_) => setState(() => _preferredUnit = ''),
                    ),
                    for (final unit in common)
                      ChoiceChip(
                        label: Text(unit),
                        selected: _preferredUnit == unit,
                        onSelected: (_) =>
                            setState(() => _preferredUnit = unit),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                decoration: InputDecoration(
                  labelText: s.noteOptional,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: canSave ? _submit : null,
                child: Text(editing ? s.save : s.createAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
