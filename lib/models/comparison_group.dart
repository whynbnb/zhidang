import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// A fixed cross-product comparison set (e.g. 猪肉 / 牛肉 / 羊肉).
class ComparisonGroup {
  ComparisonGroup({
    String? id,
    required this.name,
    List<String>? productIds,
    this.note = '',
    this.preferredUnit = '',
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        productIds = _normalizeIds(productIds),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String name;
  List<String> productIds;
  String note;
  /// Optional preferred compare unit; empty = auto-pick first common.
  String preferredUnit;
  DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'productIds': productIds,
        'note': note,
        'preferredUnit': preferredUnit,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ComparisonGroup.fromJson(Map<String, dynamic> json) =>
      ComparisonGroup(
        id: json['id'] as String?,
        name: json['name'] as String? ?? '',
        productIds: (json['productIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        note: json['note'] as String? ?? '',
        preferredUnit: json['preferredUnit'] as String? ?? '',
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );

  ComparisonGroup copyWith({
    String? name,
    List<String>? productIds,
    String? note,
    String? preferredUnit,
  }) =>
      ComparisonGroup(
        id: id,
        name: name ?? this.name,
        productIds: productIds ?? this.productIds,
        note: note ?? this.note,
        preferredUnit: preferredUnit ?? this.preferredUnit,
        updatedAt: DateTime.now(),
      );

  static List<String> _normalizeIds(List<String>? ids) {
    if (ids == null || ids.isEmpty) return const [];
    final result = <String>[];
    final seen = <String>{};
    for (final raw in ids) {
      final id = raw.trim();
      if (id.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      result.add(id);
    }
    return result;
  }
}
