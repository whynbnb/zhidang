import 'package:flutter/material.dart';

import '../app/app_navigator.dart';
import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../services/data_revision.dart';
import '../services/storage_service.dart';
import '../services/unit_store.dart';
import '../settings/app_settings.dart';
import '../utils/layout.dart';
import '../widgets/app_header_actions.dart';
import '../widgets/note_hint.dart';
import '../widgets/offer_tile.dart';
import '../widgets/product_card.dart';
import '../widgets/tag_chips.dart';
import 'offer_counter_sheet.dart';
import 'product_form_sheet.dart';

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
    // Skip full reload when we just saved locally; storage already matches.
    // Still reload for import/clear and external bumps after first paint.
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
      final isWide = AppLayout.isWide(context);
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
    // Advance before bump so this page ignores the self-triggered revision.
    _seenRevision = DataRevision.notifier.value + 1;
    DataRevision.bump();
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
    final product = result?.product;
    if (product == null) return;
    setState(() {
      _products = [product, ..._products];
      _selectedId = product.id;
    });
    await _persist();
  }

  Future<void> _editProduct(Product product) async {
    final result = await showProductForm(context, product: product);
    if (result == null) return;
    if (result.deleted) {
      setState(() {
        _products = _products.where((p) => p.id != product.id).toList();
        if (_selectedId == product.id) {
          final isWide = AppLayout.isWide(context);
          _selectedId =
              isWide && _products.isNotEmpty ? _products.first.id : null;
        }
      });
      await _persist();
      return;
    }
    final saved = result.product;
    if (saved == null) return;
    setState(() {
      _products = _products
          .map((p) => p.id == saved.id ? saved : p)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
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
    final offer = result?.offer;
    if (offer == null) return;
    final units = <String>[...product.units];
    for (final m in offer.measures) {
      if (!units.contains(m.unit)) units.add(m.unit);
    }
    final updated = product.copyWith(
      units: units,
      offers: [...product.offers, offer],
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
    if (result.deleted) {
      final offers = product.offers.where((o) => o.id != offer.id).toList();
      final updated = product.copyWith(offers: offers);
      setState(() {
        _products = _products
            .map((p) => p.id == updated.id ? updated : p)
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      });
      await _persist();
      return;
    }
    final saved = result.offer;
    if (saved == null) return;
    final offers =
        product.offers.map((o) => o.id == saved.id ? saved : o).toList();
    final units = <String>[...product.units];
    for (final m in saved.measures) {
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

  Future<void> _toggleOfferFavorite(Product product, Offer offer) async {
    final offers = product.offers
        .map(
          (o) => o.id == offer.id ? o.copyWith(favorite: !o.favorite) : o,
        )
        .toList();
    final updated = product.copyWith(offers: offers);
    setState(() {
      _products = _products
          .map((p) => p.id == updated.id ? updated : p)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = AppLayout.isWide(context);
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
                      onAddOffer: _addOffer,
                      onEditOffer: _editOffer,
                      onOfferCounter: _openOfferCounter,
                      onToggleFavorite: _toggleOfferFavorite,
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
                      onAddOffer: _addOffer,
                      onEditOffer: _editOffer,
                      onOfferCounter: _openOfferCounter,
                      onToggleFavorite: _toggleOfferFavorite,
                    ),
        ),
        floatingActionButton: isWide || _selected != null
            ? null
            : FloatingActionButton.extended(
                heroTag: 'fab-home-new-product',
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
    required this.onAddOffer,
    required this.onEditOffer,
    required this.onOfferCounter,
    required this.onToggleFavorite,
  });

  final TextEditingController search;
  final List<Product> products;
  final Product? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onOpenSettings;
  final VoidCallback onAddProduct;
  final ValueChanged<Product> onEditProduct;
  final void Function(Product, {String? preferredUnit}) onAddOffer;
  final void Function(Product, Offer) onEditOffer;
  final void Function(Product, Offer) onOfferCounter;
  final void Function(Product, Offer) onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: AppLayout.splitLeftFlex,
          child: _ProductListPane(
            search: search,
            products: products,
            selectedId: selected?.id,
            onSelect: onSelect,
            onOpenSettings: onOpenSettings,
            onAddProduct: onAddProduct,
            onEditProduct: onEditProduct,
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: AppLayout.splitRightFlex,
          child: selected == null
              ? const _EmptyDetail()
              : _ProductDetailPane(
                  key: ValueKey('detail-${selected!.id}'),
                  product: selected!,
                  onEditProduct: () => onEditProduct(selected!),
                  onAddOffer: (unit) =>
                      onAddOffer(selected!, preferredUnit: unit),
                  onEditOffer: (o) => onEditOffer(selected!, o),
                  onOfferCounter: (o) => onOfferCounter(selected!, o),
                  onToggleFavorite: (o) => onToggleFavorite(selected!, o),
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
    required this.onAddOffer,
    required this.onEditOffer,
    required this.onOfferCounter,
    required this.onToggleFavorite,
  });

  final TextEditingController search;
  final List<Product> products;
  final Product? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onBack;
  final VoidCallback onOpenSettings;
  final VoidCallback onAddProduct;
  final ValueChanged<Product> onEditProduct;
  final void Function(Product, {String? preferredUnit}) onAddOffer;
  final void Function(Product, Offer) onEditOffer;
  final void Function(Product, Offer) onOfferCounter;
  final void Function(Product, Offer) onToggleFavorite;

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
            title: selected!.note.isNotEmpty
                ? NoteHintLabel(
                    note: selected!.note,
                    label: s.productCompareTitle(selected!.name),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  )
                : Text(
                    s.productCompareTitle(selected!.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
            subtitle: Row(
              children: [
                Text(
                  s.brandCount(selected!.offers.length),
                  maxLines: 1,
                ),
                if (selected!.tags.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: TagChipRow(
                      tags: selected!.tags,
                      dense: true,
                      singleLine: true,
                    ),
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: s.editProduct,
              onPressed: () => onEditProduct(selected!),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _ProductDetailPane(
            key: ValueKey('detail-mobile-${selected!.id}'),
            product: selected!,
            onEditProduct: () => onEditProduct(selected!),
            onAddOffer: (unit) => onAddOffer(selected!, preferredUnit: unit),
            onEditOffer: (o) => onEditOffer(selected!, o),
            onOfferCounter: (o) => onOfferCounter(selected!, o),
            onToggleFavorite: (o) => onToggleFavorite(selected!, o),
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
  });

  final TextEditingController search;
  final List<Product> products;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onOpenSettings;
  final VoidCallback onAddProduct;
  final ValueChanged<Product> onEditProduct;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppPageHeader(
          title: s.appName,
          leading: Icon(Icons.savings_outlined, color: scheme.primary),
          onOpenSettings: onOpenSettings,
          showCompare: true,
          onTitleDoubleTap: AppNavigator.openQuickCalc,
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
              : ListenableBuilder(
                  listenable: AppSettings.instance,
                  builder: (context, _) {
                    final compact = AppSettings.instance.compactMode;
                    return ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 0 : 12,
                        0,
                        compact ? 0 : 12,
                        88,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: compact ? 0 : 8),
                          child: ProductCard(
                            product: product,
                            selected: product.id == selectedId,
                            compact: compact,
                            onTap: () => onSelect(product.id),
                            onLongPress: () => onEditProduct(product),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
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
    required this.onAddOffer,
    required this.onEditOffer,
    required this.onOfferCounter,
    required this.onToggleFavorite,
    this.compact = false,
  });

  final Product product;
  final VoidCallback onEditProduct;
  final ValueChanged<String?> onAddOffer;
  final ValueChanged<Offer> onEditOffer;
  final ValueChanged<Offer> onOfferCounter;
  final ValueChanged<Offer> onToggleFavorite;
  final bool compact;

  @override
  State<_ProductDetailPane> createState() => _ProductDetailPaneState();
}

enum _OfferViewMode { all, favorites }

class _ProductDetailPaneState extends State<_ProductDetailPane> {
  late String _selectedUnit;
  _OfferViewMode _viewMode = _OfferViewMode.all;

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
      _viewMode = _OfferViewMode.all;
      return;
    }
    final units = widget.product.measureUnits;
    if (!units.contains(_selectedUnit)) {
      _selectedUnit = units.first;
    }
    if (_viewMode == _OfferViewMode.favorites &&
        widget.product.favoriteOffersFor(_selectedUnit).isEmpty) {
      _viewMode = _OfferViewMode.all;
    }
  }

  List<Offer> _visibleOffers(String unit, _OfferViewMode mode) {
    final product = widget.product;
    switch (mode) {
      case _OfferViewMode.all:
        return [...product.offersFor(unit)]
          ..sort((a, b) {
            final pa = product.unitPriceForOffer(a, unit) ?? double.infinity;
            final pb = product.unitPriceForOffer(b, unit) ?? double.infinity;
            return pa.compareTo(pb);
          });
      case _OfferViewMode.favorites:
        return product.favoriteOffersFor(unit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final scheme = Theme.of(context).colorScheme;
    final s = AppStrings.of(context);
    final primaryUnit = normalizeUnit(product.unit);
    final sortedUnits = UnitStore.instance.sortUnits(product.measureUnits);
    final units = [
      if (sortedUnits.contains(primaryUnit)) primaryUnit,
      ...sortedUnits.where((unit) => unit != primaryUnit),
    ];
    final selectedUnit = units.contains(_selectedUnit)
        ? _selectedUnit
        : units.first;
    final hasFavorites =
        product.favoriteOffersFor(selectedUnit).isNotEmpty;
    final viewMode =
        hasFavorites ? _viewMode : _OfferViewMode.all;
    final offers = _visibleOffers(selectedUnit, viewMode);
    final preferred = product.preferredOfferFor(selectedUnit);
    final best = product.bestOfferFor(selectedUnit);

    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final dense = AppSettings.instance.compactMode;
        // Dense offer rows go edge-to-edge; keep header content inset.
        final horizontal = dense ? 0.0 : 20.0;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            widget.compact ? 10 : 16,
            horizontal,
            32,
          ),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: dense ? 20 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!widget.compact) ...[
                    Row(
                      children: [
                        Expanded(
                          child: product.note.isNotEmpty
                              ? NoteHintLabel(
                                  note: product.note,
                                  label: product.name,
                                  maxLines: 1,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                )
                              : Text(
                                  product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                        ),
                        IconButton(
                          onPressed: widget.onEditProduct,
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: s.editProduct,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          s.brandCount(product.offers.length),
                          maxLines: 1,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                        if (product.tags.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: TagChipRow(
                              tags: product.tags,
                              dense: true,
                              singleLine: true,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final showUnits = units.length > 1;
                      final favoritesActive =
                          viewMode == _OfferViewMode.favorites;
                      final favoriteToggle = IconButton(
                        onPressed: () => setState(
                          () => _viewMode = favoritesActive
                              ? _OfferViewMode.all
                              : _OfferViewMode.favorites,
                        ),
                        isSelected: favoritesActive,
                        icon: const Icon(Icons.star_outline, size: 20),
                        selectedIcon: const Icon(Icons.star, size: 20),
                        tooltip: favoritesActive
                            ? s.showAllOffers
                            : s.favoritesOnly,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 36,
                          height: 36,
                        ),
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          foregroundColor: favoritesActive
                              ? scheme.onPrimaryContainer
                              : scheme.onSurfaceVariant,
                          backgroundColor: favoritesActive
                              ? scheme.primaryContainer
                              : Colors.transparent,
                        ),
                      );
                      final addButton = constraints.maxWidth >= 420
                          ? FilledButton.tonalIcon(
                              onPressed: () => widget.onAddOffer(selectedUnit),
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(s.addOffer),
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                            )
                          : IconButton.filledTonal(
                              onPressed: () => widget.onAddOffer(selectedUnit),
                              icon: const Icon(Icons.add, size: 20),
                              tooltip: s.addOffer,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 36,
                                height: 36,
                              ),
                              visualDensity: VisualDensity.compact,
                            );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              if (hasFavorites) ...[
                                favoriteToggle,
                                if (showUnits) ...[
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    height: 20,
                                    child: VerticalDivider(
                                      width: 1,
                                      thickness: 1,
                                      color: scheme.outlineVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ] else
                                  const SizedBox(width: 8),
                              ],
                              if (showUnits) ...[
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        for (final unit in units) ...[
                                          ChoiceChip(
                                            label: Text(
                                              '$unit${product.offersFor(unit).isEmpty ? '' : ' (${product.offersFor(unit).length})'}',
                                            ),
                                            selected: unit == selectedUnit,
                                            visualDensity:
                                                VisualDensity.compact,
                                            onSelected: (_) => setState(() {
                                              _selectedUnit = unit;
                                              if (_viewMode ==
                                                      _OfferViewMode
                                                          .favorites &&
                                                  product
                                                      .favoriteOffersFor(unit)
                                                      .isEmpty) {
                                                _viewMode =
                                                    _OfferViewMode.all;
                                              }
                                            }),
                                          ),
                                          if (unit != units.last)
                                            const SizedBox(width: 6),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ] else ...[
                                // No unit chips: show the dimension here so
                                // the row stays balanced and the unit is
                                // never lost.
                                Text(
                                  s.measureUnitsLabel(units.join(' / ')),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                                const Spacer(),
                              ],
                              addButton,
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            if (offers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 40,
                ),
                child: Column(
                  children: [
                    Icon(
                      viewMode == _OfferViewMode.favorites
                          ? Icons.star_outline
                          : Icons.price_change_outlined,
                      size: 48,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      viewMode == _OfferViewMode.favorites
                          ? s.noFavoriteOffers
                          : s.noOffers,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      viewMode == _OfferViewMode.favorites
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
              Column(
                children: [
                  for (var i = 0; i < offers.length; i++)
                    Padding(
                      padding: EdgeInsets.only(bottom: dense ? 0 : 8),
                      child: OfferTile(
                        key: ValueKey(
                          'offer-${offers[i].id}-$selectedUnit-$viewMode',
                        ),
                        offer: offers[i],
                        unit: selectedUnit,
                        quantity:
                            product.quantityForOffer(offers[i], selectedUnit),
                        unitPrice:
                            product.unitPriceForOffer(offers[i], selectedUnit),
                        isBest: best != null && offers[i].id == best.id,
                        isPreferred: preferred != null &&
                            offers[i].id == preferred.id,
                        rank: i + 1,
                        compact: dense,
                        onEdit: () => widget.onEditOffer(offers[i]),
                        onToggleFavorite: () =>
                            widget.onToggleFavorite(offers[i]),
                        onCounterTap: offers[i].counterMode.enabled
                            ? () => widget.onOfferCounter(offers[i])
                            : null,
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}
