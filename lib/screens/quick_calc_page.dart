import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/quick_calc_store.dart';
import '../services/unit_store.dart';
import '../settings/app_settings.dart';
import '../utils/quick_calc.dart';

class QuickCalcPage extends StatefulWidget {
  const QuickCalcPage({super.key});

  static const routeName = '/quick-calc';

  @override
  State<QuickCalcPage> createState() => _QuickCalcPageState();
}

class _QuickCalcPageState extends State<QuickCalcPage> {
  final _store = QuickCalcStore.instance;

  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _quantity;

  bool get _isZh => AppSettings.instance.locale.languageCode != 'en';

  String get _defaultUnit => _isZh ? '个' : 'pc';

  QuickCalcDraft get _draft => _store.draft;

  @override
  void initState() {
    super.initState();
    if (_draft.unit.isEmpty) {
      _draft.unit = _defaultUnit;
    }
    _name = TextEditingController(text: _draft.name);
    _price = TextEditingController(text: _draft.price);
    _quantity = TextEditingController(text: _draft.quantity);
    _name.addListener(_syncDraft);
    _price.addListener(_syncDraft);
    _quantity.addListener(_syncDraft);
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _quantity.dispose();
    super.dispose();
  }

  void _syncDraft() {
    _draft.name = _name.text;
    _draft.price = _price.text;
    _draft.quantity = _quantity.text;
    if (mounted) setState(() {});
  }

  void _commitDraft() {
    final s = AppStrings.of(context);
    final price = parseCalcNumber(_price.text);
    final quantity = parseCalcNumber(_quantity.text);
    if (price == null || quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(s.quickCalcIncomplete)));
      return;
    }
    _store.commit(
      name: _name.text.trim(),
      price: price,
      quantity: quantity,
      unit: _draft.unit,
    );
    _name.clear();
    _price.clear();
    _quantity.clear();
    setState(() {});
  }

  Future<void> _clearAll() async {
    final s = AppStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.quickCalcClear),
        content: Text(s.quickCalcClearConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.quickCalcClear),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    _store.clear();
    _name.clear();
    _price.clear();
    _quantity.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final wide = MediaQuery.sizeOf(context).width >= 720;

    final results = <String, QuickCalcResult?>{};
    final groupCounts = <String, int>{};
    final groupBest = <String, double>{};
    final groups = <String, List<QuickCalcEntry>>{};
    for (final entry in _store.entries) {
      final result = computeQuickCalcValues(
        price: entry.price,
        quantity: entry.quantity,
        unit: entry.unit,
        isZh: s.isZh,
      );
      results[entry.id] = result;
      final key = result?.groupKey ?? 'unknown:${entry.id}';
      groups.putIfAbsent(key, () => []).add(entry);
      if (result == null) continue;
      groupCounts[result.groupKey] = (groupCounts[result.groupKey] ?? 0) + 1;
      final best = groupBest[result.groupKey];
      if (best == null || result.canonical < best) {
        groupBest[result.groupKey] = result.canonical;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Tooltip(
          message: s.quickCalcHint,
          triggerMode: TooltipTriggerMode.longPress,
          showDuration: const Duration(seconds: 6),
          constraints: const BoxConstraints(maxWidth: 320),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(s.quickCalcTitle, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 5),
              Icon(
                Icons.info_outline,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _store.hasData ? _clearAll : null,
            child: Text(s.quickCalcClear),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            for (final group in groups.entries) ...[
              _buildGroupHeader(context, s, group.key, group.value),
              for (final entry in group.value) ...[
                _buildCommittedRow(
                  context,
                  s,
                  entry,
                  result: results[entry.id],
                  groupCount: results[entry.id] == null
                      ? 0
                      : groupCounts[results[entry.id]!.groupKey] ?? 0,
                  groupBest: results[entry.id] == null
                      ? null
                      : groupBest[results[entry.id]!.groupKey],
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 6),
            ],
            _buildDraftCard(context, s, wide: wide),
            const SizedBox(height: 8),
            Text(
              s.quickCalcAddHint,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupHeader(
    BuildContext context,
    AppStrings s,
    String groupKey,
    List<QuickCalcEntry> entries,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final IconData icon;
    final String label;
    if (groupKey == 'weight') {
      icon = Icons.scale_outlined;
      label = s.quickCalcGroupWeight;
    } else if (groupKey == 'volume') {
      icon = Icons.water_drop_outlined;
      label = s.quickCalcGroupVolume;
    } else if (groupKey.startsWith('count:')) {
      icon = Icons.tag;
      label = s.quickCalcGroupUnit(entries.first.unit);
    } else {
      icon = Icons.tag;
      label = entries.first.unit;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(height: 1, color: scheme.outlineVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildCommittedRow(
    BuildContext context,
    AppStrings s,
    QuickCalcEntry entry, {
    required QuickCalcResult? result,
    required int groupCount,
    required double? groupBest,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    if (result == null) return const SizedBox.shrink();

    final best = groupBest;
    final comparable = groupCount > 1 && best != null;
    final isBest = comparable && (result.canonical - best).abs() < 1e-9;
    final percent = comparable && best > 0 && !isBest
        ? ((result.canonical / best - 1) * 100).round()
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 2, 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (entry.name.isNotEmpty)
                  Text(
                    entry.name,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                Text(
                  '¥${formatCalcNumber(entry.price)} / '
                  '${formatCalcNumber(entry.quantity)} ${entry.unit}',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  result.primary,
                  style: textTheme.titleSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (result.secondary != null)
                  Text(
                    result.secondary!,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                if (isBest)
                  _chip(scheme, textTheme, s.quickCalcBest)
                else if (percent != null && percent > 0)
                  Text(
                    '+$percent%',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _store.remove(entry.id),
            tooltip: s.quickCalcDeleteRow,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftCard(
    BuildContext context,
    AppStrings s, {
    required bool wide,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final units = quickCalcUnitOptions(
      isZh: s.isZh,
      extra: UnitStore.instance.names,
    );
    if (!units.contains(_draft.unit)) {
      units.insert(0, _draft.unit);
    }

    final nameField = TextField(
      controller: _name,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: s.quickCalcName,
        hintText: s.quickCalcNameHint,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
    final priceField = TextField(
      controller: _price,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: s.quickCalcPrice,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
    final quantityField = TextField(
      controller: _quantity,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _commitDraft(),
      decoration: InputDecoration(
        labelText: s.quickCalcQuantity,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
    final unitField = DropdownButtonFormField<String>(
      key: ValueKey('quick-calc-unit-${_draft.unit}'),
      initialValue: _draft.unit,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: s.quickCalcUnit,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final unit in units)
          DropdownMenuItem<String>(
            value: unit,
            child: Text(unit, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() => _draft.unit = value);
      },
    );
    final addButton = IconButton.filledTonal(
      onPressed: _commitDraft,
      tooltip: s.add,
      icon: const Icon(Icons.check),
    );

    final Widget fieldRow;
    if (wide) {
      fieldRow = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 3, child: nameField),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: priceField),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: quantityField),
          const SizedBox(width: 10),
          SizedBox(width: 120, child: unitField),
          const SizedBox(width: 4),
          addButton,
        ],
      );
    } else {
      fieldRow = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: nameField),
              const SizedBox(width: 8),
              addButton,
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 3, child: priceField),
              const SizedBox(width: 8),
              Expanded(flex: 3, child: quantityField),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: unitField),
            ],
          ),
        ],
      );
    }

    final previewPrice = parseCalcNumber(_price.text);
    final previewQuantity = parseCalcNumber(_quantity.text);
    final preview = previewPrice == null || previewQuantity == null
        ? null
        : computeQuickCalcValues(
            price: previewPrice,
            quantity: previewQuantity,
            unit: _draft.unit,
            isZh: s.isZh,
          );

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            fieldRow,
            const SizedBox(height: 10),
            _buildPreview(context, s, preview),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(
    BuildContext context,
    AppStrings s,
    QuickCalcResult? result,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    if (result == null) {
      return Text(
        s.quickCalcEmptyHint,
        style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          result.primary,
          style: textTheme.titleMedium?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (result.secondary != null)
          Text(
            result.secondary!,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _chip(
    ColorScheme scheme,
    TextTheme textTheme,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color: scheme.onTertiaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
