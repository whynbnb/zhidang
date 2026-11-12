import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/custom_unit.dart';
import '../models/quantity_preset.dart';
import '../services/unit_store.dart';
import '../utils/ime_focus.dart';
import '../utils/quantity_presets.dart';
import '../utils/quick_calc.dart';
import '../settings/app_settings.dart';
import 'unit_conversions_page.dart';

class UnitsPage extends StatefulWidget {
  const UnitsPage({super.key});

  static const routeName = '/units';

  @override
  State<UnitsPage> createState() => _UnitsPageState();
}

class _UnitsPageState extends State<UnitsPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      setState(() => _query = _search.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<CustomUnit> _filtered(List<CustomUnit> all) {
    if (_query.isEmpty) return all;
    return all
        .where((u) =>
            u.name.toLowerCase().contains(_query) ||
            u.note.toLowerCase().contains(_query))
        .toList();
  }

  Future<void> _addOrEdit([CustomUnit? unit]) async {
    final result = await showUnitForm(context, unit: unit);
    if (result == null) return;
    if (unit == null) {
      await UnitStore.instance.add(
        name: result.name,
        note: result.note,
        presets: result.presets,
      );
    } else {
      await UnitStore.instance.update(
        unit.copyWith(
          name: result.name,
          note: result.note,
          presets: result.presets,
          resetPresets: result.presets == null,
        ),
      );
    }
  }

  Future<void> _delete(CustomUnit unit) async {
    final s = AppStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.deleteUnit),
        content: Text(s.deleteUnitConfirm(unit.name)),
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
      await UnitStore.instance.remove(unit.id);
    }
  }

  Future<void> _resetDefaults() async {
    final s = AppStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.resetUnits),
        content: Text(s.resetUnitsConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.resetUnits),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await UnitStore.instance.resetToDefaults(AppSettings.instance.locale);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.unitsResetDone)),
    );
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    if (_query.isNotEmpty) return;
    await UnitStore.instance.reorder(oldIndex, newIndex);
  }

  Widget _unitTile(
    BuildContext context,
    AppStrings s,
    ColorScheme scheme,
    CustomUnit unit,
    int index, {
    required bool showHandle,
  }) {
    return Padding(
      key: ValueKey(unit.id),
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            child: const Icon(Icons.straighten_outlined),
          ),
          title: Text(
            unit.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: unit.note.isEmpty ? null : Text(unit.note),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showHandle)
                ReorderableDragStartListener(
                  index: index,
                  child: Tooltip(
                    message: s.unitReorderHint,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      child: Icon(
                        Icons.drag_handle,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') _addOrEdit(unit);
                  if (v == 'delete') _delete(unit);
                },
                itemBuilder: (_) => [
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
            ],
          ),
          onTap: () => _addOrEdit(unit),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.units),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'reset') _resetDefaults();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'reset',
                child: Text(s.resetUnits),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-units-add',
        onPressed: () => _addOrEdit(),
        icon: const Icon(Icons.add),
        label: Text(s.addUnit),
      ),
      body: ListenableBuilder(
        listenable: UnitStore.instance,
        builder: (context, _) {
          final all = UnitStore.instance.units;
          final items = _filtered(all);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: s.searchUnits,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    isDense: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    all.isEmpty ? s.noUnits : s.unitCount(all.length),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: scheme.outlineVariant),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: scheme.secondaryContainer,
                      foregroundColor: scheme.onSecondaryContainer,
                      child: const Icon(Icons.swap_horiz),
                    ),
                    title: Text(
                      s.unitConversions,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      UnitStore.instance.relations.isEmpty
                          ? s.noUnitConversions
                          : s.unitConversionsCount(
                              UnitStore.instance.relations.length,
                            ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        settings: const RouteSettings(
                          name: UnitConversionsPage.routeName,
                        ),
                        builder: (_) => const UnitConversionsPage(),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.straighten_outlined,
                                size: 56,
                                color: scheme.primary.withValues(alpha: 0.7),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                all.isEmpty ? s.noUnits : s.noUnitResults,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                s.unitsHint,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                              if (all.isEmpty) ...[
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: () => _addOrEdit(),
                                  icon: const Icon(Icons.add),
                                  label: Text(s.addUnit),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : _query.isEmpty
                        ? ReorderableListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                            buildDefaultDragHandles: false,
                            itemCount: items.length,
                            onReorderItem: _reorder,
                            itemBuilder: (context, index) => _unitTile(
                              context,
                              s,
                              scheme,
                              items[index],
                              index,
                              showHandle: true,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                            itemCount: items.length,
                            itemBuilder: (context, index) => _unitTile(
                              context,
                              s,
                              scheme,
                              items[index],
                              index,
                              showHandle: false,
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class UnitDraft {
  const UnitDraft({
    required this.name,
    this.note = '',
    this.presets,
  });

  final String name;
  final String note;

  /// `null` means keep using the built-in defaults for this unit name.
  final List<QuantityPreset>? presets;
}

Future<UnitDraft?> showUnitForm(
  BuildContext context, {
  CustomUnit? unit,
}) {
  return showModalBottomSheet<UnitDraft>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _UnitFormSheet(unit: unit),
  );
}

class _UnitFormSheet extends StatefulWidget {
  const _UnitFormSheet({this.unit});

  final CustomUnit? unit;

  @override
  State<_UnitFormSheet> createState() => _UnitFormSheetState();
}

class _UnitFormSheetState extends State<_UnitFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameFocus = FocusNode();
  late final TextEditingController _name;
  late final TextEditingController _note;
  final _presetValue = TextEditingController();
  List<QuantityPreset>? _presets;
  String? _presetError;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.unit?.name ?? '');
    _note = TextEditingController(text: widget.unit?.note ?? '');
    _presets = widget.unit?.presets == null
        ? null
        : List<QuantityPreset>.from(widget.unit!.presets!);
    _name.addListener(_onNameChanged);
    if (widget.unit == null) {
      scheduleTextFocus(_nameFocus);
    }
  }

  void _onNameChanged() {
    // Keep the preset preview and the add field's suffix in sync with the name.
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _name.removeListener(_onNameChanged);
    _nameFocus.dispose();
    _name.dispose();
    _note.dispose();
    _presetValue.dispose();
    super.dispose();
  }

  List<QuantityPreset> get _effectivePresets =>
      _presets ?? defaultQuantityPresetsFor(_name.text.trim());

  void _updatePresets(List<QuantityPreset> presets) {
    setState(() {
      _presets = presets;
      _presetError = null;
    });
  }

  void _togglePreset(int index, bool enabled) {
    final presets = [..._effectivePresets];
    presets[index] = presets[index].copyWith(enabled: enabled);
    _updatePresets(presets);
  }

  void _removePreset(int index) {
    final presets = [..._effectivePresets]..removeAt(index);
    _updatePresets(presets);
  }

  void _addPreset() {
    final s = AppStrings.of(context);
    final value = parseCalcNumber(_presetValue.text);
    if (value == null || value <= 0) {
      setState(() => _presetError = s.presetValueInvalid);
      return;
    }
    final presets = _effectivePresets;
    if (presets.any((preset) => (preset.value - value).abs() < 1e-9)) {
      setState(() => _presetError = s.presetDuplicate);
      return;
    }
    final label = '${formatQuantityValue(value)}${_name.text.trim()}';
    _presetValue.clear();
    _updatePresets([
      ...presets,
      QuantityPreset(value: value, label: label),
    ]);
  }

  void _restoreDefaults() {
    setState(() {
      _presets = null;
      _presetError = null;
    });
  }

  void _clearPresets() {
    setState(() {
      _presets = const [];
      _presetError = null;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      UnitDraft(
        name: _name.text.trim(),
        note: _note.text.trim(),
        presets: _presets,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final editing = widget.unit != null;
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final presets = _effectivePresets;

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
                editing ? s.editUnit : s.addUnit,
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
                  labelText: s.unitName,
                  hintText: s.unitNameHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return s.unitNameRequired;
                  }
                  final existing = UnitStore.instance.findByName(v);
                  if (existing != null && existing.id != widget.unit?.id) {
                    return s.unitNameExists;
                  }
                  return null;
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.quickQuantityPresets,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: _restoreDefaults,
                    child: Text(s.restoreDefaultPresets),
                  ),
                  TextButton(
                    onPressed: _clearPresets,
                    child: Text(s.clearAction),
                  ),
                ],
              ),
              Text(
                s.quickQuantityPresetsHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 10),
              if (presets.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Text(
                    s.noQuickPresets,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                )
              else
                for (var i = 0; i < presets.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              presets[i].label.trim().isEmpty
                                  ? formatQuantityValue(presets[i].value)
                                  : presets[i].label,
                              style: TextStyle(
                                color: presets[i].enabled
                                    ? null
                                    : scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Checkbox(
                            key: ValueKey('unit-preset-toggle-$i'),
                            value: presets[i].enabled,
                            onChanged: (value) =>
                                _togglePreset(i, value ?? false),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          IconButton(
                            tooltip: s.delete,
                            onPressed: () => _removePreset(i),
                            icon: const Icon(Icons.delete_outline, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('unit-preset-input'),
                      controller: _presetValue,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: s.addQuickPreset,
                        hintText: s.addQuickPresetHint,
                        errorText: _presetError,
                        border: const OutlineInputBorder(),
                        isDense: true,
                        suffixText: _name.text.trim(),
                      ),
                      onChanged: (_) {
                        if (_presetError != null) {
                          setState(() => _presetError = null);
                        }
                      },
                      onSubmitted: (_) => _addPreset(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    key: const ValueKey('unit-preset-add'),
                    onPressed: _addPreset,
                    tooltip: s.add,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submit,
                child: Text(editing ? s.save : s.createAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
