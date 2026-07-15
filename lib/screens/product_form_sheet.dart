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
  late Set<String> _units;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.product?.name ?? '');
    _note = TextEditingController(text: widget.product?.note ?? '');
    _units = {...(widget.product?.units ?? const ['g'])};
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_units.isEmpty) return;
    final selected = _units.toList();
    final base = widget.product;
    final result = base == null
        ? Product(
            name: _name.text.trim(),
            units: selected,
            note: _note.text.trim(),
          )
        : base.copyWith(
            name: _name.text.trim(),
            units: selected,
            note: _note.text.trim(),
          );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final editing = widget.product != null;
    final s = AppStrings.of(context);
    final options = {
      ...s.unitOptions,
      ..._units,
      if (widget.product != null) ...widget.product!.measureUnits,
    }.toList();

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
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? s.productNameRequired
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                s.measureDimensions,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                s.measureDimensionsHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final unit in options)
                    FilterChip(
                      label: Text(unit),
                      selected: _units.contains(unit),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _units.add(unit);
                          } else if (_units.length > 1) {
                            _units.remove(unit);
                          }
                        });
                      },
                    ),
                ],
              ),
              if (_units.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    s.measureDimensionRequired,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
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
                onPressed: _units.isEmpty ? null : _submit,
                child: Text(editing ? s.save : s.createAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<Offer?> showOfferForm(
  BuildContext context, {
  Offer? offer,
  required List<String> units,
  String? preferredUnit,
}) {
  return showModalBottomSheet<Offer>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _OfferFormSheet(
      offer: offer,
      units: units,
      preferredUnit: preferredUnit,
    ),
  );
}

class _OfferFormSheet extends StatefulWidget {
  const _OfferFormSheet({
    this.offer,
    required this.units,
    this.preferredUnit,
  });

  final Offer? offer;
  final List<String> units;
  final String? preferredUnit;

  @override
  State<_OfferFormSheet> createState() => _OfferFormSheetState();
}

class _OfferFormSheetState extends State<_OfferFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _brand;
  late final TextEditingController _price;
  late final TextEditingController _shop;
  late final TextEditingController _note;
  late final TextEditingValue _shopInitial;
  late final List<String> _availableUnits;
  late final Map<String, TextEditingController> _qtyControllers;
  String? _activePresetUnit;
  String? _measureError;

  @override
  void initState() {
    super.initState();
    final o = widget.offer;
    final baseUnits = widget.units.isNotEmpty
        ? widget.units.map(normalizeUnit).toList()
        : ['g'];
    final fromOffer = o?.measureUnits ?? const <String>[];
    _availableUnits = {
      ...baseUnits,
      ...fromOffer,
      if (widget.preferredUnit != null) normalizeUnit(widget.preferredUnit),
    }.toList();

    _qtyControllers = {
      for (final unit in _availableUnits)
        unit: TextEditingController(
          text: o == null ? '' : _fmtOptional(o.quantityFor(unit)),
        ),
    };

    // Seed preferred unit empty field focus by ensuring map has it.
    final preferred = normalizeUnit(
      widget.preferredUnit ?? _availableUnits.first,
      fallback: _availableUnits.first,
    );
    _activePresetUnit = preferred;

    _brand = TextEditingController(text: o?.brand ?? '');
    _price = TextEditingController(
      text: o == null ? '' : _fmt(o.price),
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

  String _fmtOptional(double? v) {
    if (v == null) return '';
    return _fmt(v);
  }

  @override
  void dispose() {
    _brand.dispose();
    _price.dispose();
    _shop.dispose();
    _note.dispose();
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<OfferMeasure> _collectMeasures() {
    final measures = <OfferMeasure>[];
    for (final unit in _availableUnits) {
      final raw = _qtyControllers[unit]?.text.trim() ?? '';
      if (raw.isEmpty) continue;
      final n = double.tryParse(raw);
      if (n != null && n > 0) {
        measures.add(OfferMeasure(unit: unit, quantity: n));
      }
    }
    return measures;
  }

  Future<void> _submit() async {
    final s = AppStrings.of(context);
    if (!_formKey.currentState!.validate()) return;
    final measures = _collectMeasures();
    if (measures.isEmpty) {
      setState(() => _measureError = s.measureAtLeastOneRequired);
      return;
    }
    setState(() => _measureError = null);

    final price = double.parse(_price.text.trim());
    final shop = _shop.text.trim();
    if (shop.isNotEmpty) {
      await SupplierStore.instance.ensureName(shop);
    }
    final base = widget.offer;
    final result = base == null
        ? Offer(
            brand: _brand.text.trim(),
            price: price,
            measures: measures,
            shop: shop,
            note: _note.text.trim(),
          )
        : base.copyWith(
            brand: _brand.text.trim(),
            price: price,
            measures: measures,
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

  String? _optionalPositiveNumber(String? v, AppStrings s) {
    if (v == null || v.trim().isEmpty) return null;
    final n = double.tryParse(v.trim());
    if (n == null) return s.enterNumber;
    if (n <= 0) return s.mustBePositive;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final editing = widget.offer != null;
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final presetUnit = _activePresetUnit ?? _availableUnits.first;

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
              TextFormField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: s.totalPrice,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => _positiveNumber(v, s),
              ),
              const SizedBox(height: 16),
              Text(
                s.offerMeasures,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                s.offerMeasuresHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 10),
              for (final unit in _availableUnits) ...[
                TextFormField(
                  controller: _qtyControllers[unit],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: s.quantityLabel(unit),
                    hintText: s.quantityOptionalHint,
                    border: const OutlineInputBorder(),
                    suffixText: unit,
                  ),
                  onTap: () => setState(() => _activePresetUnit = unit),
                  onChanged: (_) {
                    setState(() {
                      _activePresetUnit = unit;
                      if (_measureError != null) _measureError = null;
                    });
                  },
                  validator: (v) => _optionalPositiveNumber(v, s),
                ),
                const SizedBox(height: 10),
              ],
              if (_measureError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _measureError!,
                    style: TextStyle(color: scheme.error, fontSize: 12),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${s.quantityQuickPick} · $presetUnit',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final preset in quantityPresetsFor(presetUnit))
                    ActionChip(
                      label: Text(preset.label),
                      onPressed: () {
                        final text = formatQuantityValue(preset.value);
                        final controller = _qtyControllers[presetUnit];
                        if (controller == null) return;
                        setState(() {
                          controller.text = text;
                          controller.selection = TextSelection.collapsed(
                            offset: text.length,
                          );
                          _measureError = null;
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
      ),
    );
  }
}
