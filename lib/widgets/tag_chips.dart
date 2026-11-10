import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../utils/tag_display.dart';
import 'hint_title.dart';

/// Free-text tags: add by typing, remove by tapping chip.
class TagPicker extends StatefulWidget {
  const TagPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.maxTags = maxTagsPerEntity,
  });

  static const maxTagsPerEntity = 5;

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final int maxTags;

  @override
  State<TagPicker> createState() => _TagPickerState();
}

class _TagPickerState extends State<TagPicker> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  bool get _atLimit => widget.selected.length >= widget.maxTags;

  void _addFromInput() {
    final name = _input.text.trim();
    if (name.isEmpty || _atLimit) return;
    final exists = widget.selected.any(
      (t) => t.toLowerCase() == name.toLowerCase(),
    );
    if (!exists) {
      widget.onChanged({...widget.selected, name});
    }
    _input.clear();
  }

  void _remove(String name) {
    final next = {...widget.selected}..remove(name);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final tags = widget.selected.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final atLimit = _atLimit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HintTitle(
          title: s.tags,
          hint: s.tagsAssignHint(widget.maxTags),
        ),
        const SizedBox(height: 10),
        if (tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final name in tags)
                InputChip(
                  label: Text(name),
                  onDeleted: () => _remove(name),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        if (atLimit)
          Text(
            s.tagsLimitReached(widget.maxTags),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          )
        else
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: s.addTag,
                    hintText: s.tagNameHint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addFromInput(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _addFromInput,
                icon: const Icon(Icons.add),
                tooltip: s.addTag,
              ),
            ],
          ),
      ],
    );
  }
}

class TagChipRow extends StatelessWidget {
  const TagChipRow({
    super.key,
    required this.tags,
    this.dense = false,
  });

  final List<String> tags;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        alignment: WrapAlignment.start,
        children: [
          for (final tag in tags)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: dense ? 7 : 8,
                vertical: dense ? 2 : 3,
              ),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                TagDisplay.ellipsize(tag),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                      fontSize: dense ? 11 : 12,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
