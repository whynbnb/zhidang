import 'package:intl/intl.dart';

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
}) {
  final price = parseCalcNumber(priceText);
  final quantity = parseCalcNumber(quantityText);
  if (price == null || quantity == null) return null;
  return computeQuickCalcValues(
    price: price,
    quantity: quantity,
    unit: unit,
    isZh: isZh,
  );
}

QuickCalcResult? computeQuickCalcValues({
  required double price,
  required double quantity,
  required String unit,
  required bool isZh,
}) {
  if (price < 0 || quantity <= 0) return null;

  final label = unit.trim().isEmpty ? (isZh ? '个' : 'pc') : unit.trim();
  final key = label.toLowerCase();
  final perInput = price / quantity;

  final grams = _weightToGrams[key];
  if (grams != null && grams > 0) {
    final perKg = perInput * (1000 / grams);
    if (isZh) {
      final perJin = perInput * (500 / grams);
      return QuickCalcResult(
        dimension: QuickCalcDimension.weight,
        groupKey: 'weight',
        canonical: perKg,
        primary: '¥${_formatMoney(perJin)} / 斤',
        secondary: '¥${_formatMoney(perKg)} / kg',
      );
    }
    final perLb = perInput * (453.59237 / grams);
    return QuickCalcResult(
      dimension: QuickCalcDimension.weight,
      groupKey: 'weight',
      canonical: perKg,
      primary: '¥${_formatMoney(perKg)} / kg',
      secondary: '¥${_formatMoney(perLb)} / lb',
    );
  }

  final ml = _volumeToMl[key];
  if (ml != null && ml > 0) {
    final perL = perInput * (1000 / ml);
    final per100 = perInput * (100 / ml);
    return QuickCalcResult(
      dimension: QuickCalcDimension.volume,
      groupKey: 'volume',
      canonical: perL,
      primary: '¥${_formatMoney(perL)} / L',
      secondary: '¥${_formatMoney(per100)} / 100ml',
    );
  }

  return QuickCalcResult(
    dimension: QuickCalcDimension.count,
    groupKey: 'count:$key',
    canonical: perInput,
    primary: '¥${_formatMoney(perInput)} / $label',
  );
}
