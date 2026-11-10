import 'package:flutter/material.dart';

/// A title/brand label with a note hint icon. Hovering or long-pressing the
/// whole label reveals the note, so the hit target is not just the small icon.
class NoteHintLabel extends StatelessWidget {
  const NoteHintLabel({
    super.key,
    required this.note,
    required this.label,
    this.style,
    this.maxLines = 1,
    this.iconSize = 16,
  });

  final String note;
  final String label;
  final TextStyle? style;
  final int maxLines;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: note,
      triggerMode: TooltipTriggerMode.longPress,
      showDuration: const Duration(seconds: 6),
      constraints: const BoxConstraints(maxWidth: 280),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.info_outline,
            size: iconSize,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
