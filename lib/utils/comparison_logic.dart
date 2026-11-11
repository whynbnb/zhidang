import '../models/product.dart';
import '../services/unit_store.dart';

enum CompareViewMode {
  all,
  favorites,
  cheapest,
}

/// One ranked offer line in a cross-product comparison.
class ComparisonRow {
  const ComparisonRow({
    required this.product,
    required this.unit,
    this.offer,
  });

  final Product product;
  final String unit;
  final Offer? offer;

  double? get unitPrice =>
      offer == null ? null : product.unitPriceForOffer(offer!, unit);

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
    return UnitStore.instance.sortUnits(set);
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

  static int _byUnitPrice(ComparisonRow a, ComparisonRow b) {
    final pa = a.unitPrice;
    final pb = b.unitPrice;
    if (pa == null && pb == null) {
      final byName = a.product.name
          .toLowerCase()
          .compareTo(b.product.name.toLowerCase());
      if (byName != 0) return byName;
      return (a.offer?.brand ?? '')
          .toLowerCase()
          .compareTo((b.offer?.brand ?? '').toLowerCase());
    }
    if (pa == null) return 1;
    if (pb == null) return -1;
    final c = pa.compareTo(pb);
    if (c != 0) return c;
    final byName =
        a.product.name.toLowerCase().compareTo(b.product.name.toLowerCase());
    if (byName != 0) return byName;
    return (a.offer?.brand ?? '')
        .toLowerCase()
        .compareTo((b.offer?.brand ?? '').toLowerCase());
  }

  /// Build ranking rows for the session.
  ///
  /// - [CompareViewMode.all]: every offer that has [unit] (flat list)
  /// - [CompareViewMode.favorites]: every favorited offer with [unit]
  /// - [CompareViewMode.cheapest]: one cheapest offer per product
  static List<ComparisonRow> rank(
    List<Product> products, {
    required String unit,
    CompareViewMode mode = CompareViewMode.all,
  }) {
    final target = normalizeUnit(unit);
    final rows = <ComparisonRow>[];

    switch (mode) {
      case CompareViewMode.all:
        for (final p in products) {
          for (final o in p.offersFor(target)) {
            rows.add(ComparisonRow(product: p, unit: target, offer: o));
          }
        }
      case CompareViewMode.favorites:
        for (final p in products) {
          for (final o in p.favoriteOffersFor(target)) {
            rows.add(ComparisonRow(product: p, unit: target, offer: o));
          }
        }
      case CompareViewMode.cheapest:
        for (final p in products) {
          final best = p.bestOfferFor(target);
          rows.add(ComparisonRow(product: p, unit: target, offer: best));
        }
    }

    rows.sort(_byUnitPrice);
    return rows;
  }
}
