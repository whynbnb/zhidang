import 'package:flutter_test/flutter_test.dart';
import 'package:zhidang/models/product.dart';
import 'package:zhidang/utils/quick_calc.dart';

void main() {
  group('computeQuickCalc', () {
    test('counts price per piece', () {
      final result = computeQuickCalc(
        priceText: '20',
        quantityText: '15',
        unit: '个',
        isZh: true,
      );
      expect(result, isNotNull);
      expect(result!.dimension, QuickCalcDimension.count);
      expect(result.canonical, closeTo(20 / 15, 1e-9));
      expect(result.primary, '¥1.33 / 个');
      expect(result.secondary, isNull);
    });

    test('grams show price per jin and per kg', () {
      final result = computeQuickCalc(
        priceText: '9.6',
        quantityText: '400',
        unit: 'g',
        isZh: true,
      );
      expect(result, isNotNull);
      expect(result!.dimension, QuickCalcDimension.weight);
      expect(result.canonical, closeTo(24, 1e-9));
      expect(result.primary, '¥12 / 斤');
      expect(result.secondary, '¥24 / kg');
    });

    test('jin input converts to kg', () {
      final result = computeQuickCalc(
        priceText: '30',
        quantityText: '0.5',
        unit: '斤',
        isZh: true,
      );
      expect(result, isNotNull);
      expect(result!.canonical, closeTo(120, 1e-9));
      expect(result.primary, '¥60 / 斤');
      expect(result.secondary, '¥120 / kg');
    });

    test('volume converts to per litre', () {
      final result = computeQuickCalc(
        priceText: '10',
        quantityText: '2',
        unit: 'L',
        isZh: true,
      );
      expect(result, isNotNull);
      expect(result!.dimension, QuickCalcDimension.volume);
      expect(result.canonical, closeTo(5, 1e-9));
      expect(result.primary, '¥5 / L');
      expect(result.secondary, '¥0.5 / 100ml');
    });

    test('english weight uses kg and lb', () {
      final result = computeQuickCalc(
        priceText: '9.6',
        quantityText: '400',
        unit: 'g',
        isZh: false,
      );
      expect(result, isNotNull);
      expect(result!.primary, '¥24 / kg');
      expect(result.secondary, startsWith('¥'));
      expect(result.secondary, endsWith('/ lb'));
    });

    test('accepts full-width digits and chinese decimal mark', () {
      final result = computeQuickCalc(
        priceText: '２０，５',
        quantityText: '10',
        unit: '个',
        isZh: true,
      );
      expect(result, isNotNull);
      expect(result!.canonical, closeTo(2.05, 1e-9));
    });

    test('rejects missing or non-positive quantity', () {
      expect(
        computeQuickCalc(
          priceText: '10',
          quantityText: '0',
          unit: '个',
          isZh: true,
        ),
        isNull,
      );
      expect(
        computeQuickCalc(
          priceText: '10',
          quantityText: '',
          unit: '个',
          isZh: true,
        ),
        isNull,
      );
    });
  });

  test('unit options follow the supplied order, then common choices', () {
    final options = quickCalcUnitOptions(
      isZh: true,
      extra: const ['个', '箱'],
    );
    expect(options.take(3), ['个', '箱', '斤']);
    expect(options.where((unit) => unit == '个').length, 1);
    expect(options, contains('箱'));
  });

  test('global relations convert custom weight units', () {
    final result = computeQuickCalcValues(
      price: 30,
      quantity: 1,
      unit: '箱',
      isZh: true,
      relations: [
        UnitRelation(fromUnit: '箱', toUnit: 'kg', factor: 6),
      ],
    );
    expect(result, isNotNull);
    expect(result!.dimension, QuickCalcDimension.weight);
    expect(result.canonical, closeTo(5, 1e-9));
    expect(result.primary, '¥2.5 / 斤');
    expect(result.secondary, '¥5 / kg');
  });

  test('global count relations group related units together', () {
    final relations = [
      UnitRelation(fromUnit: '包', toUnit: '张', factor: 200),
    ];
    final pack = computeQuickCalcValues(
      price: 10,
      quantity: 1,
      unit: '包',
      isZh: true,
      relations: relations,
    )!;
    final sheet = computeQuickCalcValues(
      price: 10,
      quantity: 200,
      unit: '张',
      isZh: true,
      relations: relations,
    )!;

    expect(pack.groupKey, sheet.groupKey);
    expect(pack.canonical, closeTo(10, 1e-9));
    expect(sheet.canonical, closeTo(10, 1e-9));
    expect(pack.primary, '¥10 / 包');
    expect(sheet.primary, '¥10 / 包');
    expect(sheet.secondary, '¥0.05 / 张');
  });

  test('primary display unit can switch weight output', () {
    final result = computeQuickCalcValues(
      price: 123,
      quantity: 5,
      unit: 'kg',
      isZh: true,
      primaryUnit: 'kg',
    )!;
    expect(result.primary, '¥24.6 / kg');
    expect(result.secondary, '¥12.3 / 斤');

    final options = quickCalcDisplayUnits(
      unit: 'kg',
      relations: const [],
      isZh: true,
    );
    expect(options.take(3), ['斤', 'kg', 'g']);
  });
}
