import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/app_navigator.dart';
import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../services/data_revision.dart';
import '../services/storage_service.dart';
import '../widgets/offer_tile.dart';
import '../widgets/product_card.dart';
import '../widgets/tag_chips.dart';
import 'offer_counter_sheet.dart';
import 'product_form_sheet.dart';

final _currency = NumberFormat('#,##0.##');

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _storage = StorageService();
  final _search = TextEditingController();

  List<Product> _products = [];
  String? _selectedId;
  bool _loading = true;
  String _query = '';
  int _seenRevision = DataRevision.notifier.value;

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() {
      setState(() => _query = _search.text.trim().toLowerCase());
    });
    DataRevision.notifier.addListener(_onDataRevision);
  }

  void _onDataRevision() {
    final rev = DataRevision.notifier.value;
    if (rev == _seenRevision) return;
    _seenRevision = rev;
    _load();
  }

  @override
  void dispose() {
    DataRevision.notifier.removeListener(_onDataRevision);
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await _storage.loadProducts();
    if (!mounted) return;
    setState(() {
      _products = items;
      _loading = false;
      if (_selectedId != null && !_products.any((p) => p.id == _selectedId)) {
        _selectedId = null;
      }
      // Wide layout can preselect for split view; phone always starts on list.
      final isWide = MediaQuery.sizeOf(context).width >= 840;
      if (isWide && _selectedId == null && _products.isNotEmpty) {
        _selectedId = _products.first.id;
      }
    });
  }

  void _clearSelection() {
    if (_selectedId == null) return;
    setState(() => _selectedId = null);
  }

  Future<void> _persist() async {
    await _storage.saveProducts(_products);
  }

  Product? get _selected {
    if (_selectedId == null) return null;
    for (final p in _products) {
      if (p.id == _selectedId) return p;
    }
    return null;
  }

  List<Product> get _filtered {
    if (_query.isEmpty) return _products;
    return _products
        .where((p) =>
            p.name.toLowerCase().contains(_query) ||
            p.note.toLowerCase().contains(_query) ||
            p.tags.any((t) => t.toLowerCase().contains(_query)) ||
            p.offers.any((o) =>
                o.brand.toLowerCase().contains(_query) ||
                o.tags.any((t) => t.toLowerCase().contains(_query))))
        .toList();
  }

  Future<void> _openSettings() => AppNavigator.openSettings();

  Future<void> _addProduct() async {
    final result = await showProductForm(context);
    if (result == null) return;
    setState(() {
      _products = [result, ..._products];
      _selectedId = result.id;
    });
    await _persist();
  }

  Future<void> _editProduct(Product product) async {
    final result = await showProductForm(context, product: product);
    if (result == null) return;
    setState(() {
      _products = _products
          .map((p) => p.id == result.id ? result : p)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });
    await _persist();
  }

  Future<void> _deleteProduct(Product product) async {
    final s = AppStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.deleteProduct),
        content: Text(s.deleteProductConfirm(product.name)),
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
    if (ok != true) return;
    setState(() {
      _products = _products.where((p) => p.id != product.id).toList();
      if (_selectedId == product.id) {
        final isWide = MediaQuery.sizeOf(context).width >= 840;
        _selectedId =
            isWide && _products.isNotEmpty ? _products.first.id : null;
      }
    });
    await _persist();
  }

  Future<void> _addOffer(Product product, {String? preferredUnit}) async {
    final unit =
        normalizeUnit(preferredUnit ?? product.unit, fallback: product.unit);
    final result = await showOfferForm(
      context,
      units: product.measureUnits,
      defaultRelations: product.relations,
      preferredUnit: unit,
    );
    if (result == null) return;
    final units = <String>[...product.units];
    for (final m in result.measures) {
      if (!units.contains(m.unit)) units.add(m.unit);
    }
    final updated = product.copyWith(
      units: units,
      offers: [...product.offers, result],
    );
    setState(() {
      _products = _products
          .map((p) => p.id == updated.id ? updated : p)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _selectedId = updated.id;
    });
    await _persist();
  }

  Future<void> _editOffer(Product product, Offer offer) async {
    final result = await showOfferForm(
      context,
      offer: offer,
      units: product.measureUnits,
      defaultRelations: product.relations,
      preferredUnit: offer.unit,
    );
    if (result == null) return;
    final offers =
        product.offers.map((o) => o.id == result.id ? result : o).toList();
    final units = <String>[...product.units];
    for (final m in result.measures) {
      if (!units.contains(m.unit)) units.add(m.unit);
    }
    final updated = product.copyWith(units: units, offers: offers);
    setState(() {
      _products = _products
          .map((p) => p.id == updated.id ? updated : p)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });
    await _persist();
  }

  Future<void> _deleteOffer(Product product, Offer offer) async {
    final s = AppStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.deleteOffer),
        content: Text(s.deleteOfferConfirm(offer.brand)),
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
    if (ok != true) return;
    final offers = product.offers.where((o) => o.id != offer.id).toList();
    final updated = product.copyWith(offers: offers);
    setState(() {
      _products = _products
          .map((p) => p.id == updated.id ? updated : p)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });
    await _persist();
  }

  Future<void> _openOfferCounter(Product product, Offer offer) async {
    if (!offer.counterMode.enabled) return;
    await showOfferCounterSheet(
      context,
      offer: offer,
      onChanged: (updatedOffer) {
        final current = _products.firstWhere(
          (p) => p.id == product.id,
          orElse: () => product,
        );
        final offers = current.offers
            .map((o) => o.id == updatedOffer.id ? updatedOffer : o)
            .toList();
        final updated = current.copyWith(offers: offers);
        setState(() {
          _products = _products
              .map((p) => p.id == updated.id ? updated : p)
              .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        });
        _persist();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 840;
    final s = AppStrings.of(context);
    final inDetail = !isWide && _selected != null;

    return PopScope(
      canPop: !inDetail,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (inDetail) _clearSelection();
      },
      child: Scaffold(
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : isWide
                  ? _WideLayout(
                      search: _search,
                      products: _filtered,
                      selected: _selected,
                      onSelect: (id) => setState(() => _selectedId = id),
                      onOpenSettings: _openSettings,
                      onAddProduct: _addProduct,
                      onEditProduct: _editProduct,
                      onDeleteProduct: _deleteProduct,
                      onAddOffer: _addOffer,
                      onEditOffer: _editOffer,
                      onDeleteOffer: _deleteOffer,
                      onOfferCounter: _openOfferCounter,
                    )
                  : _NarrowLayout(
                      search: _search,
                      products: _filtered,
                      selected: _selected,
                      onSelect: (id) => setState(() => _selectedId = id),
                      onBack: _clearSelection,
                      onOpenSettings: _openSettings,
                      onAddProduct: _addProduct,
                      onEditProduct: _editProduct,
                      onDeleteProduct: _deleteProduct,
                      onAddOffer: _addOffer,
                      onEditOffer: _editOffer,
                      onDeleteOffer: _deleteOffer,
                      onOfferCounter: _openOfferCounter,
                    ),
        ),
        floatingActionButton: isWide || _selected != null
            ? null
            : FloatingActionButton.extended(
                onPressed: _addProduct,
                icon: const Icon(Icons.add),
                label: Text(s.newProduct),
              ),
      ),
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.search,
    required this.products,
    required this.selected,
    required this.onSelect,
    required this.onOpenSettings,
    required this.onAddProduct,
    required this.onEditProduct,
    required this.onDeleteProduct,
    required this.onAddOffer,
    required this.onEditOffer,
    required this.onDeleteOffer,
    required this.onOfferCounter,
  });

  final TextEditingController search;
  final List<Product> products;
  final Product? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onOpenSettings;
  final VoidCallback onAddProduct;
  final ValueChanged<Product> onEditProduct;
  final ValueChanged<Product> onDeleteProduct;
  final void Function(Product, {String? preferredUnit}) onAddOffer;
  final void Function(Product, Offer) onEditOffer;
  final void Function(Product, Offer) onDeleteOffer;
  final void Function(Product, Offer) onOfferCounter;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 360,
          child: _ProductListPane(
            search: search,
            products: products,
            selectedId: selected?.id,
            onSelect: onSelect,
            onOpenSettings: onOpenSettings,
            onAddProduct: onAddProduct,
            onEditProduct: onEditProduct,
            onDeleteProduct: onDeleteProduct,
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: selected == null
              ? const _EmptyDetail()
              : _ProductDetailPane(
                  key: ValueKey('detail-${selected!.id}'),
                  product: selected!,
                  onEditProduct: () => onEditProduct(selected!),
                  onDeleteProduct: () => onDeleteProduct(selected!),
                  onAddOffer: (unit) =>
                      onAddOffer(selected!, preferredUnit: unit),
                  onEditOffer: (o) => onEditOffer(selected!, o),
                  onDeleteOffer: (o) => onDeleteOffer(selected!, o),
                  onOfferCounter: (o) => onOfferCounter(selected!, o),
                ),
        ),
      ],
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({
    required this.search,
    required this.products,
    required this.selected,
    required this.onSelect,
    required this.onBack,
    required this.onOpenSettings,
    required this.onAddProduct,
    required this.onEditProduct,
    required this.onDeleteProduct,
    required this.onAddOffer,
    required this.onEditOffer,
    required this.onDeleteOffer,
    required this.onOfferCounter,
  });

  final TextEditingController search;
  final List<Product> products;
  final Product? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onBack;
  final VoidCallback onOpenSettings;
  final VoidCallback onAddProduct;
  final ValueChanged<Product> onEditProduct;
  final ValueChanged<Product> onDeleteProduct;
  final void Function(Product, {String? preferredUnit}) onAddOffer;
  final void Function(Product, Offer) onEditOffer;
  final void Function(Product, Offer) onDeleteOffer;
  final void Function(Product, Offer) onOfferCounter;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    if (selected == null) {
      return _ProductListPane(
        search: search,
        products: products,
        selectedId: null,
        onSelect: onSelect,
        onOpenSettings: onOpenSettings,
        onAddProduct: onAddProduct,
        onEditProduct: onEditProduct,
        onDeleteProduct: onDeleteProduct,
      );
    }

    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: ListTile(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
              tooltip: s.backToList,
            ),
            title: Text(
              selected!.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(s.measureUnitsLabel(selected!.measureUnits.join(' / '))),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _ProductDetailPane(
            key: ValueKey('detail-mobile-${selected!.id}'),
            product: selected!,
            onEditProduct: () => onEditProduct(selected!),
            onDeleteProduct: () => onDeleteProduct(selected!),
            onAddOffer: (unit) => onAddOffer(selected!, preferredUnit: unit),
            onEditOffer: (o) => onEditOffer(selected!, o),
            onDeleteOffer: (o) => onDeleteOffer(selected!, o),
            onOfferCounter: (o) => onOfferCounter(selected!, o),
            compact: true,
          ),
        ),
      ],
    );
  }
}

class _ProductListPane extends StatelessWidget {
  const _ProductListPane({
    required this.search,
    required this.products,
    required this.selectedId,
    required this.onSelect,
    required this.onOpenSettings,
    required this.onAddProduct,
    required this.onEditProduct,
    required this.onDeleteProduct,
  });

  final TextEditingController search;
  final List<Product> products;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onOpenSettings;
  final VoidCallback onAddProduct;
  final ValueChanged<Product> onEditProduct;
  final ValueChanged<Product> onDeleteProduct;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
          child: Row(
            children: [
              Icon(Icons.savings_outlined, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.appName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              IconButton(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings_outlined),
                tooltip: s.settings,
              ),
              FilledButton.tonalIcon(
                onPressed: onAddProduct,
                icon: const Icon(Icons.add),
                label: Text(s.create),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: search,
            decoration: InputDecoration(
              hintText: s.searchHint,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              isDense: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Text(
            products.isEmpty ? s.noProducts : s.productCount(products.length),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          child: products.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.compare_arrows_rounded,
                          size: 56,
                          color: scheme.primary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          s.emptyHintTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.emptyHintBody,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: onAddProduct,
                          icon: const Icon(Icons.add),
                          label: Text(s.addFirstProduct),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ProductCard(
                        product: product,
                        selected: product.id == selectedId,
                        onTap: () => onSelect(product.id),
                        onLongPress: () => _showProductMenu(
                          context,
                          product,
                          onEditProduct,
                          onDeleteProduct,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showProductMenu(
    BuildContext context,
    Product product,
    ValueChanged<Product> onEdit,
    ValueChanged<Product> onDelete,
  ) {
    final s = AppStrings.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(s.editProduct),
              onTap: () {
                Navigator.pop(context);
                onEdit(product);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                s.deleteProduct,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                onDelete(product);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail();

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Center(
      child: Text(
        s.selectProductHint,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _ProductDetailPane extends StatefulWidget {
  const _ProductDetailPane({
    super.key,
    required this.product,
    required this.onEditProduct,
    required this.onDeleteProduct,
    required this.onAddOffer,
    required this.onEditOffer,
    required this.onDeleteOffer,
    required this.onOfferCounter,
    this.compact = false,
  });

  final Product product;
  final VoidCallback onEditProduct;
  final VoidCallback onDeleteProduct;
  final ValueChanged<String?> onAddOffer;
  final ValueChanged<Offer> onEditOffer;
  final ValueChanged<Offer> onDeleteOffer;
  final ValueChanged<Offer> onOfferCounter;
  final bool compact;

  @override
  State<_ProductDetailPane> createState() => _ProductDetailPaneState();
}

class _ProductDetailPaneState extends State<_ProductDetailPane> {
  late String _selectedUnit;

  @override
  void initState() {
    super.initState();
    _selectedUnit = normalizeUnit(widget.product.unit);
  }

  @override
  void didUpdateWidget(covariant _ProductDetailPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id) {
      _selectedUnit = normalizeUnit(widget.product.unit);
      return;
    }
    final units = widget.product.measureUnits;
    if (!units.contains(_selectedUnit)) {
      _selectedUnit = units.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final scheme = Theme.of(context).colorScheme;
    final s = AppStrings.of(context);
    final units = product.measureUnits;
    final selectedUnit = units.contains(_selectedUnit)
        ? _selectedUnit
        : units.first;
    final offers = [...product.offersFor(selectedUnit)]
      ..sort((a, b) {
        final pa = a.unitPriceFor(selectedUnit) ?? double.infinity;
        final pb = b.unitPriceFor(selectedUnit) ?? double.infinity;
        return pa.compareTo(pb);
      });
    final best = product.bestOfferFor(selectedUnit);
    final bestPrice = best?.unitPriceFor(selectedUnit);

    return ListView(
      padding: EdgeInsets.fromLTRB(20, widget.compact ? 8 : 20, 20, 32),
      children: [
        if (!widget.compact) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              IconButton(
                onPressed: widget.onEditProduct,
                icon: const Icon(Icons.edit_outlined),
                tooltip: s.editProduct,
              ),
              IconButton(
                onPressed: widget.onDeleteProduct,
                icon: const Icon(Icons.delete_outline),
                tooltip: s.deleteProduct,
              ),
            ],
          ),
          Text(
            s.measureUnitsLabel(units.join(' / ')),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          if (product.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            TagChipRow(tags: product.tags),
          ],
          if (product.note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(product.note),
          ],
          const SizedBox(height: 16),
        ] else ...[
          Row(
            children: [
              const Spacer(),
              TextButton.icon(
                onPressed: widget.onEditProduct,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(s.edit),
              ),
              TextButton.icon(
                onPressed: widget.onDeleteProduct,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(s.delete),
              ),
            ],
          ),
          if (product.tags.isNotEmpty) ...[
            TagChipRow(tags: product.tags),
            const SizedBox(height: 8),
          ],
        ],
        if (units.length > 1) ...[
          Text(
            s.compareByDimension,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final unit in units)
                ChoiceChip(
                  label: Text(
                    '$unit${product.offersFor(unit).isEmpty ? '' : ' (${product.offersFor(unit).length})'}',
                  ),
                  selected: unit == selectedUnit,
                  onSelected: (_) => setState(() => _selectedUnit = unit),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (best != null)
          Card(
            elevation: 0,
            color: scheme.primaryContainer.withValues(alpha: 0.55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.emoji_events_outlined, color: scheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${s.bestValueNow} · $selectedUnit',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: scheme.onPrimaryContainer,
                                  ),
                        ),
                        Text(
                          best.brand,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '¥${_currency.format(bestPrice ?? 0)} / $selectedUnit',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              '${s.brandCompare} · $selectedUnit',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => widget.onAddOffer(selectedUnit),
              icon: const Icon(Icons.add),
              label: Text(s.addOffer),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (offers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Icon(
                  Icons.price_change_outlined,
                  size: 48,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  s.noOffers,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  s.noOffersHint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          )
        else
          ...List.generate(offers.length, (i) {
            final offer = offers[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OfferTile(
                key: ValueKey('offer-${offer.id}-$selectedUnit'),
                offer: offer,
                unit: selectedUnit,
                isBest: i == 0,
                rank: i + 1,
                onEdit: () => widget.onEditOffer(offer),
                onDelete: () => widget.onDeleteOffer(offer),
                onCounterTap: offer.counterMode.enabled
                    ? () => widget.onOfferCounter(offer)
                    : null,
              ),
            );
          }),
      ],
    );
  }
}
