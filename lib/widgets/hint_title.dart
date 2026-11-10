import 'package:flutter/material.dart';

/// Section title with a hint that appears on hover or long press.
class HintTitle extends StatelessWidget {
  const HintTitle({
    super.key,
    required this.title,
    required this.hint,
  });

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Tooltip(
        message: hint,
        triggerMode: TooltipTriggerMode.longPress,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(width: 5),
            Icon(
              Icons.info_outline,
              size: 15,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
