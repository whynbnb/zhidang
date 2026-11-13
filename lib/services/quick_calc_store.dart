import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// One committed converter row. Unpinned rows live for this run only; pinned
/// rows are persisted and restored on the next launch.
class QuickCalcEntry {
  QuickCalcEntry({
    String? id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.unit,
    this.pinned = false,
    this.fromSaved = false,
  }) : id = id ?? _uuid.v4();

  final String id;
  final String name;
  final double price;
  final double quantity;
  final String unit;
  bool pinned;

  /// True when the row was copied from a product offer that was already
  /// saved, rather than typed in by hand.
  final bool fromSaved;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'quantity': quantity,
        'unit': unit,
        'pinned': pinned,
        'fromSaved': fromSaved,
      };

  factory QuickCalcEntry.fromJson(Map<String, dynamic> json) => QuickCalcEntry(
        id: json['id'] as String?,
        name: json['name'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        unit: json['unit'] as String? ?? '',
        pinned: json['pinned'] as bool? ?? true,
        fromSaved: json['fromSaved'] as bool? ?? false,
      );
}

/// The single editable row at the bottom of the page.
class QuickCalcDraft {
  QuickCalcDraft({this.unit = ''});

  String name = '';
  String price = '';
  String quantity = '';
  String unit;
}

class QuickCalcStore extends ChangeNotifier {
  QuickCalcStore._();

  static final QuickCalcStore instance = QuickCalcStore._();

  static const _pinsKey = 'zhidang_quick_calc_pins';

  final List<QuickCalcEntry> _entries = [];
  final QuickCalcDraft draft = QuickCalcDraft();
  /// Chosen primary display unit per comparison group (weight / volume / count:x).
  final Map<String, String> primaryUnits = {};

  List<QuickCalcEntry> get entries => List.unmodifiable(_entries);

  bool get hasData =>
      _entries.isNotEmpty ||
      draft.name.trim().isNotEmpty ||
      draft.price.trim().isNotEmpty ||
      draft.quantity.trim().isNotEmpty;

  /// Restore pinned rows after an app launch.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pinsKey);
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final existing = _entries.map((entry) => entry.id).toSet();
      for (final item in list) {
        final entry = QuickCalcEntry.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
        if (entry.quantity <= 0 || entry.unit.isEmpty) continue;
        if (existing.add(entry.id)) {
          _entries.add(entry);
        }
      }
      notifyListeners();
    } catch (_) {
      // Ignore malformed pinned data and start with an empty list.
    }
  }

  QuickCalcEntry commit({
    required String name,
    required double price,
    required double quantity,
    required String unit,
    bool fromSaved = false,
  }) {
    final entry = QuickCalcEntry(
      name: name,
      price: price,
      quantity: quantity,
      unit: unit,
      fromSaved: fromSaved,
    );
    _entries.add(entry);
    draft.name = '';
    draft.price = '';
    draft.quantity = '';
    draft.unit = unit;
    notifyListeners();
    return entry;
  }

  Future<void> togglePin(String id) async {
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index < 0) return;
    _entries[index].pinned = !_entries[index].pinned;
    notifyListeners();
    await _persistPins();
  }

  Future<void> remove(String id) async {
    final before = _entries.length;
    _entries.removeWhere((entry) => entry.id == id);
    if (_entries.length == before) return;
    notifyListeners();
    await _persistPins();
  }

  Future<void> clear() async {
    _entries.clear();
    draft.name = '';
    draft.price = '';
    draft.quantity = '';
    primaryUnits.clear();
    notifyListeners();
    await _persistPins();
  }

  Future<void> _persistPins() async {
    final prefs = await SharedPreferences.getInstance();
    final pinned = _entries.where((entry) => entry.pinned).toList();
    if (pinned.isEmpty) {
      await prefs.remove(_pinsKey);
      return;
    }
    await prefs.setString(
      _pinsKey,
      jsonEncode(pinned.map((entry) => entry.toJson()).toList()),
    );
  }

  /// Test helper: drop the in-memory session while keeping persisted pins.
  @visibleForTesting
  void clearMemory() {
    _entries.clear();
    draft.name = '';
    draft.price = '';
    draft.quantity = '';
    primaryUnits.clear();
  }
}
