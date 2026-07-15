import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../services/supplier_store.dart';
import '../utils/quantity_presets.dart';

Future<Product?> showProductForm(
  BuildContext context, {
  Product? product,
}) {
  return showModalBottomSheet<Product>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ProductFormSheet(product: product),
  );
}

class _ProductFormSheet extends StatefulWidget {
  const _ProductFormSheet({this.product});

  final Product? product;

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _note;
  late String _unit;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.product?.name ?? '');
    _note = TextEditingController(text: widget.product?.note ?? '');
    _unit = widget.product?.unit ?? 'g';
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final base = widget.product;
    final result = base == null
        ? Product(name: _name.text.trim(), unit: _unit, note: _note.text.trim())
        : base.copyWith(
            name: _name.text.trim(),
            unit: _unit,
            note: _note.text.trim(),
          );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final editing = widget.product != null;
    final s = AppStrings.of(context);
    final units = {...s.unitOptions, if (!s.unitOptions.contains(_unit)) _unit}
        .toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editing ? s.editProduct : s.newProduct,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              autofocus: !editing,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: s.productName,
                hintText: s.productNameHint,
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? s.productNameRequired : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _unit,
              decoration: InputDecoration(
                labelText: s.unitOfMeasure,
                border: const OutlineInputBorder(),
              ),
              items: units
                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _unit = v);
              },
            ),
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
              onPressed: _submit,
              child: Text(editing ? s.save : s.createAction),
            ),
          ],
        ),
      ),
    );
  }
}

Future<Offer?> showOfferForm(
  BuildContext context, {
  Offer? offer,
  required String unit,
}) {
  return showModalBottomSheet<Offer>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _OfferFormSheet(offer: offer, unit: unit),
  );
}

class _OfferFormSheet extends StatefulWidget {
  const _OfferFormSheet({this.offer, required this.unit});

  final Offer? offer;
  final String unit;

  @override
  State<_OfferFormSheet> createState() => _OfferFormSheetState();
}

class _OfferFormSheetState extends State<_OfferFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _brand;
  late final TextEditingController _price;
  late final TextEditingController _quantity;
  late final TextEditingController _shop;
  late final TextEditingController _note;
  late final TextEditingValue _shopInitial;

  @override
  void initState() {
    super.initState();
    final o = widget.offer;
    _brand = TextEditingController(text: o?.brand ?? '');
    _price = TextEditingController(
      text: o == null ? '' : _fmt(o.price),
    );
    _quantity = TextEditingController(
      text: o == null ? '' : _fmt(o.quantity),
    );
    final shopText = o?.shop ?? '';
    _shop = TextEditingController(text: shopText);
    _shopInitial = TextEditingValue(text: shopText);
    _note = TextEditingController(text: o?.note ?? '');
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }

  @override
  void dispose() {
    _brand.dispose();
    _price.dispose();
    _quantity.dispose();
    _shop.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final price = double.parse(_price.text.trim());
    final quantity = double.parse(_quantity.text.trim());
    final shop = _shop.text.trim();
    if (shop.isNotEmpty) {
      await SupplierStore.instance.ensureName(shop);
    }
    final base = widget.offer;
    final result = base == null
        ? Offer(
            brand: _brand.text.trim(),
            price: price,
            quantity: quantity,
            shop: shop,
            note: _note.text.trim(),
          )
        : base.copyWith(
            brand: _brand.text.trim(),
            price: price,
            quantity: quantity,
            shop: shop,
            note: _note.text.trim(),
          );
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  String? _positiveNumber(String? v, AppStrings s) {
    if (v == null || v.trim().isEmpty) return s.requiredField;
    final n = double.tryParse(v.trim());
    if (n == null) return s.enterNumber;
    if (n <= 0) return s.mustBePositive;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final editing = widget.offer != null;
    final unit = widget.unit;
    final s = AppStrings.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editing ? s.editOffer : s.addOffer,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _brand,
              autofocus: !editing,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: s.brandOrSpec,
                hintText: s.brandHint,
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? s.brandRequired : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: s.totalPrice,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => _positiveNumber(v, s),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _quantity,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: s.quantityLabel(unit),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => _positiveNumber(v, s),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                s.quantityQuickPick,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in quantityPresetsFor(unit))
                  ActionChip(
                    label: Text(preset.label),
                    onPressed: () {
                      final text = formatQuantityValue(preset.value);
                      setState(() {
                        _quantity.text = text;
                        _quantity.selection = TextSelection.collapsed(
                          offset: text.length,
                        );
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final options = SupplierStore.instance.names;
                return RawAutocomplete<String>(
                  initialValue: _shopInitial,
                  optionsBuilder: (value) {
                    final current = SupplierStore.instance.names;
                    final q = value.text.trim().toLowerCase();
                    if (q.isEmpty) return current;
                    return current
                        .where((name) => name.toLowerCase().contains(q));
                  },
                  onSelected: (value) {
                    _shop.text = value;
                  },
                  displayStringForOption: (v) => v,
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: s.shopOptional,
                        hintText:
                            options.isEmpty ? s.shopHint : s.selectSupplier,
                        border: const OutlineInputBorder(),
                        suffixIcon: options.isEmpty
                            ? null
                            : const Icon(Icons.arrow_drop_down),
                      ),
                      onChanged: (v) => _shop.text = v,
                      onFieldSubmitted: (_) => onFieldSubmitted(),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, opts) {
                    final list = opts.toList();
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 200,
                            maxWidth: 360,
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              final option = list[index];
                              return ListTile(
                                dense: true,
                                leading: const Icon(
                                  Icons.storefront_outlined,
                                  size: 18,
                                ),
                                title: Text(option),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
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
              onPressed: _submit,
              child: Text(editing ? s.save : s.add),
            ),
          ],
        ),
      ),
    );
  }
}
