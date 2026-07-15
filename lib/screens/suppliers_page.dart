import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/supplier.dart';
import '../services/supplier_store.dart';

class SuppliersPage extends StatefulWidget {
  const SuppliersPage({super.key});

  static const routeName = '/suppliers';

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
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

  List<Supplier> _filtered(List<Supplier> all) {
    if (_query.isEmpty) return all;
    return all
        .where((s) =>
            s.name.toLowerCase().contains(_query) ||
            s.note.toLowerCase().contains(_query))
        .toList();
  }

  Future<void> _addOrEdit([Supplier? supplier]) async {
    final result = await showSupplierForm(context, supplier: supplier);
    if (result == null) return;
    if (supplier == null) {
      await SupplierStore.instance.add(name: result.name, note: result.note);
    } else {
      await SupplierStore.instance.update(
        supplier.copyWith(name: result.name, note: result.note),
      );
    }
  }

  Future<void> _delete(Supplier supplier) async {
    final s = AppStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.deleteSupplier),
        content: Text(s.deleteSupplierConfirm(supplier.name)),
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
      await SupplierStore.instance.remove(supplier.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.suppliers),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(),
        icon: const Icon(Icons.add),
        label: Text(s.addSupplier),
      ),
      body: ListenableBuilder(
        listenable: SupplierStore.instance,
        builder: (context, _) {
          final all = SupplierStore.instance.suppliers;
          final items = _filtered(all);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: s.searchSuppliers,
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
                    all.isEmpty
                        ? s.noSuppliers
                        : s.supplierCount(all.length),
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
                                Icons.storefront_outlined,
                                size: 56,
                                color: scheme.primary.withValues(alpha: 0.7),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                all.isEmpty
                                    ? s.noSuppliers
                                    : s.noSupplierResults,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                s.suppliersHint,
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
                                  label: Text(s.addSupplier),
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
                          final supplier = items[index];
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
                                child: const Icon(Icons.storefront_outlined),
                              ),
                              title: Text(
                                supplier.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: supplier.note.isEmpty
                                  ? null
                                  : Text(supplier.note),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit') _addOrEdit(supplier);
                                  if (v == 'delete') _delete(supplier);
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
                              onTap: () => _addOrEdit(supplier),
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

class SupplierDraft {
  const SupplierDraft({required this.name, this.note = ''});

  final String name;
  final String note;
}

Future<SupplierDraft?> showSupplierForm(
  BuildContext context, {
  Supplier? supplier,
}) {
  return showModalBottomSheet<SupplierDraft>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _SupplierFormSheet(supplier: supplier),
  );
}

class _SupplierFormSheet extends StatefulWidget {
  const _SupplierFormSheet({this.supplier});

  final Supplier? supplier;

  @override
  State<_SupplierFormSheet> createState() => _SupplierFormSheetState();
}

class _SupplierFormSheetState extends State<_SupplierFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.supplier?.name ?? '');
    _note = TextEditingController(text: widget.supplier?.note ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      SupplierDraft(
        name: _name.text.trim(),
        note: _note.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final editing = widget.supplier != null;
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
              editing ? s.editSupplier : s.addSupplier,
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
                labelText: s.supplierName,
                hintText: s.supplierNameHint,
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return s.supplierNameRequired;
                }
                final existing = SupplierStore.instance.findByName(v);
                if (existing != null && existing.id != widget.supplier?.id) {
                  return s.supplierNameExists;
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
