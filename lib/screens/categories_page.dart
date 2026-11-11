import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../services/category_store.dart';
import '../services/unit_store.dart';
import '../utils/ime_focus.dart';
import '../widgets/hint_title.dart';
import 'unit_relation_form.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  static const routeName = '/categories';

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
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

  List<ProductCategory> _filtered(List<ProductCategory> all) {
    if (_query.isEmpty) return all;
    return all.where((c) {
      if (c.name.toLowerCase().contains(_query)) return true;
      if (c.units.any((u) => u.toLowerCase().contains(_query))) return true;
      if (c.note.toLowerCase().contains(_query)) return true;
      return false;
    }).toList();
  }

  Future<void> _addOrEdit([ProductCategory? category]) async {
    final result = await showCategoryForm(context, category: category);
    if (result == null) return;
    if (category == null) {
      await CategoryStore.instance.add(
        name: result.name,
        units: result.units,
        relations: result.relations,
        note: result.note,
      );
    } else {
      await CategoryStore.instance.update(
        category.copyWith(
          name: result.name,
          units: result.units,
          relations: result.relations,
          note: result.note,
        ),
      );
    }
  }

  Future<void> _delete(ProductCategory category) async {
    final s = AppStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.deleteCategory),
        content: Text(s.deleteCategoryConfirm(category.name)),
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
      await CategoryStore.instance.remove(category.id);
    }
  }

  String? _subtitle(ProductCategory category, AppStrings s) {
    final parts = <String>[
      s.measureUnitsLabel(
        UnitStore.instance.sortUnits(category.units).join(' / '),
      ),
    ];
    if (category.relations.isNotEmpty) {
      parts.add(s.unitConversionsCount(category.relations.length));
    }
    if (category.note.isNotEmpty) parts.add(category.note);
    return parts.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(s.categories)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-categories-add',
        onPressed: () => _addOrEdit(),
        icon: const Icon(Icons.add),
        label: Text(s.addCategory),
      ),
      body: ListenableBuilder(
        listenable: CategoryStore.instance,
        builder: (context, _) {
          final all = CategoryStore.instance.categories;
          final items = _filtered(all);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: s.searchCategories,
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
                    all.isEmpty ? s.noCategories : s.categoryCount(all.length),
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
                                Icons.category_outlined,
                                size: 56,
                                color: scheme.primary.withValues(alpha: 0.7),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                all.isEmpty
                                    ? s.noCategories
                                    : s.noCategoryResults,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                s.categoriesHint,
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
                                  label: Text(s.addCategory),
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
                          final category = items[index];
                          final subtitle = _subtitle(category, s);
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: scheme.outlineVariant),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: scheme.secondaryContainer,
                                foregroundColor: scheme.onSecondaryContainer,
                                child: const Icon(Icons.category_outlined),
                              ),
                              title: Text(
                                category.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle:
                                  subtitle == null ? null : Text(subtitle),
                              isThreeLine:
                                  subtitle != null && subtitle.contains('\n'),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit') _addOrEdit(category);
                                  if (v == 'delete') _delete(category);
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
                              onTap: () => _addOrEdit(category),
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

class CategoryDraft {
  const CategoryDraft({
    required this.name,
    required this.units,
    this.relations = const [],
    this.note = '',
  });

  final String name;
  final List<String> units;
  final List<UnitRelation> relations;
  final String note;
}

Future<CategoryDraft?> showCategoryForm(
  BuildContext context, {
  ProductCategory? category,
}) {
  return showModalBottomSheet<CategoryDraft>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _CategoryFormSheet(category: category),
  );
}

class _CategoryFormSheet extends StatefulWidget {
  const _CategoryFormSheet({this.category});

  final ProductCategory? category;

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameFocus = FocusNode();
  late final TextEditingController _name;
  late final TextEditingController _note;
  late Set<String> _units;
  late List<UnitRelation> _relations;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.category?.name ?? '');
    _note = TextEditingController(text: widget.category?.note ?? '');
    _units = {...(widget.category?.units ?? const ['g'])};
    _relations = [...(widget.category?.relations ?? const [])];
    for (final relation in _relations) {
      _units.add(relation.fromUnit);
      _units.add(relation.toUnit);
    }
    if (widget.category == null) {
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

  void _toggleUnit(String unit, bool selected) {
    setState(() {
      if (selected) {
        _units.add(unit);
      } else if (_units.length > 1) {
        _units.remove(unit);
      }
    });
  }

  Future<void> _addOrEditRelation([UnitRelation? existing]) async {
    final units = UnitStore.instance.sortUnits({
      ...UnitStore.instance.names,
      ..._units,
      for (final relation in _relations) ...[
        relation.fromUnit,
        relation.toUnit,
      ],
      if (existing != null) ...[existing.fromUnit, existing.toUnit],
    });
    final result = await showUnitRelationForm(
      context,
      units: units,
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
            .map((relation) => relation.id == existing.id ? result : relation)
            .toList();
      }
    });
  }

  Future<void> _addGlobalRelations() async {
    final picked = await showGlobalRelationsPicker(
      context,
      existing: _relations,
    );
    if (picked == null || picked.isEmpty) return;
    setState(() {
      for (final relation in picked) {
        _relations = [..._relations, relation];
        _units.add(relation.fromUnit);
        _units.add(relation.toUnit);
      }
    });
  }

  void _deleteRelation(UnitRelation relation) {
    setState(() {
      _relations = _relations
          .where((existing) => existing.id != relation.id)
          .toList();
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_units.isEmpty) return;
    Navigator.of(context).pop(
      CategoryDraft(
        name: _name.text.trim(),
        units: _units.toList(),
        relations: _relations,
        note: _note.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final editing = widget.category != null;
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final unitOptions = UnitStore.instance.sortUnits({
      ...UnitStore.instance.names,
      ..._units,
    });

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
                editing ? s.editCategory : s.addCategory,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                s.categoryUnitHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                focusNode: _nameFocus,
                autofocus: !editing && !prefersDelayedTextFocus,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: s.categoryName,
                  hintText: s.categoryNameHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return s.categoryNameRequired;
                  }
                  final existing = CategoryStore.instance.findByName(v);
                  if (existing != null &&
                      existing.id != widget.category?.id) {
                    return s.categoryNameExists;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                s.categoryUnit,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final unit in unitOptions)
                    FilterChip(
                      label: Text(unit),
                      selected: _units.contains(unit),
                      onSelected: (v) => _toggleUnit(unit, v),
                    ),
                ],
              ),
              if (_units.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    s.measureDimensionRequired,
                    style: TextStyle(color: scheme.error, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),
              HintTitle(
                title: s.unitRelations,
                hint: s.categoryRelationsHint,
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 4,
                  children: [
                    if (UnitStore.instance.relations.isNotEmpty)
                      TextButton.icon(
                        onPressed: _addGlobalRelations,
                        icon: const Icon(
                          Icons.library_add_outlined,
                          size: 18,
                        ),
                        label: Text(s.chooseGlobalRelations),
                      ),
                    TextButton.icon(
                      onPressed: _units.length < 2
                          ? null
                          : () => _addOrEditRelation(),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(s.addRelation),
                    ),
                  ],
                ),
              ),
              if (_relations.isEmpty)
                Text(
                  s.noRelations,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                )
              else
                ..._relations.map(
                  (relation) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.35,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        dense: true,
                        title: Text(
                          relation.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: s.edit,
                              onPressed: () => _addOrEditRelation(relation),
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 20,
                              ),
                            ),
                            IconButton(
                              tooltip: s.delete,
                              onPressed: () => _deleteRelation(relation),
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
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
