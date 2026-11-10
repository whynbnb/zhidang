import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

/// Asks the user whether unsaved edits should be discarded.
Future<bool> confirmDiscardChanges(BuildContext context) async {
  final s = AppStrings.of(context);
  final discard = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(s.discardChangesTitle),
      content: Text(s.discardChangesBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(s.keepEditing),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(s.discardChanges),
        ),
      ],
    ),
  );
  return discard ?? false;
}
