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

  String _typeLabel(AppStrings s, SupplierType type) {
    switch (type) {
      case SupplierType.ecommerce:
        return s.supplierTypeEcommerce;
      case SupplierType.delivery:
        return s.supplierTypeDelivery;
      case SupplierType.store:
        return s.supplierTypeStore;
    }
  }

  List<Supplier> _filtered(List<Supplier> all, AppStrings strings) {
    if (_query.isEmpty) return all;
    return all.where((supplier) {
      if (supplier.name.toLowerCase().contains(_query)) return true;
      if (supplier.note.toLowerCase().contains(_query)) return true;
      if (supplier.address.toLowerCase().contains(_query)) return true;
      for (final type in supplier.types) {
        if (_typeLabel(strings, type).toLowerCase().contains(_query)) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  Future<void> _addOrEdit([Supplier? supplier]) async {
    final result = await showSupplierForm(context, supplier: supplier);
    if (result == null) return;
    if (supplier == null) {
      await SupplierStore.instance.add(
        name: result.name,
        types: result.types,
        address: result.address,
        note: result.note,
      );
    } else {
      await SupplierStore.instance.update(
        supplier.copyWith(
          name: result.name,
          types: result.types,
          address: result.address,
          note: result.note,
        ),
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

  String? _subtitle(Supplier supplier, AppStrings s) {
    final parts = <String>[];
    if (supplier.types.isNotEmpty) {
      parts.add(supplier.types.map((t) => _typeLabel(s, t)).join(' · '));
    }
    if (supplier.hasStore && supplier.address.isNotEmpty) {
      parts.add(supplier.address);
    }
    if (supplier.note.isNotEmpty) {
      parts.add(supplier.note);
    }
    if (parts.isEmpty) return null;
    return parts.join('\n');
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
          final items = _filtered(all, s);

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
                          final subtitle = _subtitle(supplier, s);
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
                                child: Icon(
                                  supplier.hasStore
                                      ? Icons.store_outlined
                                      : Icons.storefront_outlined,
                                ),
                              ),
                              title: Text(
                                supplier.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: subtitle == null
                                  ? null
                                  : Text(subtitle),
                              isThreeLine:
                                  subtitle != null && subtitle.contains('\n'),
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
  const SupplierDraft({
    required this.name,
    this.types = const [],
    this.address = '',
    this.note = '',
  });

  final String name;
  final List<SupplierType> types;
  final String address;
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
  late final TextEditingController _address;
  late Set<SupplierType> _types;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.supplier?.name ?? '');
    _note = TextEditingController(text: widget.supplier?.note ?? '');
    _address = TextEditingController(text: widget.supplier?.address ?? '');
    _types = {...(widget.supplier?.types ?? const [])};
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    _address.dispose();
    super.dispose();
  }

  bool get _hasStore => _types.contains(SupplierType.store);

  void _toggleType(SupplierType type, bool selected) {
    setState(() {
      if (selected) {
        _types.add(type);
      } else {
        _types.remove(type);
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final hasStore = _types.contains(SupplierType.store);
    Navigator.of(context).pop(
      SupplierDraft(
        name: _name.text.trim(),
        types: SupplierType.valuesInOrder
            .where((t) => _types.contains(t))
            .toList(),
        address: hasStore ? _address.text.trim() : '',
        note: _note.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final editing = widget.supplier != null;
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
              const SizedBox(height: 16),
              Text(
                s.supplierTypes,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                s.supplierTypesHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: Text(s.supplierTypeEcommerce),
                    selected: _types.contains(SupplierType.ecommerce),
                    onSelected: (v) => _toggleType(SupplierType.ecommerce, v),
                  ),
                  FilterChip(
                    label: Text(s.supplierTypeDelivery),
                    selected: _types.contains(SupplierType.delivery),
                    onSelected: (v) => _toggleType(SupplierType.delivery, v),
                  ),
                  FilterChip(
                    label: Text(s.supplierTypeStore),
                    selected: _types.contains(SupplierType.store),
                    onSelected: (v) => _toggleType(SupplierType.store, v),
                  ),
                ],
              ),
              if (_hasStore) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _address,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: s.supplierAddressOptional,
                    hintText: s.supplierAddressHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
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
      ),
    );
  }
}
