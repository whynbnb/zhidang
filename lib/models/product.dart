import 'package:uuid/uuid.dart';

const _uuid = Uuid();

String normalizeUnit(String? unit, {String fallback = 'g'}) {
  final value = unit?.trim() ?? '';
  return value.isEmpty ? fallback : value;
}

/// 1 [fromUnit] = [factor] [toUnit]
class UnitRelation {
  UnitRelation({
    String? id,
    required String fromUnit,
    required String toUnit,
    required this.factor,
  })  : id = id ?? _uuid.v4(),
        fromUnit = normalizeUnit(fromUnit),
        toUnit = normalizeUnit(toUnit);

  final String id;
  final String fromUnit;
  final String toUnit;
  final double factor;

  String get label => '1 $fromUnit = ${_fmt(factor)} $toUnit';

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromUnit': fromUnit,
        'toUnit': toUnit,
        'factor': factor,
      };

  factory UnitRelation.fromJson(Map<String, dynamic> json) => UnitRelation(
        id: json['id'] as String?,
        fromUnit: normalizeUnit(json['fromUnit'] as String?),
        toUnit: normalizeUnit(json['toUnit'] as String?),
        factor: (json['factor'] as num?)?.toDouble() ?? 1,
      );

  UnitRelation copyWith({
    String? fromUnit,
    String? toUnit,
    double? factor,
  }) =>
      UnitRelation(
        id: id,
        fromUnit: fromUnit ?? this.fromUnit,
        toUnit: toUnit ?? this.toUnit,
        factor: factor ?? this.factor,
      );

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    final text = v.toStringAsFixed(4);
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }
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

enum OfferCounterMode {
  none,
  countOnly,
  withLog;

  static OfferCounterMode fromJson(Object? raw) {
    switch (raw?.toString()) {
      case 'countOnly':
        return OfferCounterMode.countOnly;
      case 'withLog':
        return OfferCounterMode.withLog;
      default:
        return OfferCounterMode.none;
    }
  }

  String toJson() => name;

  bool get enabled => this != OfferCounterMode.none;
}

class OfferCounterLog {
  OfferCounterLog({
    String? id,
    DateTime? at,
    this.note = '',
  })  : id = id ?? _uuid.v4(),
        at = at ?? DateTime.now();

  final String id;
  final DateTime at;
  final String note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'at': at.toIso8601String(),
        'note': note,
      };

  factory OfferCounterLog.fromJson(Map<String, dynamic> json) =>
      OfferCounterLog(
        id: json['id'] as String?,
        at: json['at'] != null
            ? DateTime.tryParse(json['at'] as String)
            : null,
        note: json['note'] as String? ?? '',
      );

  OfferCounterLog copyWith({String? note, DateTime? at}) => OfferCounterLog(
        id: id,
        at: at ?? this.at,
        note: note ?? this.note,
      );
}

class Offer {
  Offer({
    String? id,
    required this.brand,
    required this.price,
    List<OfferMeasure>? measures,
    List<UnitRelation>? relations,
    List<String>? tags,
    this.counterMode = OfferCounterMode.none,
    int counterValue = 0,
    List<OfferCounterLog>? counterLogs,
    String? unit,
    double? quantity,
    this.shop = '',
    this.note = '',
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        measures = _normalizeMeasures(measures, unit: unit, quantity: quantity),
        relations = List<UnitRelation>.from(relations ?? const []),
        tags = _normalizeTags(tags),
        counterValue = counterValue < 0 ? 0 : counterValue,
        counterLogs = List<OfferCounterLog>.from(counterLogs ?? const []),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String brand;
  double price;
  List<OfferMeasure> measures;
  /// Per-offer conversion, e.g. brand A: 1 pack = 200 sheets.
  List<UnitRelation> relations;
  List<String> tags;
  OfferCounterMode counterMode;
  int counterValue;
  List<OfferCounterLog> counterLogs;
  String shop;
  String note;
  DateTime updatedAt;

  int get displayCount {
    switch (counterMode) {
      case OfferCounterMode.none:
        return 0;
      case OfferCounterMode.countOnly:
        return counterValue;
      case OfferCounterMode.withLog:
        return counterLogs.length;
    }
  }

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
        'relations': relations.map((e) => e.toJson()).toList(),
        'tags': tags,
        'counterMode': counterMode.toJson(),
        'counterValue': counterValue,
        'counterLogs': counterLogs.map((e) => e.toJson()).toList(),
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
    final relations = (json['relations'] as List<dynamic>?)
            ?.map((e) => UnitRelation.fromJson(e as Map<String, dynamic>))
            .where((r) => r.factor > 0 && r.fromUnit != r.toUnit)
            .toList() ??
        <UnitRelation>[];
    final logs = (json['counterLogs'] as List<dynamic>?)
            ?.map((e) => OfferCounterLog.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <OfferCounterLog>[];

    return Offer(
      id: json['id'] as String?,
      brand: json['brand'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      measures: measures,
      relations: relations,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      counterMode: OfferCounterMode.fromJson(json['counterMode']),
      counterValue: (json['counterValue'] as num?)?.toInt() ?? 0,
      counterLogs: logs,
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
    List<UnitRelation>? relations,
    List<String>? tags,
    OfferCounterMode? counterMode,
    int? counterValue,
    List<OfferCounterLog>? counterLogs,
    String? shop,
    String? note,
  }) =>
      Offer(
        id: id,
        brand: brand ?? this.brand,
        price: price ?? this.price,
        measures: measures ?? this.measures,
        relations: relations ?? this.relations,
        tags: tags ?? this.tags,
        counterMode: counterMode ?? this.counterMode,
        counterValue: counterValue ?? this.counterValue,
        counterLogs: counterLogs ?? this.counterLogs,
        shop: shop ?? this.shop,
        note: note ?? this.note,
        updatedAt: DateTime.now(),
      );

  Offer incrementCount({String note = ''}) {
    switch (counterMode) {
      case OfferCounterMode.none:
        return this;
      case OfferCounterMode.countOnly:
        return copyWith(counterValue: counterValue + 1);
      case OfferCounterMode.withLog:
        return copyWith(
          counterLogs: [
            OfferCounterLog(note: note.trim()),
            ...counterLogs,
          ],
        );
    }
  }

  Offer decrementCount() {
    if (counterMode != OfferCounterMode.countOnly) return this;
    if (counterValue <= 0) return this;
    return copyWith(counterValue: counterValue - 1);
  }

  Offer resetCount() {
    switch (counterMode) {
      case OfferCounterMode.none:
        return this;
      case OfferCounterMode.countOnly:
        return copyWith(counterValue: 0);
      case OfferCounterMode.withLog:
        return copyWith(counterLogs: const []);
    }
  }

  Offer removeCounterLog(String logId) {
    return copyWith(
      counterLogs: counterLogs.where((e) => e.id != logId).toList(),
    );
  }

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
    List<UnitRelation>? relations,
    List<String>? tags,
    this.note = '',
    List<Offer>? offers,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        units = _normalizeUnits(units, unit),
        relations = List<UnitRelation>.from(relations ?? const []),
        tags = _normalizeTags(tags),
        offers = List<Offer>.from(offers ?? const []),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String name;
  List<String> units;
  /// Optional default template for new offers (not forced on existing offers).
  List<UnitRelation> relations;
  List<String> tags;
  String note;
  List<Offer> offers;
  DateTime updatedAt;

  /// List-card / default compare unit (always `units.first`).
  String get unit => units.isNotEmpty ? units.first : 'g';

  /// Alias for the unit shown on the product list.
  String get displayUnit => unit;

  List<String> get measureUnits {
    final result = <String>[...units];
    for (final r in relations) {
      if (!result.contains(r.fromUnit)) result.add(r.fromUnit);
      if (!result.contains(r.toUnit)) result.add(r.toUnit);
    }
    for (final offer in offers) {
      for (final m in offer.measures) {
        if (!result.contains(m.unit)) result.add(m.unit);
      }
      for (final r in offer.relations) {
        if (!result.contains(r.fromUnit)) result.add(r.fromUnit);
        if (!result.contains(r.toUnit)) result.add(r.toUnit);
      }
    }
    if (result.isEmpty) return ['g'];
    return result;
  }

  /// Expand quantities with product defaults + optional offer-specific relations.
  Map<String, double> expandQuantities(
    Map<String, double> seeded, {
    List<UnitRelation> extraRelations = const [],
  }) {
    return expandQuantitiesWithRelations(
      seeded,
      relations: [...relations, ...extraRelations],
    );
  }

  static Map<String, double> expandQuantitiesWithRelations(
    Map<String, double> seeded, {
    List<UnitRelation> relations = const [],
  }) {
    final values = <String, double>{
      for (final e in seeded.entries)
        if (e.value > 0) normalizeUnit(e.key): e.value,
    };
    if (values.isEmpty) return values;

    final edges = <String, Map<String, double>>{};
    void addEdge(String from, String to, double factor) {
      if (factor <= 0) return;
      edges.putIfAbsent(from, () => {});
      edges[from]![to] = factor;
      edges.putIfAbsent(to, () => {});
      edges[to]![from] = 1 / factor;
    }

    addEdge('kg', 'g', 1000);
    addEdge('L', 'ml', 1000);

    for (final r in relations) {
      if (r.factor > 0 && r.fromUnit != r.toUnit) {
        addEdge(r.fromUnit, r.toUnit, r.factor);
      }
    }

    final queue = [...values.keys];
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final currentQty = values[current];
      if (currentQty == null) continue;
      final next = edges[current];
      if (next == null) continue;
      next.forEach((unit, factor) {
        if (values.containsKey(unit)) return;
        values[unit] = currentQty * factor;
        queue.add(unit);
      });
    }
    return values;
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
        'relations': relations.map((e) => e.toJson()).toList(),
        'tags': tags,
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
    final relations = (json['relations'] as List<dynamic>?)
            ?.map((e) => UnitRelation.fromJson(e as Map<String, dynamic>))
            .where((r) => r.factor > 0 && r.fromUnit != r.toUnit)
            .toList() ??
        <UnitRelation>[];

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
      unit: fallback,
      relations: relations,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
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
    String? unit,
    List<UnitRelation>? relations,
    List<String>? tags,
    String? note,
    List<Offer>? offers,
  }) =>
      Product(
        id: id,
        name: name ?? this.name,
        units: units ?? this.units,
        unit: unit ?? this.unit,
        relations: relations ?? this.relations,
        tags: tags ?? this.tags,
        note: note ?? this.note,
        offers: offers ?? this.offers,
        updatedAt: DateTime.now(),
      );

  static List<String> _normalizeUnits(List<String>? units, String? preferred) {
    final result = <String>[];
    void add(String? value) {
      final v = normalizeUnit(value, fallback: '');
      if (v.isEmpty) return;
      if (!result.contains(v)) result.add(v);
    }

    // Preferred display unit first so list cards and default compare use it.
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

const maxTagsPerEntity = 5;

List<String> _normalizeTags(List<String>? tags) {
  if (tags == null || tags.isEmpty) return const [];
  final result = <String>[];
  final seen = <String>{};
  for (final raw in tags) {
    if (result.length >= maxTagsPerEntity) break;
    final name = raw.trim();
    if (name.isEmpty) continue;
    final key = name.toLowerCase();
    if (seen.contains(key)) continue;
    seen.add(key);
    result.add(name);
  }
  return result;
}
