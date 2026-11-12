import '../models/quantity_preset.dart';
import '../services/unit_store.dart';

/// Presets configured for [unit], or the built-in defaults when the unit has
/// no custom list. Disabled presets are kept in the configured list.
List<QuantityPreset> editableQuantityPresetsFor(String unit) {
  return UnitStore.instance.findByName(unit)?.presets ??
      defaultQuantityPresetsFor(unit);
}

/// Presets that the offer editor should show: configured/default minus any
/// entries the user disabled.
List<QuantityPreset> quantityPresetsFor(String unit) {
  return editableQuantityPresetsFor(unit)
      .where((preset) => preset.enabled && preset.value > 0)
      .toList();
}

List<QuantityPreset> defaultQuantityPresetsFor(String unit) {
  switch (unit) {
    case 'g':
      return const [
        QuantityPreset(value: 50, label: '50g'),
        QuantityPreset(value: 100, label: '100g'),
        QuantityPreset(value: 200, label: '200g'),
        QuantityPreset(value: 250, label: '250g'),
        QuantityPreset(value: 500, label: '500g'),
        QuantityPreset(value: 1000, label: '1kg'),
      ];
    case 'kg':
      return const [
        QuantityPreset(value: 0.1, label: '100g'),
        QuantityPreset(value: 0.25, label: '250g'),
        QuantityPreset(value: 0.5, label: '500g'),
        QuantityPreset(value: 1, label: '1kg'),
        QuantityPreset(value: 2, label: '2kg'),
        QuantityPreset(value: 5, label: '5kg'),
      ];
    case 'ml':
      return const [
        QuantityPreset(value: 100, label: '100ml'),
        QuantityPreset(value: 250, label: '250ml'),
        QuantityPreset(value: 500, label: '500ml'),
        QuantityPreset(value: 750, label: '750ml'),
        QuantityPreset(value: 1000, label: '1L'),
        QuantityPreset(value: 1500, label: '1.5L'),
      ];
    case 'L':
      return const [
        QuantityPreset(value: 0.25, label: '250ml'),
        QuantityPreset(value: 0.5, label: '500ml'),
        QuantityPreset(value: 1, label: '1L'),
        QuantityPreset(value: 1.5, label: '1.5L'),
        QuantityPreset(value: 2, label: '2L'),
        QuantityPreset(value: 5, label: '5L'),
      ];
    case '个':
    case 'pc':
      return _countPresets(unit);
    case '包':
    case 'pack':
      return _countPresets(unit);
    case '盒':
    case 'box':
      return const [
        QuantityPreset(value: 1, label: '1'),
        QuantityPreset(value: 2, label: '2'),
        QuantityPreset(value: 3, label: '3'),
        QuantityPreset(value: 4, label: '4'),
        QuantityPreset(value: 6, label: '6'),
        QuantityPreset(value: 12, label: '12'),
      ];
    case '瓶':
    case 'bottle':
      return const [
        QuantityPreset(value: 1, label: '1'),
        QuantityPreset(value: 2, label: '2'),
        QuantityPreset(value: 3, label: '3'),
        QuantityPreset(value: 4, label: '4'),
        QuantityPreset(value: 6, label: '6'),
        QuantityPreset(value: 12, label: '12'),
      ];
    case '袋':
    case 'bag':
      return _countPresets(unit);
    case '卷':
    case 'roll':
      return const [
        QuantityPreset(value: 1, label: '1'),
        QuantityPreset(value: 2, label: '2'),
        QuantityPreset(value: 4, label: '4'),
        QuantityPreset(value: 6, label: '6'),
        QuantityPreset(value: 8, label: '8'),
        QuantityPreset(value: 10, label: '10'),
        QuantityPreset(value: 12, label: '12'),
      ];
    case '张':
    case '片':
    case 'sheet':
      return const [
        QuantityPreset(value: 50, label: '50'),
        QuantityPreset(value: 100, label: '100'),
        QuantityPreset(value: 200, label: '200'),
        QuantityPreset(value: 300, label: '300'),
        QuantityPreset(value: 500, label: '500'),
        QuantityPreset(value: 1000, label: '1000'),
      ];
    default:
      return const [
        QuantityPreset(value: 1, label: '1'),
        QuantityPreset(value: 2, label: '2'),
        QuantityPreset(value: 3, label: '3'),
        QuantityPreset(value: 5, label: '5'),
        QuantityPreset(value: 10, label: '10'),
      ];
  }
}

List<QuantityPreset> _countPresets(String unit) {
  final suffix = unit;
  return [
    QuantityPreset(value: 1, label: '1$suffix'),
    QuantityPreset(value: 2, label: '2$suffix'),
    QuantityPreset(value: 3, label: '3$suffix'),
    QuantityPreset(value: 5, label: '5$suffix'),
    QuantityPreset(value: 6, label: '6$suffix'),
    QuantityPreset(value: 10, label: '10$suffix'),
  ];
}

String formatQuantityValue(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  final text = value.toStringAsFixed(3);
  return text.replaceFirst(RegExp(r'\.?0+$'), '');
}
