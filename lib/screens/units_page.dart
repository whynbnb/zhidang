import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/custom_unit.dart';
import '../services/unit_store.dart';
import '../utils/ime_focus.dart';
import '../settings/app_settings.dart';

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
      await UnitStore.instance.add(name: result.name, note: result.note);
    } else {
      await UnitStore.instance.update(
        unit.copyWith(name: result.name, note: result.note),
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
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final unit = items[index];
                          return Card(
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle:
                                  unit.note.isEmpty ? null : Text(unit.note),
                              trailing: PopupMenuButton<String>(
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
                              onTap: () => _addOrEdit(unit),
                            ),
                          );
                        },
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
  const UnitDraft({required this.name, this.note = ''});

  final String name;
  final String note;
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

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.unit?.name ?? '');
    _note = TextEditingController(text: widget.unit?.note ?? '');
    if (widget.unit == null) {
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      UnitDraft(
        name: _name.text.trim(),
        note: _note.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final editing = widget.unit != null;
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
