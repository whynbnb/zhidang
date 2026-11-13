import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/quick_calc_store.dart';
import '../services/unit_store.dart';
import '../settings/app_settings.dart';
import '../utils/quick_calc.dart';
import 'quick_offer_picker.dart';
import 'unit_conversions_page.dart';

class QuickCalcPage extends StatefulWidget {
  const QuickCalcPage({super.key});

  static const routeName = '/quick-calc';

  @override
  State<QuickCalcPage> createState() => _QuickCalcPageState();
}

class _QuickCalcPageState extends State<QuickCalcPage>
    with SingleTickerProviderStateMixin {
  final _store = QuickCalcStore.instance;

  late final TabController _tabs;
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _quantity;
  late final TextEditingController _comboTarget;
  final _comboCounts = <String, int>{};
  final _draftRevision = ValueNotifier<int>(0);
  final _priceFocus = FocusNode();
  final _quantityFocus = FocusNode();
  final _nameFocus = FocusNode();

  bool get _isZh => AppSettings.instance.locale.languageCode != 'en';

  String get _defaultUnit => _isZh ? '个' : 'pc';

  QuickCalcDraft get _draft => _store.draft;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    UnitStore.instance.addListener(_onUnitsChanged);
    if (_draft.unit.isEmpty) {
      _draft.unit = _defaultUnit;
    }
    _name = TextEditingController(text: _draft.name);
    _price = TextEditingController(text: _draft.price);
    _quantity = TextEditingController(text: _draft.quantity);
    _comboTarget = TextEditingController();
    _name.addListener(_syncDraft);
    _price.addListener(_syncDraft);
    _quantity.addListener(_syncDraft);
    _comboTarget.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _onUnitsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    UnitStore.instance.removeListener(_onUnitsChanged);
    _tabs.dispose();
    _name.dispose();
    _price.dispose();
    _quantity.dispose();
    _comboTarget.dispose();
    _draftRevision.dispose();
    _priceFocus.dispose();
    _quantityFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _syncDraft() {
    _draft.name = _name.text;
    _draft.price = _price.text;
    _draft.quantity = _quantity.text;
    _draftRevision.value++;
    if (mounted) setState(() {});
  }

  bool _commitDraft() {
    final s = AppStrings.of(context);
    final price = parseCalcNumber(_price.text);
    final quantity = parseCalcNumber(_quantity.text);
    if (price == null) {
      _priceFocus.requestFocus();
      _showIncomplete(s);
      return false;
    }
    if (quantity == null || quantity <= 0) {
      _quantityFocus.requestFocus();
      _showIncomplete(s);
      return false;
    }
    final entry = _store.commit(
      name: _name.text.trim(),
      price: price,
      quantity: quantity,
      unit: _draft.unit,
    );
    if (_tabs.index == 1) {
      _comboCounts[entry.id] = 1;
    }
    _name.clear();
    _price.clear();
    _quantity.clear();
    setState(() {});
    return true;
  }

  void _submitFromSheet() {
    if (!_commitDraft()) return;
    Navigator.of(context).maybePop();
  }

  Future<void> _pickSavedOffers({bool closeSheet = false}) async {
    final s = AppStrings.of(context);
    FocusManager.instance.primaryFocus?.unfocus();
    final picks = await showQuickOfferPicker(context);
    if (picks == null || picks.isEmpty || !mounted) return;
    var added = 0;
    for (final pick in picks) {
      if (pick.quantity <= 0 || pick.unit.isEmpty) continue;
      final entry = _store.commit(
        name: pick.name.trim(),
        price: pick.price,
        quantity: pick.quantity,
        unit: pick.unit,
        fromSaved: true,
      );
      if (_tabs.index == 1) {
        _comboCounts[entry.id] = 1;
      }
      added++;
    }
    if (added == 0) return;
    _name.clear();
    _price.clear();
    _quantity.clear();
    setState(() {});
    if (closeSheet) Navigator.of(context).maybePop();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(s.quickCalcPickSavedAdded(added))),
      );
  }

  void _showIncomplete(AppStrings s) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(s.quickCalcIncomplete)));
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
    await _store.clear();
    _name.clear();
    _price.clear();
    _quantity.clear();
    _comboTarget.clear();
    _comboCounts.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

    final relations = UnitStore.instance.relations;
    final provisional = <String, QuickCalcResult?>{};
    final groups = <String, List<QuickCalcEntry>>{};
    for (final entry in _store.entries) {
      final result = computeQuickCalcValues(
        price: entry.price,
        quantity: entry.quantity,
        unit: entry.unit,
        isZh: s.isZh,
        relations: relations,
      );
      provisional[entry.id] = result;
      final key = result?.groupKey ?? 'unknown:${entry.id}';
      groups.putIfAbsent(key, () => []).add(entry);
    }

    final groupPrimaries = <String, String>{};
    final groupOptions = <String, List<String>>{};
    for (final group in groups.entries) {
      final first = group.value.first;
      final primaryOptions = quickCalcDisplayUnits(
        unit: first.unit,
        relations: relations,
        isZh: s.isZh,
      );
      final options = UnitStore.instance.sortUnits(primaryOptions);
      var primary = primaryOptions.first;
      final stored = _store.primaryUnits[group.key];
      if (stored != null) {
        for (final option in options) {
          if (option.toLowerCase() == stored.toLowerCase()) {
            primary = option;
            break;
          }
        }
      }
      groupPrimaries[group.key] = primary;
      groupOptions[group.key] = options;
    }

    final results = <String, QuickCalcResult?>{};
    final groupCounts = <String, int>{};
    final groupBest = <String, double>{};
    for (final entry in _store.entries) {
      final groupKey = provisional[entry.id]?.groupKey;
      final result = computeQuickCalcValues(
        price: entry.price,
        quantity: entry.quantity,
        unit: entry.unit,
        isZh: s.isZh,
        relations: relations,
        primaryUnit: groupKey == null ? null : groupPrimaries[groupKey],
      );
      results[entry.id] = result;
      if (result == null) continue;
      groupCounts[result.groupKey] = (groupCounts[result.groupKey] ?? 0) + 1;
      final best = groupBest[result.groupKey];
      if (best == null || result.canonical < best) {
        groupBest[result.groupKey] = result.canonical;
      }
    }

    final convertView = SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
        children: [
          for (final group in groups.entries) ...[
            _buildGroupHeader(
              context,
              s,
              group.key,
              group.value,
              primary: groupPrimaries[group.key]!,
              options: groupOptions[group.key]!,
              onPrimarySelected: (unit) => setState(
                () => _store.primaryUnits[group.key] = unit,
              ),
            ),
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
        ],
      ),
    );

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
          IconButton(
            tooltip: s.quickCalcPickSaved,
            onPressed: _pickSavedOffers,
            icon: const Icon(Icons.playlist_add),
          ),
          IconButton(
            tooltip: s.unitConversions,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                settings: const RouteSettings(
                  name: UnitConversionsPage.routeName,
                ),
                builder: (_) => const UnitConversionsPage(),
              ),
            ),
            icon: const Icon(Icons.swap_horiz),
          ),
          TextButton(
            onPressed: _store.hasData ? _clearAll : null,
            child: Text(s.quickCalcClear),
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: s.quickCalcTabConvert),
            Tab(text: s.quickCalcTabCombo),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'quick-calc-add',
        onPressed: _showAddSheet,
        tooltip: s.quickCalcAddItem,
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          convertView,
          _buildComboView(context, s),
        ],
      ),
    );
  }

  Future<void> _showAddSheet() async {
    final s = AppStrings.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _priceFocus.requestFocus();
        });
        return AnimatedBuilder(
          animation: Listenable.merge([
            _name,
            _price,
            _quantity,
            _draftRevision,
          ]),
          builder: (context, _) {
            final insets = MediaQuery.viewInsetsOf(context);
            final wide = MediaQuery.sizeOf(context).width >= 720;
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  16 + insets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.quickCalcAddItem,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            tooltip: MaterialLocalizations.of(context)
                                .closeButtonTooltip,
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      _buildDraftCard(context, s, wide: wide),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => _pickSavedOffers(closeSheet: true),
                        icon: const Icon(Icons.playlist_add, size: 20),
                        label: Text(s.quickCalcPickSaved),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildComboView(BuildContext context, AppStrings s) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final entries = _store.entries;
    final target = parseCalcNumber(_comboTarget.text);
    final hasTarget = target != null && target > 0;

    var total = 0.0;
    for (final entry in entries) {
      total += entry.price * (_comboCounts[entry.id] ?? 0);
    }
    final reached = hasTarget && total >= target - 1e-9;
    final over = hasTarget && total > target + 1e-9;
    final remaining = hasTarget ? target - total : null;

    final String? summaryChip;
    if (!hasTarget) {
      summaryChip = null;
    } else if (over) {
      summaryChip = s.quickCalcComboOver(formatCalcNumber(total - target));
    } else if (reached) {
      summaryChip = s.quickCalcComboReached;
    } else {
      summaryChip = s.quickCalcComboRemaining(
        formatCalcNumber(remaining!),
      );
    }

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          Card(
            elevation: 0,
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _comboTarget,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: s.quickCalcComboTarget,
                      prefixText: '¥ ',
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.quickCalcComboSelected,
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '¥${formatCalcNumber(total)}',
                              style: textTheme.titleLarge?.copyWith(
                                color: reached ? scheme.tertiary : scheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (summaryChip != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: reached
                                ? scheme.tertiaryContainer
                                : scheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            summaryChip,
                            style: textTheme.labelMedium?.copyWith(
                              color: reached
                                  ? scheme.onTertiaryContainer
                                  : scheme.onSecondaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (hasTarget) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: (total / target).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: scheme.surfaceContainerHighest,
                        color: reached ? scheme.tertiary : scheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.shopping_basket_outlined,
                    size: 48,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.quickCalcComboEmptyTitle,
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.quickCalcComboEmptyHint,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: () => _tabs.animateTo(0),
                    icon: const Icon(Icons.swap_horiz),
                    label: Text(s.quickCalcComboGoConvert),
                  ),
                ],
              ),
            )
          else ...[
            // The clear button stays mounted (just disabled) so the header
            // keeps the same height when the first portion is selected.
            Row(
              key: const ValueKey('quick-calc-combo-header'),
              children: [
                Expanded(
                  child: Text(
                    s.quickCalcComboItems,
                    style: textTheme.titleSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ExcludeSemantics(
                  excluding: _comboCounts.isEmpty,
                  child: IgnorePointer(
                    ignoring: _comboCounts.isEmpty,
                    child: AnimatedOpacity(
                      key: const ValueKey('quick-calc-combo-clear'),
                      opacity: _comboCounts.isEmpty ? 0 : 1,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      child: TextButton.icon(
                        onPressed: () => setState(_comboCounts.clear),
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: Text(s.quickCalcComboClearSelection),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final entry in entries) ...[
              _buildComboRow(context, s, entry),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildComboRow(
    BuildContext context,
    AppStrings s,
    QuickCalcEntry entry,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final count = _comboCounts[entry.id] ?? 0;
    final selected = count > 0;
    final unitPrice = entry.quantity > 0 ? entry.price / entry.quantity : 0.0;
    final priceLine = '¥${formatCalcNumber(entry.price)} / '
        '${formatCalcNumber(entry.quantity)} ${entry.unit}';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: selected
            ? scheme.primaryContainer.withValues(alpha: 0.35)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.name.isEmpty ? priceLine : entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (entry.fromSaved) ...[
                      const SizedBox(width: 6),
                      _savedMark(context, s),
                    ],
                  ],
                ),
                Text(
                  entry.name.isEmpty
                      ? '¥${formatCalcNumber(unitPrice)} / ${entry.unit}'
                      : '$priceLine · ¥${formatCalcNumber(unitPrice)} / ${entry.unit}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (selected)
                  Text(
                    s.quickCalcComboSubtotal(
                      formatCalcNumber(entry.price * count),
                    ),
                    style: textTheme.labelMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: count > 0
                ? () => setState(() {
                      if (count <= 1) {
                        _comboCounts.remove(entry.id);
                      } else {
                        _comboCounts[entry.id] = count - 1;
                      }
                    })
                : null,
            tooltip: s.quickCalcComboRemoveOne,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove_circle_outline, size: 20),
          ),
          Semantics(
            button: true,
            label: s.quickCalcComboEditCount,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPress: () => _editComboCount(context, s, entry),
              child: SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: Text(
                    '×$count',
                    textAlign: TextAlign.center,
                    style: textTheme.titleSmall?.copyWith(
                      color:
                          selected ? scheme.primary : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () =>
                setState(() => _comboCounts[entry.id] = count + 1),
            tooltip: s.quickCalcComboAddOne,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add_circle_outline, size: 20),
          ),
        ],
      ),
    );
  }

  Future<void> _editComboCount(
    BuildContext context,
    AppStrings s,
    QuickCalcEntry entry,
  ) async {
    final formKey = GlobalKey<FormState>();
    var text = '${_comboCounts[entry.id] ?? 0}';
    final next = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.quickCalcComboCountTitle),
        content: Form(
          key: formKey,
          child: TextFormField(
            initialValue: text,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: s.quickCalcComboCountLabel,
              helperText: s.quickCalcComboCountHint,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) => text = value,
            validator: (value) {
              final n = int.tryParse((value ?? '').trim());
              if (n == null || n < 0) {
                return s.quickCalcComboCountInvalid;
              }
              return null;
            },
            onFieldSubmitted: (_) {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(int.parse(text.trim()));
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(int.parse(text.trim()));
              }
            },
            child: Text(s.save),
          ),
        ],
      ),
    );
    if (next == null || !mounted) return;
    setState(() {
      if (next <= 0) {
        _comboCounts.remove(entry.id);
      } else {
        _comboCounts[entry.id] = next;
      }
    });
  }

  Widget _savedMark(BuildContext context, AppStrings s) {
    return Semantics(
      label: s.quickCalcFromSaved,
      child: Tooltip(
        message: s.quickCalcFromSavedHint,
        triggerMode: TooltipTriggerMode.longPress,
        child: Icon(
          Icons.inventory_2_outlined,
          size: 14,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildGroupHeader(
    BuildContext context,
    AppStrings s,
    String groupKey,
    List<QuickCalcEntry> entries, {
    required String primary,
    required List<String> options,
    required ValueChanged<String> onPrimarySelected,
  }) {
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
      final units = entries
          .map((entry) => entry.unit)
          .toSet()
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      label = s.quickCalcGroupUnit(units.join(' / '));
    } else {
      icon = Icons.tag;
      label = entries.first.unit;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              Icon(icon, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.55,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Divider(height: 1, color: scheme.outlineVariant),
              ),
              const SizedBox(width: 8),
              if (options.length > 1)
                PopupMenuButton<String>(
                  key: ValueKey('quick-calc-primary-$groupKey'),
                  tooltip: s.quickCalcPrimaryUnit,
                  initialValue: primary,
                  onSelected: onPrimarySelected,
                  itemBuilder: (_) => [
                    for (final option in options)
                      PopupMenuItem<String>(
                        value: option,
                        child: Text(option),
                      ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          primary,
                          style: textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 18,
                          color: scheme.primary,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    primary,
                    style: textTheme.labelMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          );
        },
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
                if (entry.fromSaved) _savedMark(context, s),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () async {
                  await _store.togglePin(entry.id);
                  if (mounted) setState(() {});
                },
                tooltip: entry.pinned ? s.quickCalcUnpin : s.quickCalcPin,
                visualDensity: VisualDensity.compact,
                color: entry.pinned ? scheme.tertiary : null,
                icon: Icon(
                  entry.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 20,
                ),
              ),
              IconButton(
                onPressed: () async {
                  await _store.remove(entry.id);
                  if (mounted) setState(() {});
                },
                tooltip: s.quickCalcDeleteRow,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
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
      extra: [
        ...UnitStore.instance.names,
        for (final relation in UnitStore.instance.relations) ...[
          relation.fromUnit,
          relation.toUnit,
        ],
      ],
    );
    if (!units.contains(_draft.unit)) {
      units.insert(0, _draft.unit);
    }

    final nameField = TextField(
      controller: _name,
      focusNode: _nameFocus,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _submitFromSheet(),
      decoration: InputDecoration(
        labelText: s.quickCalcName,
        hintText: s.quickCalcNameHint,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
    final priceField = TextField(
      controller: _price,
      focusNode: _priceFocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      onSubmitted: (_) => _quantityFocus.requestFocus(),
      decoration: InputDecoration(
        labelText: s.quickCalcPrice,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
    final quantityField = TextField(
      controller: _quantity,
      focusNode: _quantityFocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _submitFromSheet(),
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
        _draftRevision.value++;
      },
    );
    final addButton = IconButton.filledTonal(
      onPressed: _submitFromSheet,
      tooltip: s.add,
      icon: const Icon(Icons.check),
    );

    final Widget fieldRow;
    if (wide) {
      fieldRow = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 2, child: priceField),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: quantityField),
          const SizedBox(width: 10),
          SizedBox(width: 120, child: unitField),
          const SizedBox(width: 10),
          Expanded(flex: 3, child: nameField),
          const SizedBox(width: 4),
          addButton,
        ],
      );
    } else {
      fieldRow = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: nameField),
              const SizedBox(width: 8),
              addButton,
            ],
          ),
        ],
      );
    }

    final previewPrice = parseCalcNumber(_price.text);
    final previewQuantity = parseCalcNumber(_quantity.text);
    final relations = UnitStore.instance.relations;
    final provisional = previewPrice == null || previewQuantity == null
        ? null
        : computeQuickCalcValues(
            price: previewPrice,
            quantity: previewQuantity,
            unit: _draft.unit,
            isZh: s.isZh,
            relations: relations,
          );
    String? previewPrimary;
    if (provisional != null) {
      final primaryOptions = quickCalcDisplayUnits(
        unit: _draft.unit,
        relations: relations,
        isZh: s.isZh,
      );
      final options = UnitStore.instance.sortUnits(primaryOptions);
      previewPrimary = primaryOptions.first;
      final stored = _store.primaryUnits[provisional.groupKey];
      if (stored != null) {
        for (final option in options) {
          if (option.toLowerCase() == stored.toLowerCase()) {
            previewPrimary = option;
            break;
          }
        }
      }
    }
    final preview = provisional == null
        ? null
        : computeQuickCalcValues(
            price: previewPrice!,
            quantity: previewQuantity!,
            unit: _draft.unit,
            isZh: s.isZh,
            relations: relations,
            primaryUnit: previewPrimary,
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
            if (preview != null) ...[
              const SizedBox(height: 10),
              _buildPreview(context, preview),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context, QuickCalcResult result) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
