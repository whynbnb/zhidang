import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/app_navigator.dart';
import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../services/storage_service.dart';
import '../widgets/offer_tile.dart';
import '../widgets/product_card.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() {
      setState(() => _query = _search.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
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
      if (_selectedId == null && _products.isNotEmpty) {
        _selectedId = _products.first.id;
      }
    });
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
            p.offers.any((o) => o.brand.toLowerCase().contains(_query)))
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
        _selectedId = _products.isEmpty ? null : _products.first.id;
      }
    });
    await _persist();
  }

  Future<void> _addOffer(Product product) async {
    final result = await showOfferForm(context, unit: product.unit);
    if (result == null) return;
    final updated = product.copyWith(offers: [...product.offers, result]);
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
    final result =
        await showOfferForm(context, offer: offer, unit: product.unit);
    if (result == null) return;
    final offers =
        product.offers.map((o) => o.id == result.id ? result : o).toList();
    final updated = product.copyWith(offers: offers);
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 840;
    final s = AppStrings.of(context);

    return Scaffold(
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
                  )
                : _NarrowLayout(
                    search: _search,
                    products: _filtered,
                    selected: _selected,
                    onSelect: (id) => setState(() => _selectedId = id),
                    onBack: () => setState(() => _selectedId = null),
                    onOpenSettings: _openSettings,
                    onAddProduct: _addProduct,
                    onEditProduct: _editProduct,
                    onDeleteProduct: _deleteProduct,
                    onAddOffer: _addOffer,
                    onEditOffer: _editOffer,
                    onDeleteOffer: _deleteOffer,
                  ),
      ),
      floatingActionButton: isWide || _selected != null
          ? null
          : FloatingActionButton.extended(
              onPressed: _addProduct,
              icon: const Icon(Icons.add),
              label: Text(s.newProduct),
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
  });

  final TextEditingController search;
  final List<Product> products;
  final Product? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onOpenSettings;
  final VoidCallback onAddProduct;
  final ValueChanged<Product> onEditProduct;
  final ValueChanged<Product> onDeleteProduct;
  final ValueChanged<Product> onAddOffer;
  final void Function(Product, Offer) onEditOffer;
  final void Function(Product, Offer) onDeleteOffer;

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
                  product: selected!,
                  onEditProduct: () => onEditProduct(selected!),
                  onDeleteProduct: () => onDeleteProduct(selected!),
                  onAddOffer: () => onAddOffer(selected!),
                  onEditOffer: (o) => onEditOffer(selected!, o),
                  onDeleteOffer: (o) => onDeleteOffer(selected!, o),
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
  final ValueChanged<Product> onAddOffer;
  final void Function(Product, Offer) onEditOffer;
  final void Function(Product, Offer) onDeleteOffer;

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
            subtitle: Text(s.unitLabel(selected!.unit)),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _ProductDetailPane(
            product: selected!,
            onEditProduct: () => onEditProduct(selected!),
            onDeleteProduct: () => onDeleteProduct(selected!),
            onAddOffer: () => onAddOffer(selected!),
            onEditOffer: (o) => onEditOffer(selected!, o),
            onDeleteOffer: (o) => onDeleteOffer(selected!, o),
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

class _ProductDetailPane extends StatelessWidget {
  const _ProductDetailPane({
    required this.product,
    required this.onEditProduct,
    required this.onDeleteProduct,
    required this.onAddOffer,
    required this.onEditOffer,
    required this.onDeleteOffer,
    this.compact = false,
  });

  final Product product;
  final VoidCallback onEditProduct;
  final VoidCallback onDeleteProduct;
  final VoidCallback onAddOffer;
  final ValueChanged<Offer> onEditOffer;
  final ValueChanged<Offer> onDeleteOffer;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = AppStrings.of(context);
    final offers = [...product.offers]
      ..sort((a, b) => a.unitPrice.compareTo(b.unitPrice));
    final best = offers.isEmpty ? null : offers.first;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, compact ? 8 : 20, 20, 32),
      children: [
        if (!compact) ...[
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
                onPressed: onEditProduct,
                icon: const Icon(Icons.edit_outlined),
                tooltip: s.editProduct,
              ),
              IconButton(
                onPressed: onDeleteProduct,
                icon: const Icon(Icons.delete_outline),
                tooltip: s.deleteProduct,
              ),
            ],
          ),
          Text(
            s.measureUnit(product.unit),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
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
                onPressed: onEditProduct,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(s.edit),
              ),
              TextButton.icon(
                onPressed: onDeleteProduct,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(s.delete),
              ),
            ],
          ),
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
                          s.bestValueNow,
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
                    '¥${_currency.format(best.unitPrice)} / ${product.unit}',
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
              s.brandCompare,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: onAddOffer,
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
                offer: offer,
                unit: product.unit,
                isBest: i == 0,
                rank: i + 1,
                onEdit: () => onEditOffer(offer),
                onDelete: () => onDeleteOffer(offer),
              ),
            );
          }),
      ],
    );
  }
}
