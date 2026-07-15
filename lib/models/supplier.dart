import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Supplier {
  Supplier({
    String? id,
    required this.name,
    this.note = '',
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String name;
  String note;
  DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'note': note,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
        id: json['id'] as String?,
        name: json['name'] as String? ?? '',
        note: json['note'] as String? ?? '',
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );

  Supplier copyWith({
    String? name,
    String? note,
  }) =>
      Supplier(
        id: id,
        name: name ?? this.name,
        note: note ?? this.note,
        updatedAt: DateTime.now(),
      );
}
