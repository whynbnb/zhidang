import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Offer {
  Offer({
    String? id,
    required this.brand,
    required this.price,
    required this.quantity,
    this.shop = '',
    this.note = '',
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String brand;
  double price;
  double quantity;
  String shop;
  String note;
  DateTime updatedAt;

  double get unitPrice => quantity > 0 ? price / quantity : 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'price': price,
        'quantity': quantity,
        'shop': shop,
        'note': note,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Offer.fromJson(Map<String, dynamic> json) => Offer(
        id: json['id'] as String?,
        brand: json['brand'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        shop: json['shop'] as String? ?? '',
        note: json['note'] as String? ?? '',
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );

  Offer copyWith({
    String? brand,
    double? price,
    double? quantity,
    String? shop,
    String? note,
  }) =>
      Offer(
        id: id,
        brand: brand ?? this.brand,
        price: price ?? this.price,
        quantity: quantity ?? this.quantity,
        shop: shop ?? this.shop,
        note: note ?? this.note,
        updatedAt: DateTime.now(),
      );
}

class Product {
  Product({
    String? id,
    required this.name,
    this.unit = 'g',
    this.note = '',
    List<Offer>? offers,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        offers = offers ?? [],
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String name;
  String unit;
  String note;
  List<Offer> offers;
  DateTime updatedAt;

  Offer? get bestOffer {
    if (offers.isEmpty) return null;
    final sorted = [...offers]..sort((a, b) => a.unitPrice.compareTo(b.unitPrice));
    return sorted.first;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'unit': unit,
        'note': note,
        'offers': offers.map((e) => e.toJson()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String?,
        name: json['name'] as String? ?? '',
        unit: json['unit'] as String? ?? 'g',
        note: json['note'] as String? ?? '',
        offers: (json['offers'] as List<dynamic>?)
                ?.map((e) => Offer.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );

  Product copyWith({
    String? name,
    String? unit,
    String? note,
    List<Offer>? offers,
  }) =>
      Product(
        id: id,
        name: name ?? this.name,
        unit: unit ?? this.unit,
        note: note ?? this.note,
        offers: offers ?? this.offers,
        updatedAt: DateTime.now(),
      );
}

const unitOptions = ['g', 'kg', 'ml', 'L', '个', '包', '盒', '瓶', '袋', '卷'];
