import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../services/unit_store.dart';
import '../utils/discard_changes.dart';
import '../utils/quantity_presets.dart';

Future<UnitRelation?> showUnitRelationForm(
  BuildContext context, {
  required List<String> units,
  UnitRelation? relation,
}) {
  return Navigator.of(context).push<UnitRelation>(
    MaterialPageRoute(
      builder: (context) => _UnitRelationFormSheet(
        units: units,
        relation: relation,
      ),
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
  late final String _initialSignature;

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
    _factor.addListener(_onFieldChanged);
    _initialSignature = _signature();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  String _signature() => '$_from|$_to|${_factor.text.trim()}';

  bool get _hasUnsavedChanges => _signature() != _initialSignature;

  Future<void> _onPopInvoked(bool didPop, Object? result) async {
    if (didPop) return;
    final discard = await confirmDiscardChanges(context);
    if (discard && mounted) {
      Navigator.of(context).pop();
    }
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
    _factor.removeListener(_onFieldChanged);
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
    final s = AppStrings.of(context);
    final editing = widget.relation != null;
    final units = _allUnits;
    final toItems = units.where((u) => u != _from).toList();
    final canPickPair = units.length >= 2;
    final title = editing ? s.editRelation : s.addRelation;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            TextButton(
              onPressed: canPickPair && _from != _to ? _submit : null,
              child: Text(editing ? s.save : s.createAction),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
          ],
        ),
      ),
    ),
  ),
),
);
  }
}

String relationPairKey(UnitRelation relation) {
  final a = relation.fromUnit.trim().toLowerCase();
  final b = relation.toUnit.trim().toLowerCase();
  return a.compareTo(b) <= 0 ? '$a|$b' : '$b|$a';
}

/// Pick one or more global conversions to add to a product / offer editor.
/// Already-present pairs are hidden. Returned relations get fresh ids so they
/// belong to the local editor rather than the shared library.
Future<List<UnitRelation>?> showGlobalRelationsPicker(
  BuildContext context, {
  required List<UnitRelation> existing,
}) {
  final existingKeys = existing.map(relationPairKey).toSet();
  final options = UnitStore.instance.relations
      .where((relation) => !existingKeys.contains(relationPairKey(relation)))
      .toList();
  final selected = <String>{};

  return showDialog<List<UnitRelation>>(
    context: context,
    builder: (context) {
      final s = AppStrings.of(context);
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(s.chooseGlobalRelations),
            content: SizedBox(
              width: 380,
              child: options.isEmpty
                  ? Text(s.noSelectableGlobalRelations)
                  : ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final relation in options)
                            CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              value: selected.contains(relation.id),
                              title: Text(relation.label),
                              onChanged: (value) {
                                setDialogState(() {
                                  if (value == true) {
                                    selected.add(relation.id);
                                  } else {
                                    selected.remove(relation.id);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(s.cancel),
              ),
              FilledButton(
                onPressed: selected.isEmpty
                    ? null
                    : () {
                        final picked = options
                            .where(
                              (relation) => selected.contains(relation.id),
                            )
                            .map(
                              (relation) => UnitRelation(
                                fromUnit: relation.fromUnit,
                                toUnit: relation.toUnit,
                                factor: relation.factor,
                              ),
                            )
                            .toList();
                        Navigator.pop(context, picked);
                      },
                child: Text(s.add),
              ),
            ],
          );
        },
      );
    },
  );
}
