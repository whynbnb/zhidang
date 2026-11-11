import 'package:intl/intl.dart';

import '../models/product.dart';

final _money = NumberFormat('#,##0.##');
final _smallMoney = NumberFormat('#,##0.####');

String _formatMoney(double value) {
  // Keep tiny unit prices readable while matching the app's 2-decimal style.
  return value.abs() < 0.1
      ? _smallMoney.format(value)
      : _money.format(value);
}

/// Short number for showing a row's original price / quantity.
String formatCalcNumber(double value) => _smallMoney.format(value);

enum QuickCalcDimension { count, weight, volume }

/// One unit-price result. [canonical] is per piece / kg / L so entries with
/// the same [groupKey] can be compared even when their input units differ.
class QuickCalcResult {
  const QuickCalcResult({
    required this.dimension,
    required this.groupKey,
    required this.canonical,
    required this.primary,
    this.secondary,
  });

  final QuickCalcDimension dimension;
  final String groupKey;
  final double canonical;
  final String primary;
  final String? secondary;
}

const _weightToGrams = <String, double>{
  'mg': 0.001,
  'g': 1,
  '克': 1,
  'kg': 1000,
  '千克': 1000,
  '公斤': 1000,
  'jin': 500,
  '斤': 500,
  'liang': 50,
  '两': 50,
  'lb': 453.59237,
  'lbs': 453.59237,
  'oz': 28.349523125,
};

const _volumeToMl = <String, double>{
  'ml': 1,
  '毫升': 1,
  'cl': 10,
  'dl': 100,
  'l': 1000,
  '升': 1000,
  'gal': 3785.411784,
};

/// Graph factors from [unit] to every reachable unit. Built-in metric and
/// common weight/volume units are included, then global relations are applied.
Map<String, double> _unitFactors(
  String unit,
  List<UnitRelation> relations,
) {
  final canonical = <String, String>{};
  void remember(String name) {
    final key = name.trim().toLowerCase();
    if (key.isEmpty) return;
    canonical.putIfAbsent(key, () => name.trim());
  }

  for (final key in _weightToGrams.keys) {
    remember(key);
  }
  for (final key in _volumeToMl.keys) {
    remember(key);
  }
  for (final relation in relations) {
    remember(relation.fromUnit);
    remember(relation.toUnit);
  }
  String canon(String name) {
    final trimmed = name.trim();
    return canonical[trimmed.toLowerCase()] ?? trimmed;
  }

  final edges = <String, Map<String, double>>{};
  void addEdge(String from, String to, double factor) {
    if (factor <= 0 || from == to) return;
    edges.putIfAbsent(from, () => {});
    edges[from]![to] = factor;
    edges.putIfAbsent(to, () => {});
    edges[to]![from] = 1 / factor;
  }

  for (final entry in _weightToGrams.entries) {
    addEdge(canon(entry.key), 'g', entry.value);
  }
  for (final entry in _volumeToMl.entries) {
    addEdge(canon(entry.key), 'ml', entry.value);
  }
  for (final relation in relations) {
    addEdge(
      canon(relation.fromUnit),
      canon(relation.toUnit),
      relation.factor,
    );
  }

  final start = canon(unit);
  final result = <String, double>{start: 1};
  final queue = <String>[start];
  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    final currentFactor = result[current]!;
    final next = edges[current];
    if (next == null) continue;
    next.forEach((target, factor) {
      if (result.containsKey(target)) return;
      result[target] = currentFactor * factor;
      queue.add(target);
    });
  }
  return result;
}

/// Units offered by the quick converter, in priority order.
List<String> quickCalcUnitOptions({
  required bool isZh,
  Iterable<String> extra = const [],
}) {
  const zh = [
    '个',
    '斤',
    'kg',
    'g',
    'L',
    'ml',
    '盒',
    '瓶',
    '包',
    '袋',
    '片',
    '卷',
    '张',
  ];
  const en = [
    'pc',
    'kg',
    'g',
    'lb',
    'L',
    'ml',
    'box',
    'bottle',
    'pack',
    'bag',
    'sheet',
    'roll',
  ];
  final options = <String>[];
  for (final unit in [...(isZh ? zh : en), ...extra]) {
    final trimmed = unit.trim();
    if (trimmed.isEmpty || options.contains(trimmed)) continue;
    options.add(trimmed);
  }
  return options;
}

/// Accepts half/full-width digits, commas and Chinese decimal marks.
double? parseCalcNumber(String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) return null;
  const fullWidthDigits = '０１２３４５６７８９';
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    final ch = String.fromCharCode(rune);
    final digit = fullWidthDigits.indexOf(ch);
    if (digit >= 0) {
      buffer.write(digit);
    } else if (ch == '，' || ch == '。' || ch == '．') {
      buffer.write('.');
    } else if (ch == ',' ||
        ch == ' ' ||
        ch == '¥' ||
        ch == '￥' ||
        ch == '元') {
      // Ignore separators and currency marks.
    } else {
      buffer.write(ch);
    }
  }
  final value = double.tryParse(buffer.toString());
  if (value == null || value.isNaN || value.isInfinite || value < 0) {
    return null;
  }
  return value;
}

QuickCalcResult? computeQuickCalc({
  required String priceText,
  required String quantityText,
  required String unit,
  required bool isZh,
  List<UnitRelation> relations = const [],
  String? primaryUnit,
}) {
  final price = parseCalcNumber(priceText);
  final quantity = parseCalcNumber(quantityText);
  if (price == null || quantity == null) return null;
  return computeQuickCalcValues(
    price: price,
    quantity: quantity,
    unit: unit,
    isZh: isZh,
    relations: relations,
    primaryUnit: primaryUnit,
  );
}

double? _factorFor(Map<String, double> factors, String unit) {
  final exact = factors[unit];
  if (exact != null) return exact;
  final lower = unit.trim().toLowerCase();
  for (final entry in factors.entries) {
    if (entry.key.toLowerCase() == lower) return entry.value;
  }
  return null;
}

bool _hasWeight(Map<String, double> factors) =>
    _factorFor(factors, 'kg') != null || _factorFor(factors, 'g') != null;

bool _hasVolume(Map<String, double> factors) =>
    _factorFor(factors, 'L') != null || _factorFor(factors, 'ml') != null;

String _perUnit(double value, String unit) =>
    '¥${_formatMoney(value)} / $unit';

/// Units the current group can display as its primary unit. The first item is
/// also the default. Includes common metric units and units referenced by
/// global relations.
List<String> quickCalcDisplayUnits({
  required String unit,
  required List<UnitRelation> relations,
  required bool isZh,
}) {
  final factors = _unitFactors(unit, relations);
  final custom = <String>{
    unit.trim(),
    for (final relation in relations) ...[
      relation.fromUnit.trim(),
      relation.toUnit.trim(),
    ],
  };
  final result = <String>[];
  void add(String name) {
    if (name.trim().isEmpty) return;
    if (_factorFor(factors, name) == null) return;
    if (result.any((u) => u.toLowerCase() == name.toLowerCase())) return;
    result.add(name);
  }

  if (_hasWeight(factors)) {
    if (isZh) {
      add('斤');
      add('kg');
      add('g');
    } else {
      add('kg');
      add('g');
      add('lb');
    }
  } else if (_hasVolume(factors)) {
    add('L');
    add('ml');
  }

  final extras = factors.keys.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  for (final extra in extras) {
    final referenced = custom.any(
      (name) => name.toLowerCase() == extra.toLowerCase(),
    );
    if (referenced) add(extra);
  }
  return result.isEmpty ? [unit.trim()] : result;
}

QuickCalcResult? computeQuickCalcValues({
  required double price,
  required double quantity,
  required String unit,
  required bool isZh,
  List<UnitRelation> relations = const [],
  String? primaryUnit,
}) {
  if (price < 0 || quantity <= 0) return null;

  final label = unit.trim().isEmpty ? (isZh ? '个' : 'pc') : unit.trim();
  final perInput = price / quantity;
  final factors = _unitFactors(label, relations);
  final weight = _hasWeight(factors);
  final volume = !weight && _hasVolume(factors);

  if (weight) {
    final perKg = perInput / _factorFor(factors, 'kg')!;
    final options = quickCalcDisplayUnits(
      unit: label,
      relations: relations,
      isZh: isZh,
    );
    final primary = primaryUnit != null &&
            _factorFor(factors, primaryUnit) != null
        ? primaryUnit
        : options.first;
    final secondaryCandidates = isZh ? ['kg', '斤'] : ['kg', 'lb'];
    String? secondary;
    for (final candidate in secondaryCandidates) {
      if (candidate.toLowerCase() == primary.toLowerCase()) continue;
      if (_factorFor(factors, candidate) != null) {
        secondary = candidate;
        break;
      }
    }
    return QuickCalcResult(
      dimension: QuickCalcDimension.weight,
      groupKey: 'weight',
      canonical: perKg,
      primary: _perUnit(
        perInput / _factorFor(factors, primary)!,
        primary,
      ),
      secondary: secondary == null
          ? null
          : _perUnit(
              perInput / _factorFor(factors, secondary)!,
              secondary,
            ),
    );
  }

  if (volume) {
    final liters = _factorFor(factors, 'L')!;
    final perL = perInput / liters;
    final options = quickCalcDisplayUnits(
      unit: label,
      relations: relations,
      isZh: isZh,
    );
    final primary = primaryUnit != null &&
            _factorFor(factors, primaryUnit) != null
        ? primaryUnit
        : options.first;
    final String secondaryLabel;
    final double secondaryValue;
    if (primary.toLowerCase() == 'l') {
      secondaryLabel = '100ml';
      secondaryValue = perL / 10;
    } else if (primary.toLowerCase() == 'ml') {
      secondaryLabel = 'L';
      secondaryValue = perL;
    } else {
      secondaryLabel = 'L';
      secondaryValue = perL;
    }
    return QuickCalcResult(
      dimension: QuickCalcDimension.volume,
      groupKey: 'volume',
      canonical: perL,
      primary: _perUnit(
        perInput / _factorFor(factors, primary)!,
        primary,
      ),
      secondary: _perUnit(secondaryValue, secondaryLabel),
    );
  }

  // Count-like component: compare per a stable base unit of the connected
  // group (e.g. 1包 = 200张 groups 包 and 张 together).
  final baseUnits = factors.keys.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  final base = baseUnits.first;
  final baseFactor = factors[base]!;
  final perBase = perInput / baseFactor;
  final options = quickCalcDisplayUnits(
    unit: label,
    relations: relations,
    isZh: isZh,
  );
  final primary = primaryUnit != null &&
          _factorFor(factors, primaryUnit) != null
      ? primaryUnit
      : options.first;
  final secondary = primary.toLowerCase() == label.toLowerCase()
      ? null
      : label;
  return QuickCalcResult(
    dimension: QuickCalcDimension.count,
    groupKey: 'count:${base.toLowerCase()}',
    canonical: perBase,
    primary: _perUnit(
      perInput / _factorFor(factors, primary)!,
      primary,
    ),
    secondary: secondary == null
        ? null
        : _perUnit(
            perInput / _factorFor(factors, secondary)!,
            secondary,
          ),
  );
}
