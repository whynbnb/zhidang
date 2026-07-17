import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/comparison_group.dart';

class ComparisonStore extends ChangeNotifier {
  ComparisonStore._();

  static final ComparisonStore instance = ComparisonStore._();

  static const _key = 'zhidang_comparisons';

  List<ComparisonGroup> _groups = [];
  bool _ready = false;

  List<ComparisonGroup> get groups => List.unmodifiable(_groups);
  bool get ready => _ready;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      _groups = [];
    } else {
      final list = jsonDecode(raw) as List<dynamic>;
      _groups = list
          .map((e) => ComparisonGroup.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_groups.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  Future<ComparisonGroup> add(ComparisonGroup group) async {
    final next = group.copyWith(
      name: group.name.trim(),
      productIds: group.productIds,
      note: group.note.trim(),
      preferredUnit: group.preferredUnit.trim(),
    );
    _groups = [next, ..._groups.where((g) => g.id != next.id)]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    notifyListeners();
    await _persist();
    return next;
  }

  Future<ComparisonGroup> update(ComparisonGroup group) async {
    final updated = group.copyWith(
      name: group.name.trim(),
      productIds: group.productIds,
      note: group.note.trim(),
      preferredUnit: group.preferredUnit.trim(),
    );
    _groups = _groups
        .map((g) => g.id == updated.id ? updated : g)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    notifyListeners();
    await _persist();
    return updated;
  }

  Future<void> remove(String id) async {
    _groups = _groups.where((g) => g.id != id).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> replaceAll(List<ComparisonGroup> list) async {
    _groups = [...list]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _ready = true;
    notifyListeners();
    await _persist();
  }

  Future<void> clear() => replaceAll(const []);

  /// Drop product ids that no longer exist.
  Future<void> pruneMissingProducts(Set<String> validProductIds) async {
    var changed = false;
    final next = <ComparisonGroup>[];
    for (final g in _groups) {
      final ids =
          g.productIds.where(validProductIds.contains).toList(growable: false);
      if (ids.length != g.productIds.length) {
        changed = true;
        next.add(g.copyWith(productIds: ids));
      } else {
        next.add(g);
      }
    }
    if (!changed) return;
    _groups = next..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    notifyListeners();
    await _persist();
  }
}
