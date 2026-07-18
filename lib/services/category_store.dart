import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import '../models/product_category.dart';
import 'data_revision.dart';
import 'storage_service.dart';

class CategoryStore extends ChangeNotifier {
  CategoryStore._();

  static final CategoryStore instance = CategoryStore._();

  static const _key = 'zhidang_categories';

  final _storage = StorageService();
  List<ProductCategory> _categories = [];
  bool _ready = false;

  List<ProductCategory> get categories => List.unmodifiable(_categories);
  bool get ready => _ready;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      _categories = [];
    } else {
      final list = jsonDecode(raw) as List<dynamic>;
      _categories = list
          .map((e) => ProductCategory.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_categories.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  ProductCategory? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  ProductCategory? findByName(String name) {
    final key = name.trim().toLowerCase();
    if (key.isEmpty) return null;
    for (final c in _categories) {
      if (c.name.trim().toLowerCase() == key) return c;
    }
    return null;
  }

  Future<ProductCategory> add({
    required String name,
    required List<String> units,
    String note = '',
  }) async {
    final trimmed = name.trim();
    final existing = findByName(trimmed);
    if (existing != null) {
      return update(
        existing.copyWith(
          units: units,
          note: note.trim().isNotEmpty ? note.trim() : existing.note,
        ),
      );
    }
    final category = ProductCategory(
      name: trimmed,
      units: units,
      note: note.trim(),
    );
    _categories = [..._categories, category]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    notifyListeners();
    await _persist();
    return category;
  }

  Future<ProductCategory> update(ProductCategory category) async {
    final previous = byId(category.id);
    final updated = category.copyWith(
      name: category.name.trim(),
      units: category.units,
      note: category.note.trim(),
    );
    _categories = _categories
        .map((e) => e.id == updated.id ? updated : e)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    notifyListeners();
    await _persist();
    if (previous != null && !_sameUnits(previous.units, updated.units)) {
      await _syncCategoryUnitChange(previous, updated);
    }
    return updated;
  }

  Future<void> remove(String id) async {
    final previous = byId(id);
    _categories = _categories.where((e) => e.id != id).toList();
    notifyListeners();
    await _persist();
    if (previous != null) {
      await _detachAllFromCategory(previous);
    }
  }

  Future<void> replaceAll(List<ProductCategory> list) async {
    _categories = [...list]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _ready = true;
    notifyListeners();
    await _persist();
  }

  Future<void> clear() => replaceAll(const []);

  bool _sameUnits(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (normalizeUnit(a[i]) != normalizeUnit(b[i])) return false;
    }
    return true;
  }

  Future<void> _syncCategoryUnitChange(
    ProductCategory previous,
    ProductCategory updated,
  ) async {
    final products = await _storage.loadProducts();
    var changed = false;
    final next = products.map((p) {
      if (p.categoryId != updated.id) return p;
      final adjusted = CategoryUnitSync.applyCategoryUnitsChange(
        p,
        previousUnits: previous.units,
        newUnits: updated.units,
      );
      if (!_productUnitsEqual(p, adjusted)) changed = true;
      return adjusted;
    }).toList();
    if (changed) {
      await _storage.saveProducts(next);
      DataRevision.bump();
    }
  }

  bool _productUnitsEqual(Product a, Product b) {
    if (a.units.length != b.units.length) return false;
    for (var i = 0; i < a.units.length; i++) {
      if (a.units[i] != b.units[i]) return false;
    }
    return a.displayUnit == b.displayUnit && a.categoryId == b.categoryId;
  }

  Future<void> _detachAllFromCategory(ProductCategory category) async {
    final products = await _storage.loadProducts();
    var changed = false;
    final next = products.map((p) {
      if (p.categoryId != category.id) return p;
      changed = true;
      return CategoryUnitSync.leaveCategory(p, categoryUnits: category.units);
    }).toList();
    if (changed) {
      await _storage.saveProducts(next);
      DataRevision.bump();
    }
  }
}

/// Unit inheritance when joining / leaving a category.
class CategoryUnitSync {
  CategoryUnitSync._();

  static bool hasUnitData(Product product, String unit) {
    final u = normalizeUnit(unit, fallback: '');
    if (u.isEmpty) return false;
    for (final o in product.offers) {
      final q = o.quantityFor(u);
      if (q != null && q > 0) return true;
      for (final r in o.relations) {
        if (r.fromUnit == u || r.toUnit == u) return true;
      }
    }
    for (final r in product.relations) {
      if (r.fromUnit == u || r.toUnit == u) return true;
    }
    return false;
  }

  /// Ensure all category units are present on the product.
  static Product joinCategory(
    Product product, {
    required List<String> categoryUnits,
  }) {
    final units = [...product.units];
    for (final raw in categoryUnits) {
      final unit = normalizeUnit(raw);
      if (!units.contains(unit)) units.add(unit);
    }
    return product.copyWith(
      categoryId: product.categoryId,
      units: units,
      unit: product.displayUnit,
    );
  }

  /// Clear category; drop inherited units when unused, else keep.
  static Product leaveCategory(
    Product product, {
    required List<String> categoryUnits,
  }) {
    var units = [...product.units];
    for (final raw in categoryUnits) {
      final unit = normalizeUnit(raw);
      final keepUnit = hasUnitData(product, unit);
      if (!keepUnit && units.contains(unit) && units.length > 1) {
        units = units.where((u) => u != unit).toList();
      }
    }
    if (units.isEmpty) units = ['g'];
    final display = units.contains(product.displayUnit)
        ? product.displayUnit
        : units.first;
    return product.copyWith(
      categoryId: '',
      clearCategory: true,
      units: units,
      unit: display,
    );
  }

  static Product applyCategoryUnitsChange(
    Product product, {
    required List<String> previousUnits,
    required List<String> newUnits,
  }) {
    final prev = previousUnits.map(normalizeUnit).toSet();
    final next = newUnits.map(normalizeUnit).toSet();
    var units = [...product.units];
    for (final u in next) {
      if (!units.contains(u)) units.add(u);
    }
    for (final u in prev) {
      if (next.contains(u)) continue;
      if (units.contains(u) && units.length > 1 && !hasUnitData(product, u)) {
        units = units.where((x) => x != u).toList();
      }
    }
    if (units.isEmpty) units = ['g'];
    final display = units.contains(product.displayUnit)
        ? product.displayUnit
        : units.first;
    return product.copyWith(units: units, unit: display);
  }

  /// Resolve product when category assignment changes in the form.
  static Product applyAssignment(
    Product product, {
    String? previousCategoryId,
    String? newCategoryId,
    required ProductCategory? Function(String? id) resolve,
  }) {
    final prevId = (previousCategoryId ?? '').trim();
    final nextId = (newCategoryId ?? '').trim();
    if (prevId == nextId) {
      if (nextId.isEmpty) return product.copyWith(clearCategory: true);
      final cat = resolve(nextId);
      if (cat == null) return product.copyWith(clearCategory: true);
      return joinCategory(
        product.copyWith(categoryId: cat.id),
        categoryUnits: cat.units,
      );
    }

    var result = product;
    if (prevId.isNotEmpty) {
      final prev = resolve(prevId);
      if (prev != null) {
        result = leaveCategory(result, categoryUnits: prev.units);
      } else {
        result = result.copyWith(clearCategory: true);
      }
    }
    if (nextId.isNotEmpty) {
      final next = resolve(nextId);
      if (next != null) {
        result = joinCategory(
          result.copyWith(categoryId: next.id),
          categoryUnits: next.units,
        );
      }
    }
    return result;
  }
}
