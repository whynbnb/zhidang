import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../services/storage_service.dart';
import '../utils/quick_calc.dart';

/// One saved offer flattened into the fields the quick converter understands.
class QuickOfferPick {
  const QuickOfferPick({
    required this.name,
    required this.price,
    required this.quantity,
    required this.unit,
  });

  final String name;
  final double price;
  final double quantity;
  final String unit;
}

/// Lets the quick converter pull offers that were already saved with a
/// product, instead of typing the price and size again.
Future<List<QuickOfferPick>?> showQuickOfferPicker(BuildContext context) {
  return showModalBottomSheet<List<QuickOfferPick>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _QuickOfferPickerSheet(),
  );
}

class _PickRow {
  const _PickRow(this.product, this.offer);

  final Product product;
  final Offer offer;
}

class _QuickOfferPickerSheet extends StatefulWidget {
  const _QuickOfferPickerSheet();

  @override
  State<_QuickOfferPickerSheet> createState() => _QuickOfferPickerSheetState();
}

class _QuickOfferPickerSheetState extends State<_QuickOfferPickerSheet> {
  final _storage = StorageService();
  final _search = TextEditingController();
  final _selected = <String>{};

  List<Product> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final products = await _storage.loadProducts();
    if (!mounted) return;
    setState(() {
      _products = products;
      _loading = false;
    });
  }

  bool _matches(_PickRow row, String query) {
    if (query.isEmpty) return true;
    final offer = row.offer;
    return row.product.name.toLowerCase().contains(query) ||
        row.product.tags.any((t) => t.toLowerCase().contains(query)) ||
        offer.brand.toLowerCase().contains(query) ||
        offer.shop.toLowerCase().contains(query) ||
        offer.shopArea.toLowerCase().contains(query) ||
        offer.note.toLowerCase().contains(query) ||
        offer.tags.any((t) => t.toLowerCase().contains(query));
  }

  String _entryName(Product product, Offer offer) {
    final brand = offer.brand.trim();
    if (brand.isEmpty || brand == product.name.trim()) return product.name;
    return '${product.name} · $brand';
  }

  void _confirm() {
    final picks = <QuickOfferPick>[];
    for (final product in _products) {
      for (final offer in product.offers) {
        if (!_selected.contains(offer.id)) continue;
        if (offer.quantity <= 0 || offer.unit.isEmpty) continue;
        picks.add(
          QuickOfferPick(
            name: _entryName(product, offer),
            price: offer.price,
            quantity: offer.quantity,
            unit: offer.unit,
          ),
        );
      }
    }
    Navigator.of(context).pop(picks);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final query = _search.text.trim().toLowerCase();

    final rows = <_PickRow>[];
    for (final product in _products) {
      final offers = product.offers
          .where((offer) => offer.quantity > 0 && offer.unit.isNotEmpty)
          .toList()
        ..sort((a, b) => a.unitPrice.compareTo(b.unitPrice));
      for (final offer in offers) {
        final row = _PickRow(product, offer);
        if (_matches(row, query)) rows.add(row);
      }
    }
    final grouped = <String, List<_PickRow>>{};
    for (final row in rows) {
      grouped.putIfAbsent(row.product.id, () => []).add(row);
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.quickCalcPickSavedTitle,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            s.quickCalcPickSavedHint,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
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
              maxHeight: MediaQuery.sizeOf(context).height * 0.5,
            ),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : rows.isEmpty
                    ? _buildEmpty(context, s)
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          for (final group in grouped.values)
                            _buildGroup(context, s, group),
                        ],
                      ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _selected.isEmpty ? null : _confirm,
            child: Text(s.quickCalcPickSavedConfirm(_selected.length)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, AppStrings s) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 44,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(s.quickCalcPickSavedEmpty, style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            s.quickCalcPickSavedEmptyHint,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(
    BuildContext context,
    AppStrings s,
    List<_PickRow> rows,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
          child: Text(
            rows.first.product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final row in rows) _buildRow(context, s, row),
      ],
    );
  }

  Widget _buildRow(BuildContext context, AppStrings s, _PickRow row) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final offer = row.offer;
    final checked = _selected.contains(offer.id);
    final brand = offer.brand.trim();
    final title = brand.isNotEmpty
        ? brand
        : (offer.shopLabel.isNotEmpty
            ? offer.shopLabel
            : s.quickCalcPickSavedDefault);
    final details = <String>[
      '¥${formatCalcNumber(offer.price)} / '
          '${formatCalcNumber(offer.quantity)}${offer.unit}',
      if (offer.shopLabel.isNotEmpty && offer.shopLabel != title)
        offer.shopLabel,
    ].join(' · ');

    void toggle() {
      setState(() {
        if (!_selected.remove(offer.id)) _selected.add(offer.id);
      });
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: checked
            ? scheme.primaryContainer.withValues(alpha: 0.35)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: checked ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: toggle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
            child: Row(
              children: [
                Checkbox(
                  value: checked,
                  onChanged: (_) => toggle(),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (offer.limitedPrice) ...[
                            const SizedBox(width: 6),
                            _LimitedBadge(label: s.limitedBadge),
                          ],
                        ],
                      ),
                      Text(
                        details,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '¥${formatCalcNumber(offer.unitPrice)}',
                      style: textTheme.titleSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '/ ${offer.unit}',
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LimitedBadge extends StatelessWidget {
  const _LimitedBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onTertiaryContainer,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
