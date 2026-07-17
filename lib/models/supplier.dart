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
    this.note = '',
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        types = _normalizeTypes(types),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String name;
  List<SupplierType> types;
  String address;
  String note;
  DateTime updatedAt;

  bool get hasStore => types.contains(SupplierType.store);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'types': types.map((e) => e.toJson()).toList(),
        'address': address,
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
    String? note,
  }) =>
      Supplier(
        id: id,
        name: name ?? this.name,
        types: types ?? this.types,
        address: address ?? this.address,
        note: note ?? this.note,
        updatedAt: DateTime.now(),
      );

  static List<SupplierType> _normalizeTypes(List<SupplierType>? types) {
    if (types == null || types.isEmpty) return const [];
    final result = <SupplierType>[];
    for (final t in SupplierType.valuesInOrder) {
      if (types.contains(t)) result.add(t);
    }
    return result;
  }
}
