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
    this.suggestions = const [],
    this.suggestionsLabel,
    this.maxTags = maxTagsPerEntity,
  });

  static const maxTagsPerEntity = 5;

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  /// Optional tags to offer as one-tap additions, e.g. tags already used by
  /// other products in the same category.
  final List<String> suggestions;

  /// Label above [suggestions]; defaults to the category tag hint.
  final String? suggestionsLabel;
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

  void _add(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _atLimit) return;
    final exists = widget.selected.any(
      (t) => t.toLowerCase() == trimmed.toLowerCase(),
    );
    if (!exists) {
      widget.onChanged({...widget.selected, trimmed});
    }
  }

  void _addFromInput() {
    _add(_input.text);
    _input.clear();
  }

  List<String> get _availableSuggestions {
    final selectedKeys = widget.selected
        .map((tag) => tag.trim().toLowerCase())
        .where((tag) => tag.isNotEmpty)
        .toSet();
    final seen = <String>{};
    final result = <String>[];
    for (final raw in widget.suggestions) {
      final name = raw.trim();
      final key = name.toLowerCase();
      if (name.isEmpty || selectedKeys.contains(key) || !seen.add(key)) {
        continue;
      }
      result.add(name);
    }
    return result;
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
    final suggestions = _availableSuggestions;

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
        if (!atLimit && suggestions.isNotEmpty) ...[
          Text(
            widget.suggestionsLabel ?? s.tagsInCategory,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final name in suggestions)
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: Text(name),
                  onPressed: () => _add(name),
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
    this.singleLine = false,
  });

  final List<String> tags;
  final bool dense;

  /// Scrolls horizontally instead of wrapping to another line.
  final bool singleLine;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    Widget chip(String tag) {
      return Container(
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
      );
    }

    if (singleLine) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < tags.length; i++) ...[
              chip(tags[i]),
              if (i != tags.length - 1) const SizedBox(width: 6),
            ],
          ],
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        alignment: WrapAlignment.start,
        children: [for (final tag in tags) chip(tag)],
      ),
    );
  }
}
