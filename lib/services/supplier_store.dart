import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/supplier.dart';

class SupplierStore extends ChangeNotifier {
  SupplierStore._();

  static final SupplierStore instance = SupplierStore._();

  static const _key = 'zhidang_suppliers';

  List<Supplier> _suppliers = [];
  bool _ready = false;

  List<Supplier> get suppliers => List.unmodifiable(_suppliers);
  bool get ready => _ready;

  List<String> get names =>
      _suppliers.map((e) => e.name).where((e) => e.isNotEmpty).toList();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      _suppliers = [];
    } else {
      final list = jsonDecode(raw) as List<dynamic>;
      _suppliers = list
          .map((e) => Supplier.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_suppliers.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  Future<Supplier> add({
    required String name,
    List<SupplierType> types = const [],
    String address = '',
    String note = '',
  }) async {
    final trimmed = name.trim();
    final existing = findByName(trimmed);
    if (existing != null) {
      // ensureName / quick create should not wipe richer fields.
      final nextNote =
          note.trim().isNotEmpty ? note.trim() : existing.note;
      final nextTypes = types.isNotEmpty ? types : existing.types;
      final nextAddress =
          address.trim().isNotEmpty ? address.trim() : existing.address;
      if (nextNote == existing.note &&
          nextTypes == existing.types &&
          nextAddress == existing.address) {
        return existing;
      }
      return update(
        existing.copyWith(
          types: nextTypes,
          address: nextAddress,
          note: nextNote,
        ),
      );
    }
    final supplier = Supplier(
      name: trimmed,
      types: types,
      address: address.trim(),
      note: note.trim(),
    );
    _suppliers = [..._suppliers, supplier]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    notifyListeners();
    await _persist();
    return supplier;
  }

  Future<Supplier> update(Supplier supplier) async {
    final trimmed = supplier.name.trim();
    final hasStore = supplier.types.contains(SupplierType.store);
    final updated = supplier.copyWith(
      name: trimmed,
      types: supplier.types,
      address: hasStore ? supplier.address.trim() : '',
      note: supplier.note.trim(),
    );
    _suppliers = _suppliers
        .map((e) => e.id == updated.id ? updated : e)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    notifyListeners();
    await _persist();
    return updated;
  }

  Future<void> remove(String id) async {
    _suppliers = _suppliers.where((e) => e.id != id).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> replaceAll(List<Supplier> list) async {
    _suppliers = [...list]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _ready = true;
    notifyListeners();
    await _persist();
  }

  Future<void> clear() => replaceAll(const []);

  Supplier? findByName(String name) {
    final key = name.trim().toLowerCase();
    if (key.isEmpty) return null;
    for (final s in _suppliers) {
      if (s.name.trim().toLowerCase() == key) return s;
    }
    return null;
  }

  Future<void> ensureName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await add(name: trimmed);
  }
}
