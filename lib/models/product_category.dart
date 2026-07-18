import 'package:uuid/uuid.dart';

import 'product.dart';

const _uuid = Uuid();

/// Product category (大类), e.g. 肉类 with shared units 斤/g.
class ProductCategory {
  ProductCategory({
    String? id,
    required this.name,
    List<String>? units,
    String? unit,
    this.note = '',
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        units = _normalizeUnits(units, unit),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String name;
  /// Shared measure units inherited by member products.
  List<String> units;
  String note;
  DateTime updatedAt;

  /// Primary / preferred category unit (first).
  String get unit => units.isNotEmpty ? units.first : 'g';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'units': units,
        'unit': unit,
        'note': note,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    final legacyUnit = json['unit'] as String?;
    final units = _normalizeUnits(
      (json['units'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      legacyUnit,
    );
    return ProductCategory(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      units: units,
      note: json['note'] as String? ?? '',
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  ProductCategory copyWith({
    String? name,
    List<String>? units,
    String? note,
  }) =>
      ProductCategory(
        id: id,
        name: name ?? this.name,
        units: units ?? this.units,
        note: note ?? this.note,
        updatedAt: DateTime.now(),
      );

  static List<String> _normalizeUnits(List<String>? units, String? preferred) {
    final result = <String>[];
    void add(String? value) {
      final v = normalizeUnit(value, fallback: '');
      if (v.isEmpty) return;
      if (!result.contains(v)) result.add(v);
    }

    add(preferred);
    if (units != null) {
      for (final u in units) {
        add(u);
      }
    }
    if (result.isEmpty) result.add('g');
    return result;
  }
}
