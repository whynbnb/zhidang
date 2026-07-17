import 'package:flutter/foundation.dart';

/// Bumped after product data changes (save/import/clear) so tabs can reload.
class DataRevision {
  DataRevision._();

  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);

  static void bump() {
    notifier.value++;
  }
}
