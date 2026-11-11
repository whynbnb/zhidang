import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../services/unit_store.dart';
import '../utils/quick_calc.dart';
import 'unit_relation_form.dart';

/// Global conversion library. It powers quick convert and can be picked by
/// product / offer editors, but is never applied automatically.
class UnitConversionsPage extends StatefulWidget {
  const UnitConversionsPage({super.key});

  static const routeName = '/unit-conversions';

  @override
  State<UnitConversionsPage> createState() => _UnitConversionsPageState();
}

class _UnitConversionsPageState extends State<UnitConversionsPage> {
  Future<void> _addOrEdit([UnitRelation? relation]) async {
    final store = UnitStore.instance;
    final s = AppStrings.of(context);
    final units = <String>{
      ...store.names,
      ...quickCalcUnitOptions(isZh: s.isZh),
      for (final existing in store.relations) ...[
        existing.fromUnit,
        existing.toUnit,
      ],
      if (relation != null) ...[relation.fromUnit, relation.toUnit],
    }.toList();
    final result = await showUnitRelationForm(
      context,
      units: units,
      relation: relation,
    );
    if (result == null) return;
    await store.ensureName(result.fromUnit);
    await store.ensureName(result.toUnit);
    if (relation == null) {
      await store.addRelation(
        fromUnit: result.fromUnit,
        toUnit: result.toUnit,
        factor: result.factor,
      );
    } else {
      await store.updateRelation(result);
    }
  }

  Future<void> _delete(UnitRelation relation) async {
    final s = AppStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.deleteRelation),
        content: Text(relation.label),
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
      await UnitStore.instance.removeRelation(relation.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(s.unitConversions)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-unit-conversion-add',
        onPressed: () => _addOrEdit(),
        icon: const Icon(Icons.add),
        label: Text(s.addRelation),
      ),
      body: ListenableBuilder(
        listenable: UnitStore.instance,
        builder: (context, _) {
          final relations = UnitStore.instance.relations;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Text(
                  s.unitConversionsHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  relations.isEmpty
                      ? s.noUnitConversions
                      : s.unitConversionsCount(relations.length),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
              Expanded(
                child: relations.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.swap_horiz,
                                size: 56,
                                color: scheme.primary.withValues(alpha: 0.7),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                s.noUnitConversions,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () => _addOrEdit(),
                                icon: const Icon(Icons.add),
                                label: Text(s.addRelation),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                        itemCount: relations.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final relation = relations[index];
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
                                child: const Icon(Icons.swap_horiz),
                              ),
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
                                    tooltip: s.editRelation,
                                    onPressed: () => _addOrEdit(relation),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: s.delete,
                                    onPressed: () => _delete(relation),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _addOrEdit(relation),
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
