import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// One committed converter row. Kept in memory only: values survive page
/// navigation during this run and disappear when the app exits.
class QuickCalcEntry {
  QuickCalcEntry({
    String? id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.unit,
  }) : id = id ?? _uuid.v4();

  final String id;
  final String name;
  final double price;
  final double quantity;
  final String unit;
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

  final List<QuickCalcEntry> _entries = [];
  final QuickCalcDraft draft = QuickCalcDraft();

  List<QuickCalcEntry> get entries => List.unmodifiable(_entries);

  bool get hasData =>
      _entries.isNotEmpty ||
      draft.name.trim().isNotEmpty ||
      draft.price.trim().isNotEmpty ||
      draft.quantity.trim().isNotEmpty;

  QuickCalcEntry commit({
    required String name,
    required double price,
    required double quantity,
    required String unit,
  }) {
    final entry = QuickCalcEntry(
      name: name,
      price: price,
      quantity: quantity,
      unit: unit,
    );
    _entries.add(entry);
    draft.name = '';
    draft.price = '';
    draft.quantity = '';
    draft.unit = unit;
    notifyListeners();
    return entry;
  }

  void remove(String id) {
    _entries.removeWhere((entry) => entry.id == id);
    notifyListeners();
  }

  void clear() {
    if (_entries.isEmpty && !hasData) return;
    _entries.clear();
    draft.name = '';
    draft.price = '';
    draft.quantity = '';
    notifyListeners();
  }
}
