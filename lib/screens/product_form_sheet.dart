import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../services/category_store.dart';
import '../services/supplier_store.dart';
import '../services/unit_store.dart';
import '../utils/ime_focus.dart';
import '../utils/quantity_presets.dart';
import '../widgets/tag_chips.dart';

class ProductFormResult {
  const ProductFormResult.saved(this.product) : deleted = false;
  const ProductFormResult.deleted()
      : product = null,
        deleted = true;

  final Product? product;
  final bool deleted;
}

Future<ProductFormResult?> showProductForm(
  BuildContext context, {
  Product? product,
}) {
  return showModalBottomSheet<ProductFormResult>(
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
  final _nameFocus = FocusNode();
  late final TextEditingController _name;
  late final TextEditingController _note;
  late Set<String> _units;
  late Set<String> _tags;
  late List<UnitRelation> _relations;
  late String _displayUnit;
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.product?.name ?? '');
    _note = TextEditingController(text: widget.product?.note ?? '');
    _units = {...(widget.product?.units ?? const ['g'])};
    _tags = {...(widget.product?.tags ?? const [])};
    _relations = [...(widget.product?.relations ?? const [])];
    _categoryId = widget.product?.categoryId;
    final current = widget.product?.displayUnit;
    _displayUnit = (current != null && _units.contains(current))
        ? current
        : (_units.isNotEmpty ? _units.first : 'g');
    _ensureCategoryUnit();
    if (widget.product == null) {
      scheduleTextFocus(_nameFocus);
    }
  }

  void _ensureCategoryUnit() {
    final cat = CategoryStore.instance.byId(_categoryId);
    if (cat == null) return;
    for (final u in cat.units) {
      _units.add(normalizeUnit(u));
    }
  }

  Set<String> get _lockedCategoryUnits {
    final cat = CategoryStore.instance.byId(_categoryId);
    if (cat == null) return const {};
    return {for (final u in cat.units) normalizeUnit(u)};
  }

  void _setDisplayUnit(String unit) {
    if (!_units.contains(unit)) return;
    setState(() => _displayUnit = unit);
  }

  void _toggleUnit(String unit, bool selected) {
    final locked = _lockedCategoryUnits.contains(normalizeUnit(unit));
    if (!selected && locked) return;
    setState(() {
      if (selected) {
        _units.add(unit);
        _displayUnit = _units.contains(_displayUnit) ? _displayUnit : unit;
      } else if (_units.length > 1) {
        _units.remove(unit);
        if (_displayUnit == unit) {
          _displayUnit = _units.first;
        }
      }
    });
  }

  void _setCategory(String? id) {
    final previousId = _categoryId;
    final nextId = (id == null || id.isEmpty) ? null : id;
    setState(() {
      if (previousId != null && previousId != nextId) {
        final prev = CategoryStore.instance.byId(previousId);
        if (prev != null) {
          for (final raw in prev.units) {
            final u = normalizeUnit(raw);
            final keep = widget.product != null &&
                CategoryUnitSync.hasUnitData(widget.product!, u);
            if (!keep && _units.length > 1) {
              _units.remove(u);
            }
          }
        }
      }
      _categoryId = nextId;
      if (nextId != null) {
        final cat = CategoryStore.instance.byId(nextId);
        if (cat != null) {
          for (final u in cat.units) {
            _units.add(normalizeUnit(u));
          }
        }
      }
      if (_units.isNotEmpty && !_units.contains(_displayUnit)) {
        _displayUnit = _units.first;
      }
    });
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_units.isEmpty) return;
    final selected = _units.toList();
    // Keep units referenced by relations.
    for (final r in _relations) {
      if (!_units.contains(r.fromUnit)) selected.add(r.fromUnit);
      if (!_units.contains(r.toUnit)) selected.add(r.toUnit);
    }
    final display =
        selected.contains(_displayUnit) ? _displayUnit : selected.first;
    final tags = _tags.toList();
    final base = widget.product;
    final draft = base == null
        ? Product(
            name: _name.text.trim(),
            units: selected,
            unit: display,
            relations: _relations,
            tags: tags,
            categoryId: _categoryId,
            note: _note.text.trim(),
          )
        : base.copyWith(
            name: _name.text.trim(),
            units: selected,
            unit: display,
            relations: _relations,
            tags: tags,
            categoryId: _categoryId,
            clearCategory: _categoryId == null || _categoryId!.isEmpty,
            note: _note.text.trim(),
          );
    final result = CategoryUnitSync.applyAssignment(
      draft,
      previousCategoryId: base?.categoryId,
      newCategoryId: _categoryId,
      resolve: CategoryStore.instance.byId,
    );
    Navigator.of(context).pop(ProductFormResult.saved(result));
  }

  Future<void> _deleteProduct() async {
    final existing = widget.product;
    if (existing == null) return;
    final s = AppStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.deleteProduct),
        content: Text(s.deleteProductConfirm(existing.name)),
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
    if (ok == true && mounted) {
      Navigator.of(context).pop(const ProductFormResult.deleted());
    }
  }

  Future<void> _addOrEditRelation([UnitRelation? existing]) async {
    final result = await showUnitRelationForm(
      context,
      units: {
        ..._units,
        if (existing != null) existing.fromUnit,
        if (existing != null) existing.toUnit,
      }.toList(),
      relation: existing,
    );
    if (result == null) return;
    setState(() {
      _units.add(result.fromUnit);
      _units.add(result.toUnit);
      if (existing == null) {
        _relations = [..._relations, result];
      } else {
        _relations = _relations
            .map((r) => r.id == existing.id ? result : r)
            .toList();
      }
    });
  }

  void _deleteRelation(UnitRelation relation) {
    setState(() {
      _relations = _relations.where((r) => r.id != relation.id).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final editing = widget.product != null;
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

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
                focusNode: _nameFocus,
                autofocus: !editing && !prefersDelayedTextFocus,
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
                s.productCategory,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                s.productCategoryHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 10),
              ListenableBuilder(
                listenable: CategoryStore.instance,
                builder: (context, _) {
                  final cats = CategoryStore.instance.categories;
                  return DropdownButtonFormField<String?>(
                    // ignore: deprecated_member_use
                    value: cats.any((c) => c.id == _categoryId)
                        ? _categoryId
                        : null,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      isDense: true,
                      hintText: s.noneOption,
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(s.noneOption),
                      ),
                      for (final c in cats)
                        DropdownMenuItem<String?>(
                          value: c.id,
                          child: Text('${c.name} · ${c.units.join(' / ')}'),
                        ),
                    ],
                    onChanged: _setCategory,
                  );
                },
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
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 10),
              ListenableBuilder(
                listenable: UnitStore.instance,
                builder: (context, _) {
                  final unitOptions = {
                    ...UnitStore.instance.names,
                    ..._units,
                    if (widget.product != null) ...widget.product!.measureUnits,
                    for (final r in _relations) ...[r.fromUnit, r.toUnit],
                  }.toList();
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final unit in unitOptions)
                        FilterChip(
                          label: Text(unit),
                          selected: _units.contains(unit),
                          onSelected: (selected) => _toggleUnit(unit, selected),
                        ),
                    ],
                  );
                },
              ),
              if (_units.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    s.measureDimensionRequired,
                    style: TextStyle(
                      color: scheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (_units.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  s.listDisplayUnit,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.listDisplayUnitHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final unit in _units)
                      ChoiceChip(
                        label: Text(unit),
                        selected: unit == _displayUnit,
                        onSelected: (_) => _setDisplayUnit(unit),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              TagPicker(
                selected: _tags,
                onChanged: (next) => setState(() => _tags = next),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                decoration: InputDecoration(
                  labelText: s.noteOptional,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: false,
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  leading: Icon(Icons.tune, color: scheme.onSurfaceVariant),
                  title: Text(
                    s.advancedOptions,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  subtitle: Text(
                    _relations.isEmpty
                        ? s.unitRelations
                        : '${s.unitRelations} · ${s.relationsConfigured(_relations.length)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        s.unitRelationsHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _units.length < 2
                            ? null
                            : () => _addOrEditRelation(),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(s.addRelation),
                      ),
                    ),
                    if (_relations.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: Text(
                          s.noRelations,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      )
                    else
                      ..._relations.map((r) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: scheme.surfaceContainerHighest.withValues(
                              alpha: 0.35,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: ListTile(
                              dense: true,
                              title: Text(
                                r.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: s.edit,
                                    onPressed: () => _addOrEditRelation(r),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: s.delete,
                                    onPressed: () => _deleteRelation(r),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _units.isEmpty ? null : _submit,
                child: Text(editing ? s.save : s.createAction),
              ),
              if (editing) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _deleteProduct,
                  icon: Icon(Icons.delete_outline, color: scheme.error),
                  label: Text(
                    s.deleteProduct,
                    style: TextStyle(color: scheme.error),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<UnitRelation?> showUnitRelationForm(
  BuildContext context, {
  required List<String> units,
  UnitRelation? relation,
}) {
  return showModalBottomSheet<UnitRelation>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _UnitRelationFormSheet(
      units: units,
      relation: relation,
    ),
  );
}

class _UnitRelationFormSheet extends StatefulWidget {
  const _UnitRelationFormSheet({
    required this.units,
    this.relation,
  });

  final List<String> units;
  final UnitRelation? relation;

  @override
  State<_UnitRelationFormSheet> createState() => _UnitRelationFormSheetState();
}

class _UnitRelationFormSheetState extends State<_UnitRelationFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _from;
  late String _to;
  late final TextEditingController _factor;

  @override
  void initState() {
    super.initState();
    final units = _allUnits;
    _from = widget.relation?.fromUnit ?? units.first;
    _to = widget.relation?.toUnit ?? _otherThan(_from, units);
    if (_from == _to && units.length > 1) {
      _to = _otherThan(_from, units);
    }
    _factor = TextEditingController(
      text: widget.relation == null
          ? ''
          : formatQuantityValue(widget.relation!.factor),
    );
  }

  List<String> get _allUnits {
    final list = widget.units.where((u) => u.trim().isNotEmpty).toList();
    return list.isNotEmpty ? list : const ['g', '个'];
  }

  String _otherThan(String exclude, List<String> units) {
    for (final u in units) {
      if (u != exclude) return u;
    }
    return exclude;
  }

  void _setFrom(String value) {
    setState(() {
      _from = value;
      // Left is free; if right collides, move right to another unit.
      if (_to == _from) {
        _to = _otherThan(_from, _allUnits);
      }
    });
  }

  void _setTo(String value) {
    if (value == _from) return;
    setState(() => _to = value);
  }

  @override
  void dispose() {
    _factor.dispose();
    super.dispose();
  }

  void _submit() {
    final s = AppStrings.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_from == _to) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.relationSameUnit)),
      );
      return;
    }
    final factor = double.parse(_factor.text.trim());
    final base = widget.relation;
    final result = base == null
        ? UnitRelation(fromUnit: _from, toUnit: _to, factor: factor)
        : base.copyWith(fromUnit: _from, toUnit: _to, factor: factor);
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final s = AppStrings.of(context);
    final editing = widget.relation != null;
    final units = _allUnits;
    final toItems = units.where((u) => u != _from).toList();
    final canPickPair = units.length >= 2;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editing ? s.editRelation : s.addRelation,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              canPickPair ? s.offerRelationsHint : s.relationNeedTwoUnits,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '1',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('from_$_from'),
                    initialValue: units.contains(_from) ? _from : null,
                    decoration: InputDecoration(
                      labelText: s.relationFrom,
                      border: const OutlineInputBorder(),
                    ),
                    items: units
                        .map(
                          (u) => DropdownMenuItem(value: u, child: Text(u)),
                        )
                        .toList(),
                    onChanged: canPickPair
                        ? (v) {
                            if (v != null) _setFrom(v);
                          }
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '=',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _factor,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: s.relationFactor,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return s.requiredField;
                      }
                      final n = double.tryParse(v.trim());
                      if (n == null) return s.enterNumber;
                      if (n <= 0) return s.mustBePositive;
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('to_$_to'),
                    initialValue: toItems.contains(_to) ? _to : null,
                    decoration: InputDecoration(
                      labelText: s.relationTo,
                      border: const OutlineInputBorder(),
                    ),
                    items: toItems
                        .map(
                          (u) => DropdownMenuItem(value: u, child: Text(u)),
                        )
                        .toList(),
                    onChanged: canPickPair
                        ? (v) {
                            if (v != null) _setTo(v);
                          }
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              s.relationEquals(
                _from,
                _factor.text.trim().isEmpty ? '?' : _factor.text.trim(),
                _to,
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: canPickPair && _from != _to ? _submit : null,
              child: Text(editing ? s.save : s.createAction),
            ),
          ],
        ),
      ),
    );
  }
}


class OfferFormResult {
  const OfferFormResult.saved(this.offer) : deleted = false;
  const OfferFormResult.deleted()
      : offer = null,
        deleted = true;

  final Offer? offer;
  final bool deleted;
}

Future<OfferFormResult?> showOfferForm(
  BuildContext context, {
  Offer? offer,
  required List<String> units,
  /// Product-level defaults used only when creating a new offer.
  List<UnitRelation> defaultRelations = const [],
  String? preferredUnit,
}) {
  return showModalBottomSheet<OfferFormResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _OfferFormSheet(
      offer: offer,
      units: units,
      defaultRelations: defaultRelations,
      preferredUnit: preferredUnit,
    ),
  );
}

class _OfferFormSheet extends StatefulWidget {
  const _OfferFormSheet({
    this.offer,
    required this.units,
    this.defaultRelations = const [],
    this.preferredUnit,
  });

  final Offer? offer;
  final List<String> units;
  final List<UnitRelation> defaultRelations;
  final String? preferredUnit;

  @override
  State<_OfferFormSheet> createState() => _OfferFormSheetState();
}

class _OfferFormSheetState extends State<_OfferFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _brandFocus = FocusNode();
  late final TextEditingController _brand;
  late final TextEditingController _price;
  late final TextEditingController _shop;
  late final TextEditingController _note;
  late final TextEditingValue _shopInitial;
  late List<String> _availableUnits;
  late Map<String, TextEditingController> _qtyControllers;
  late List<UnitRelation> _offerRelations;
  late Set<String> _tags;
  late OfferCounterMode _counterMode;
  /// Quantities the user entered (or loaded from a saved offer). Never auto-overwritten.
  final Set<String> _manualUnits = {};
  /// Quantities filled by conversion from manual seeds. Safe to update/clear.
  final Set<String> _autoFilledUnits = {};
  String? _activePresetUnit;
  String? _measureError;

  @override
  void initState() {
    super.initState();
    final o = widget.offer;
    _tags = {...(o?.tags ?? const [])};
    _counterMode = o?.counterMode ?? OfferCounterMode.none;
    _offerRelations = o == null
        ? widget.defaultRelations
            .map(
              (r) => UnitRelation(
                fromUnit: r.fromUnit,
                toUnit: r.toUnit,
                factor: r.factor,
              ),
            )
            .toList()
        : [...o.relations];

    final baseUnits = widget.units.isNotEmpty
        ? widget.units.map(normalizeUnit).toList()
        : ['g'];
    final fromOffer = o?.measureUnits ?? const <String>[];
    final fromRelations = <String>[
      for (final r in _offerRelations) ...[r.fromUnit, r.toUnit],
      for (final r in widget.defaultRelations) ...[r.fromUnit, r.toUnit],
    ];
    _availableUnits = {
      ...baseUnits,
      ...fromOffer,
      ...fromRelations,
      if (widget.preferredUnit != null) normalizeUnit(widget.preferredUnit),
    }.toList();

    _qtyControllers = {
      for (final unit in _availableUnits)
        unit: TextEditingController(
          text: o == null ? '' : _fmtOptional(o.quantityFor(unit)),
        ),
    };

    // Treat existing offer quantities as owned so editing one unit
    // cannot wipe unrelated dimensions via auto-fill.
    if (o != null) {
      for (final unit in _availableUnits) {
        final q = o.quantityFor(unit);
        if (q != null && q > 0) {
          _manualUnits.add(unit);
        }
      }
    }

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
    if (o == null) {
      scheduleTextFocus(_brandFocus);
    }
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }

  String _fmtOptional(double? v) {
    if (v == null) return '';
    return _fmt(v);
  }

  void _ensureUnitController(String unit) {
    final u = normalizeUnit(unit);
    if (_qtyControllers.containsKey(u)) return;
    _qtyControllers[u] = TextEditingController();
    if (!_availableUnits.contains(u)) {
      _availableUnits = [..._availableUnits, u];
    }
  }

  @override
  void dispose() {
    _brandFocus.dispose();
    _brand.dispose();
    _price.dispose();
    _shop.dispose();
    _note.dispose();
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _addOrEditRelation([UnitRelation? existing]) async {
    final result = await showUnitRelationForm(
      context,
      units: {
        ...widget.units.map(normalizeUnit),
        if (existing != null) existing.fromUnit,
        if (existing != null) existing.toUnit,
      }.toList(),
      relation: existing,
    );
    if (result == null) return;
    setState(() {
      _ensureUnitController(result.fromUnit);
      _ensureUnitController(result.toUnit);
      if (existing == null) {
        _offerRelations = [..._offerRelations, result];
      } else {
        _offerRelations = _offerRelations
            .map((r) => r.id == existing.id ? result : r)
            .toList();
      }
    });
    final source = _activePresetUnit ?? _availableUnits.first;
    if ((_qtyControllers[source]?.text.trim().isNotEmpty ?? false) ||
        _manualUnits.isNotEmpty) {
      _applyAutoFill(sourceUnit: source);
    }
  }

  void _deleteRelation(UnitRelation relation) {
    setState(() {
      _offerRelations =
          _offerRelations.where((r) => r.id != relation.id).toList();
    });
    final source = _activePresetUnit ?? _availableUnits.first;
    if (_manualUnits.isNotEmpty) {
      _applyAutoFill(sourceUnit: source);
    }
  }

  void _useProductDefaults() {
    setState(() {
      _offerRelations = widget.defaultRelations
          .map(
            (r) => UnitRelation(
              fromUnit: r.fromUnit,
              toUnit: r.toUnit,
              factor: r.factor,
            ),
          )
          .toList();
      for (final r in _offerRelations) {
        _ensureUnitController(r.fromUnit);
        _ensureUnitController(r.toUnit);
      }
    });
    final source = _activePresetUnit ?? _availableUnits.first;
    if (_manualUnits.isNotEmpty ||
        (_qtyControllers[source]?.text.trim().isNotEmpty ?? false)) {
      _applyAutoFill(sourceUnit: source);
    }
  }

  void _applyAutoFill({required String sourceUnit}) {
    final seeded = <String, double>{};
    for (final unit in _manualUnits) {
      final raw = _qtyControllers[unit]?.text.trim() ?? '';
      final n = double.tryParse(raw);
      if (n != null && n > 0) seeded[unit] = n;
    }

    final sourceRaw = _qtyControllers[sourceUnit]?.text.trim() ?? '';
    final sourceN = double.tryParse(sourceRaw);
    if (sourceN != null && sourceN > 0) {
      seeded[sourceUnit] = sourceN;
    } else {
      seeded.remove(sourceUnit);
    }

    if (seeded.isEmpty) {
      // Only clear previous auto-filled values; leave other fields alone.
      for (final unit in {..._autoFilledUnits}) {
        if (_manualUnits.contains(unit)) continue;
        _qtyControllers[unit]?.text = '';
      }
      _autoFilledUnits.clear();
      setState(() {});
      return;
    }

    final expanded = Product.expandQuantitiesWithRelations(
      seeded,
      relations: _offerRelations,
    );

    // Only touch units derived by conversion, never wipe unrelated manual data.
    final nextAuto = <String>{};
    for (final unit in _availableUnits) {
      if (_manualUnits.contains(unit)) continue;
      if (seeded.containsKey(unit)) continue;
      final controller = _qtyControllers[unit];
      if (controller == null) continue;
      final value = expanded[unit];
      if (value == null) {
        if (_autoFilledUnits.contains(unit)) {
          controller.text = '';
        }
        continue;
      }
      final text = formatQuantityValue(value);
      if (controller.text != text) {
        controller.text = text;
      }
      nextAuto.add(unit);
    }

    _autoFilledUnits
      ..clear()
      ..addAll(nextAuto);
    setState(() {});
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
    final tags = _tags.toList();
    final base = widget.offer;
    final result = base == null
        ? Offer(
            brand: _brand.text.trim(),
            price: price,
            measures: measures,
            relations: _offerRelations,
            tags: tags,
            counterMode: _counterMode,
            shop: shop,
            note: _note.text.trim(),
          )
        : base.copyWith(
            brand: _brand.text.trim(),
            price: price,
            measures: measures,
            relations: _offerRelations,
            tags: tags,
            counterMode: _counterMode,
            shop: shop,
            note: _note.text.trim(),
          );
    if (!mounted) return;
    Navigator.of(context).pop(OfferFormResult.saved(result));
  }

  Future<void> _deleteOffer() async {
    final existing = widget.offer;
    if (existing == null) return;
    final s = AppStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.deleteOffer),
        content: Text(s.deleteOfferConfirm(existing.brand)),
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
    if (ok == true && mounted) {
      Navigator.of(context).pop(const OfferFormResult.deleted());
    }
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
    final hasRelations = _offerRelations.isNotEmpty;

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
                focusNode: _brandFocus,
                autofocus: !editing && !prefersDelayedTextFocus,
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
                    helperText: _autoFilledUnits.contains(unit)
                        ? s.autoFilled
                        : null,
                  ),
                  onTap: () => setState(() => _activePresetUnit = unit),
                  onChanged: (value) {
                    _activePresetUnit = unit;
                    if (value.trim().isEmpty) {
                      _manualUnits.remove(unit);
                      _autoFilledUnits.remove(unit);
                    } else {
                      _manualUnits.add(unit);
                      _autoFilledUnits.remove(unit);
                    }
                    _measureError = null;
                    _applyAutoFill(sourceUnit: unit);
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
                        _manualUnits.add(presetUnit);
                        _autoFilledUnits.remove(presetUnit);
                        controller.text = text;
                        controller.selection = TextSelection.collapsed(
                          offset: text.length,
                        );
                        _measureError = null;
                        _applyAutoFill(sourceUnit: presetUnit);
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
              const SizedBox(height: 16),
              Text(
                s.counter,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                s.counterHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(s.counterModeNone),
                    selected: _counterMode == OfferCounterMode.none,
                    onSelected: (_) =>
                        setState(() => _counterMode = OfferCounterMode.none),
                  ),
                  ChoiceChip(
                    label: Text(s.counterModeCount),
                    selected: _counterMode == OfferCounterMode.countOnly,
                    onSelected: (_) => setState(
                      () => _counterMode = OfferCounterMode.countOnly,
                    ),
                  ),
                  ChoiceChip(
                    label: Text(s.counterModeLog),
                    selected: _counterMode == OfferCounterMode.withLog,
                    onSelected: (_) => setState(
                      () => _counterMode = OfferCounterMode.withLog,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TagPicker(
                selected: _tags,
                onChanged: (next) => setState(() => _tags = next),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                decoration: InputDecoration(
                  labelText: s.noteOptional,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: false,
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  leading: Icon(Icons.tune, color: scheme.onSurfaceVariant),
                  title: Text(
                    s.advancedOptions,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  subtitle: Text(
                    hasRelations
                        ? '${s.offerRelations} · ${s.relationsConfigured(_offerRelations.length)}'
                        : s.offerRelations,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        s.offerRelationsHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (widget.defaultRelations.isNotEmpty)
                          TextButton(
                            onPressed: _useProductDefaults,
                            child: Text(s.useDefaultRelations),
                          ),
                        TextButton.icon(
                          onPressed: () => _addOrEditRelation(),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(s.addRelation),
                        ),
                      ],
                    ),
                    if (!hasRelations)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: Text(
                          s.noRelations,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      )
                    else
                      ..._offerRelations.map((r) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: scheme.surfaceContainerHighest
                                .withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(12),
                            child: ListTile(
                              dense: true,
                              leading:
                                  Icon(Icons.link, color: scheme.primary),
                              title: Text(
                                r.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: s.edit,
                                    onPressed: () => _addOrEditRelation(r),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: s.delete,
                                    onPressed: () => _deleteRelation(r),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _submit,
                child: Text(editing ? s.save : s.add),
              ),
              if (editing) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _deleteOffer,
                  icon: Icon(Icons.delete_outline, color: scheme.error),
                  label: Text(
                    s.deleteOffer,
                    style: TextStyle(color: scheme.error),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
