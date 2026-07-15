import 'package:uuid/uuid.dart';

const _uuid = Uuid();

const unitOptions = [
  'g',
  'kg',
  'ml',
  'L',
  '个',
  '包',
  '盒',
  '瓶',
  '袋',
  '卷',
  'pc',
  'pack',
  'box',
  'bottle',
  'bag',
  'roll',
];

String normalizeUnit(String? unit, {String fallback = 'g'}) {
  final value = unit?.trim() ?? '';
  return value.isEmpty ? fallback : value;
}

class OfferMeasure {
  OfferMeasure({
    required String unit,
    required this.quantity,
  }) : unit = normalizeUnit(unit);

  final String unit;
  final double quantity;

  Map<String, dynamic> toJson() => {
        'unit': unit,
        'quantity': quantity,
      };

  factory OfferMeasure.fromJson(Map<String, dynamic> json) => OfferMeasure(
        unit: normalizeUnit(json['unit'] as String?),
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      );
}

class Offer {
  Offer({
    String? id,
    required this.brand,
    required this.price,
    List<OfferMeasure>? measures,
    String? unit,
    double? quantity,
    this.shop = '',
    this.note = '',
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        measures = _normalizeMeasures(measures, unit: unit, quantity: quantity),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String brand;
  double price;
  List<OfferMeasure> measures;
  String shop;
  String note;
  DateTime updatedAt;

  String get unit => measures.isNotEmpty ? measures.first.unit : 'g';

  double get quantity => measures.isNotEmpty ? measures.first.quantity : 0;

  double get unitPrice => unitPriceFor(unit) ?? 0;

  List<String> get measureUnits =>
      measures.map((m) => m.unit).where((u) => u.isNotEmpty).toList();

  bool hasUnit(String unit) {
    final target = normalizeUnit(unit);
    return measures.any((m) => m.unit == target && m.quantity > 0);
  }

  double? quantityFor(String unit) {
    final target = normalizeUnit(unit);
    for (final m in measures) {
      if (m.unit == target && m.quantity > 0) return m.quantity;
    }
    return null;
  }

  double? unitPriceFor(String unit) {
    final qty = quantityFor(unit);
    if (qty == null || qty <= 0) return null;
    return price / qty;
  }

  String measuresSummary([NumberFormatLike? format]) {
    final fmt = format ?? _defaultQty;
    return measures
        .where((m) => m.quantity > 0)
        .map((m) => '${fmt(m.quantity)}${m.unit}')
        .join(' · ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'price': price,
        'measures': measures.map((e) => e.toJson()).toList(),
        // Keep legacy fields for older builds / partial migrations.
        'unit': unit,
        'quantity': quantity,
        'shop': shop,
        'note': note,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Offer.fromJson(
    Map<String, dynamic> json, {
    String fallbackUnit = 'g',
  }) {
    final rawMeasures = json['measures'] as List<dynamic>?;
    List<OfferMeasure>? measures;
    if (rawMeasures != null && rawMeasures.isNotEmpty) {
      measures = rawMeasures
          .map((e) => OfferMeasure.fromJson(e as Map<String, dynamic>))
          .where((m) => m.quantity > 0)
          .toList();
    }

    return Offer(
      id: json['id'] as String?,
      brand: json['brand'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      measures: measures,
      unit: normalizeUnit(json['unit'] as String?, fallback: fallbackUnit),
      quantity: (json['quantity'] as num?)?.toDouble(),
      shop: json['shop'] as String? ?? '',
      note: json['note'] as String? ?? '',
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Offer copyWith({
    String? brand,
    double? price,
    List<OfferMeasure>? measures,
    String? shop,
    String? note,
  }) =>
      Offer(
        id: id,
        brand: brand ?? this.brand,
        price: price ?? this.price,
        measures: measures ?? this.measures,
        shop: shop ?? this.shop,
        note: note ?? this.note,
        updatedAt: DateTime.now(),
      );

  static List<OfferMeasure> _normalizeMeasures(
    List<OfferMeasure>? measures, {
    String? unit,
    double? quantity,
  }) {
    final result = <OfferMeasure>[];
    final seen = <String>{};

    void add(String? u, double? q) {
      final nu = normalizeUnit(u, fallback: '');
      if (nu.isEmpty || q == null || q <= 0) return;
      if (seen.contains(nu)) {
        final index = result.indexWhere((m) => m.unit == nu);
        if (index >= 0) {
          result[index] = OfferMeasure(unit: nu, quantity: q);
        }
        return;
      }
      seen.add(nu);
      result.add(OfferMeasure(unit: nu, quantity: q));
    }

    if (measures != null) {
      for (final m in measures) {
        add(m.unit, m.quantity);
      }
    }
    if (result.isEmpty) {
      add(unit, quantity ?? 0);
    }
    if (result.isEmpty) {
      result.add(OfferMeasure(unit: normalizeUnit(unit), quantity: 1));
    }
    return result;
  }
}

typedef NumberFormatLike = String Function(double value);

String _defaultQty(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  final text = value.toStringAsFixed(3);
  return text.replaceFirst(RegExp(r'\.?0+$'), '');
}

class Product {
  Product({
    String? id,
    required this.name,
    List<String>? units,
    String? unit,
    this.note = '',
    List<Offer>? offers,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        units = _normalizeUnits(units, unit),
        offers = List<Offer>.from(offers ?? const []),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String name;
  List<String> units;
  String note;
  List<Offer> offers;
  DateTime updatedAt;

  String get unit => units.isNotEmpty ? units.first : 'g';

  List<String> get measureUnits {
    final result = <String>[...units];
    for (final offer in offers) {
      for (final m in offer.measures) {
        if (!result.contains(m.unit)) result.add(m.unit);
      }
    }
    if (result.isEmpty) return ['g'];
    return result;
  }

  List<Offer> offersFor(String unit) {
    final target = normalizeUnit(unit, fallback: this.unit);
    return offers.where((o) => o.hasUnit(target)).toList();
  }

  Offer? bestOfferFor(String unit) {
    final list = offersFor(unit);
    if (list.isEmpty) return null;
    final target = normalizeUnit(unit, fallback: this.unit);
    final sorted = [...list]
      ..sort((a, b) {
        final pa = a.unitPriceFor(target) ?? double.infinity;
        final pb = b.unitPriceFor(target) ?? double.infinity;
        return pa.compareTo(pb);
      });
    return sorted.first;
  }

  Offer? get bestOffer => bestOfferFor(unit);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'units': units,
        'unit': unit,
        'note': note,
        'offers': offers.map((e) => e.toJson()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Product.fromJson(Map<String, dynamic> json) {
    final legacyUnit = normalizeUnit(json['unit'] as String?);
    final units = _normalizeUnits(
      (json['units'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      legacyUnit,
    );
    final fallback = units.first;

    final rawOffers = (json['offers'] as List<dynamic>?) ?? const [];
    final offers = rawOffers
        .map(
          (e) => Offer.fromJson(
            e as Map<String, dynamic>,
            fallbackUnit: fallback,
          ),
        )
        .toList();

    return Product(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      units: units,
      note: json['note'] as String? ?? '',
      offers: offers,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Product copyWith({
    String? name,
    List<String>? units,
    String? note,
    List<Offer>? offers,
  }) =>
      Product(
        id: id,
        name: name ?? this.name,
        units: units ?? this.units,
        note: note ?? this.note,
        offers: offers ?? this.offers,
        updatedAt: DateTime.now(),
      );

  static List<String> _normalizeUnits(List<String>? units, String? unit) {
    final result = <String>[];
    void add(String? value) {
      final v = normalizeUnit(value, fallback: '');
      if (v.isEmpty) return;
      if (!result.contains(v)) result.add(v);
    }

    if (units != null) {
      for (final u in units) {
        add(u);
      }
    }
    add(unit);
    if (result.isEmpty) result.add('g');
    return result;
  }
}
