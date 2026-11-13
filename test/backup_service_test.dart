import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zhidang/services/backup_service.dart';

void main() {
  final service = BackupService.instance;

  test('parses a full backup', () {
    final raw = jsonEncode({
      'version': 1,
      'app': 'zhidang',
      'products': [
        {
          'id': 'p1',
          'name': '牛奶',
          'units': ['ml'],
          'offers': <Map<String, dynamic>>[],
        },
      ],
      'suppliers': [
        {'id': 's1', 'name': '超市', 'areas': ['熟食区']},
      ],
      'categories': [
        {
          'id': 'c1',
          'name': '乳品',
          'units': ['ml', 'L'],
        },
      ],
      'units': [
        {'id': 'u1', 'name': 'ml'},
      ],
      'comparisons': [
        {
          'id': 'g1',
          'name': '乳品对比',
          'productIds': ['p1'],
        },
      ],
    });

    final payload = service.parse(raw);
    expect(payload.products, hasLength(1));
    expect(payload.suppliers, hasLength(1));
    expect(payload.suppliers.single.areas, ['熟食区']);
    expect(payload.categories.single.units, ['ml', 'L']);
    expect(payload.units, hasLength(1));
    expect(payload.comparisons, hasLength(1));
  });

  test('strips UTF-8 BOM', () {
    final raw = jsonEncode({
      'app': 'zhidang',
      'products': <Map<String, dynamic>>[],
      'suppliers': <Map<String, dynamic>>[],
      'units': <Map<String, dynamic>>[],
    });
    final payload = service.parse('\uFEFF$raw');
    expect(payload.products, isEmpty);
  });

  test('tolerates missing optional sections', () {
    final raw = jsonEncode({
      'app': 'zhidang',
      'products': <Map<String, dynamic>>[],
    });
    final payload = service.parse(raw);
    expect(payload.products, isEmpty);
    expect(payload.suppliers, isEmpty);
    expect(payload.categories, isEmpty);
    expect(payload.units, isEmpty);
    expect(payload.comparisons, isEmpty);
  });

  test('rejects foreign or malformed files', () {
    expect(
      () => service.parse(jsonEncode({'app': 'other', 'products': []})),
      throwsFormatException,
    );
    expect(
      () => service.parse(jsonEncode({'app': 'zhidang'})),
      throwsFormatException,
    );
    // Arbitrary JSON with a products key but no backup markers.
    expect(
      () => service.parse(jsonEncode({'products': []})),
      throwsFormatException,
    );
    expect(() => service.parse('not json'), throwsA(isA<FormatException>()));
  });
}
