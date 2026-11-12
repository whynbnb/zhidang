class QuantityPreset {
  const QuantityPreset({
    required this.value,
    required this.label,
    this.enabled = true,
  });

  /// Quantity inserted when the preset is tapped.
  final double value;

  /// Text shown on the quick-quantity button.
  final String label;

  /// Disabled presets stay configured but are hidden from the offer editor.
  final bool enabled;

  Map<String, dynamic> toJson() => {
        'value': value,
        'label': label,
        'enabled': enabled,
      };

  factory QuantityPreset.fromJson(Map<String, dynamic> json) => QuantityPreset(
        value: (json['value'] as num?)?.toDouble() ?? 0,
        label: json['label'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? true,
      );

  QuantityPreset copyWith({
    double? value,
    String? label,
    bool? enabled,
  }) =>
      QuantityPreset(
        value: value ?? this.value,
        label: label ?? this.label,
        enabled: enabled ?? this.enabled,
      );
}
