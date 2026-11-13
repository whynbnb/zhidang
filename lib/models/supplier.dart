import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum SupplierType {
  ecommerce,
  delivery,
  store;

  static const valuesInOrder = [
    SupplierType.ecommerce,
    SupplierType.delivery,
    SupplierType.store,
  ];

  static SupplierType? tryParse(Object? raw) {
    switch (raw?.toString()) {
      case 'ecommerce':
        return SupplierType.ecommerce;
      case 'delivery':
        return SupplierType.delivery;
      case 'store':
        return SupplierType.store;
      default:
        return null;
    }
  }

  String toJson() => name;
}

class Supplier {
  Supplier({
    String? id,
    required this.name,
    List<SupplierType>? types,
    this.address = '',
    List<String>? areas,
    this.note = '',
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        types = _normalizeTypes(types),
        areas = _normalizeAreas(areas),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String name;
  List<SupplierType> types;
  String address;
  /// Areas or departments that belong to this supplier, e.g. 熟食区 / 生鲜区.
  List<String> areas;
  String note;
  DateTime updatedAt;

  bool get hasStore => types.contains(SupplierType.store);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'types': types.map((e) => e.toJson()).toList(),
        'address': address,
        'areas': areas,
        'note': note,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Supplier.fromJson(Map<String, dynamic> json) {
    final rawTypes = json['types'] as List<dynamic>?;
    final types = rawTypes
            ?.map(SupplierType.tryParse)
            .whereType<SupplierType>()
            .toList() ??
        const <SupplierType>[];
    return Supplier(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      types: types,
      address: json['address'] as String? ?? '',
      areas: (json['areas'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      note: json['note'] as String? ?? '',
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Supplier copyWith({
    String? name,
    List<SupplierType>? types,
    String? address,
    List<String>? areas,
    String? note,
  }) =>
      Supplier(
        id: id,
        name: name ?? this.name,
        types: types ?? this.types,
        address: address ?? this.address,
        areas: areas ?? this.areas,
        note: note ?? this.note,
        updatedAt: DateTime.now(),
      );

  static List<String> _normalizeAreas(List<String>? areas) {
    if (areas == null || areas.isEmpty) return const [];
    final result = <String>[];
    final seen = <String>{};
    for (final raw in areas) {
      final name = raw.trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      result.add(name);
    }
    return result;
  }

  static List<SupplierType> _normalizeTypes(List<SupplierType>? types) {
    if (types == null || types.isEmpty) return const [];
    final result = <SupplierType>[];
    for (final t in SupplierType.valuesInOrder) {
      if (types.contains(t)) result.add(t);
    }
    return result;
  }
}
