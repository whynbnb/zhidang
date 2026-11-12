import 'package:uuid/uuid.dart';

import 'quantity_preset.dart';

const _uuid = Uuid();

class CustomUnit {
  CustomUnit({
    String? id,
    required this.name,
    this.note = '',
    List<QuantityPreset>? presets,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        presets = presets == null ? null : List<QuantityPreset>.from(presets),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String name;
  String note;

  /// Per-unit quick-quantity presets. `null` means use the built-in defaults
  /// for this unit name; an empty list means the user cleared them.
  List<QuantityPreset>? presets;
  DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'note': note,
        if (presets != null)
          'presets': presets!.map((preset) => preset.toJson()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CustomUnit.fromJson(Map<String, dynamic> json) => CustomUnit(
        id: json['id'] as String?,
        name: json['name'] as String? ?? '',
        note: json['note'] as String? ?? '',
        presets: json.containsKey('presets')
            ? (json['presets'] as List<dynamic>? ?? const [])
                .map(
                  (e) => QuantityPreset.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList()
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );

  CustomUnit copyWith({
    String? name,
    String? note,
    List<QuantityPreset>? presets,
    bool resetPresets = false,
  }) =>
      CustomUnit(
        id: id,
        name: name ?? this.name,
        note: note ?? this.note,
        presets: resetPresets ? null : (presets ?? this.presets),
        updatedAt: DateTime.now(),
      );
}
