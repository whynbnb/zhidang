import '../models/product.dart';

/// One product’s best offer under a chosen unit for cross-product ranking.
class ComparisonRow {
  const ComparisonRow({
    required this.product,
    required this.unit,
    this.offer,
  });

  final Product product;
  final String unit;
  final Offer? offer;

  double? get unitPrice => offer?.unitPriceFor(unit);

  bool get hasPrice => unitPrice != null;
}

/// Shared helpers for fixed / temporary comparisons.
class ComparisonLogic {
  ComparisonLogic._();

  /// Units that appear on every product (intersection of measureUnits).
  static List<String> commonUnits(List<Product> products) {
    if (products.isEmpty) return const [];
    var set = products.first.measureUnits.toSet();
    for (var i = 1; i < products.length; i++) {
      set = set.intersection(products[i].measureUnits.toSet());
    }
    final list = set.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  /// Prefer [preferred] if still common; else first common; else first product unit.
  static String pickUnit(
    List<Product> products, {
    String preferred = '',
  }) {
    final common = commonUnits(products);
    final pref = preferred.trim();
    if (pref.isNotEmpty && common.contains(pref)) return pref;
    if (common.isNotEmpty) return common.first;
    if (products.isNotEmpty) return products.first.displayUnit;
    return 'g';
  }

  static List<ComparisonRow> rank(
    List<Product> products, {
    required String unit,
  }) {
    final rows = products
        .map(
          (p) => ComparisonRow(
            product: p,
            unit: unit,
            offer: p.bestOfferFor(unit),
          ),
        )
        .toList();
    rows.sort((a, b) {
      final pa = a.unitPrice;
      final pb = b.unitPrice;
      if (pa == null && pb == null) {
        return a.product.name.toLowerCase().compareTo(b.product.name.toLowerCase());
      }
      if (pa == null) return 1;
      if (pb == null) return -1;
      final c = pa.compareTo(pb);
      if (c != 0) return c;
      return a.product.name.toLowerCase().compareTo(b.product.name.toLowerCase());
    });
    return rows;
  }
}
