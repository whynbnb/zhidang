import 'package:flutter/foundation.dart';

/// Bumped after import/clear so HomePage can reload products.
class DataRevision {
  DataRevision._();

  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);

  static void bump() {
    notifier.value++;
  }
}
