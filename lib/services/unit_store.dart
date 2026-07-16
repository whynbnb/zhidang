import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/custom_unit.dart';

/// Built-in unit presets. Seeded into the store when empty / on reset.
const defaultUnitNamesZh = [
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
  '张',
  '片',
];

const defaultUnitNamesEn = [
  'g',
  'kg',
  'ml',
  'L',
  'pc',
  'pack',
  'box',
  'bottle',
  'bag',
  'roll',
  'sheet',
];

class UnitStore extends ChangeNotifier {
  UnitStore._();

  static final UnitStore instance = UnitStore._();

  static const _key = 'zhidang_units';
  static const _legacyKey = 'zhidang_custom_units';

  List<CustomUnit> _units = [];
  bool _ready = false;

  List<CustomUnit> get units => List.unmodifiable(_units);
  bool get ready => _ready;

  /// Names in store order (default seed order, then user-added).
  List<String> get names =>
      _units.map((e) => e.name).where((e) => e.isNotEmpty).toList();

  static List<String> defaultNamesForLocale(Locale locale) {
    return locale.languageCode == 'en'
        ? List<String>.from(defaultUnitNamesEn)
        : List<String>.from(defaultUnitNamesZh);
  }

  Future<void> load({Locale? locale}) async {
    final prefs = await SharedPreferences.getInstance();
    var raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      // Migrate previous custom-only list if present.
      raw = prefs.getString(_legacyKey);
    }
    if (raw == null || raw.isEmpty) {
      await _seedDefaults(locale ?? const Locale('zh'));
      return;
    }
    final list = jsonDecode(raw) as List<dynamic>;
    _units = list
        .map((e) => CustomUnit.fromJson(e as Map<String, dynamic>))
        .toList();
    if (_units.isEmpty) {
      await _seedDefaults(locale ?? const Locale('zh'));
      return;
    }
    _ready = true;
    notifyListeners();
    // Persist under the new key after a legacy read.
    if (prefs.getString(_key) == null) {
      await _persist();
    }
  }

  Future<void> _seedDefaults(Locale locale) async {
    _units = [
      for (final name in defaultNamesForLocale(locale)) CustomUnit(name: name),
    ];
    _ready = true;
    notifyListeners();
    await _persist();
  }

  /// Replace all units with locale defaults.
  Future<void> resetToDefaults(Locale locale) async {
    await _seedDefaults(locale);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_units.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  Future<CustomUnit> add({required String name, String note = ''}) async {
    final trimmed = name.trim();
    final existing = findByName(trimmed);
    if (existing != null) {
      if (note.trim().isNotEmpty && existing.note != note.trim()) {
        return update(existing.copyWith(note: note.trim()));
      }
      return existing;
    }
    final unit = CustomUnit(name: trimmed, note: note.trim());
    _units = [..._units, unit];
    notifyListeners();
    await _persist();
    return unit;
  }

  Future<CustomUnit> update(CustomUnit unit) async {
    final trimmed = unit.name.trim();
    final updated = unit.copyWith(name: trimmed, note: unit.note);
    _units = _units.map((e) => e.id == updated.id ? updated : e).toList();
    notifyListeners();
    await _persist();
    return updated;
  }

  Future<void> remove(String id) async {
    _units = _units.where((e) => e.id != id).toList();
    notifyListeners();
    await _persist();
  }

  CustomUnit? findByName(String name) {
    final key = name.trim().toLowerCase();
    if (key.isEmpty) return null;
    for (final u in _units) {
      if (u.name.trim().toLowerCase() == key) return u;
    }
    return null;
  }

  Future<void> ensureName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await add(name: trimmed);
  }
}
