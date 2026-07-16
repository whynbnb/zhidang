import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/product.dart';

final _dateTime = DateFormat('yyyy-MM-dd HH:mm');

/// Counter sheet that auto-saves on every change via [onChanged].
Future<void> showOfferCounterSheet(
  BuildContext context, {
  required Offer offer,
  required ValueChanged<Offer> onChanged,
}) {
  if (!offer.counterMode.enabled) return Future.value();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _OfferCounterSheet(
      offer: offer,
      onChanged: onChanged,
    ),
  );
}

class _OfferCounterSheet extends StatefulWidget {
  const _OfferCounterSheet({
    required this.offer,
    required this.onChanged,
  });

  final Offer offer;
  final ValueChanged<Offer> onChanged;

  @override
  State<_OfferCounterSheet> createState() => _OfferCounterSheetState();
}

class _OfferCounterSheetState extends State<_OfferCounterSheet> {
  late Offer _offer;
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    _offer = widget.offer;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _commit(Offer next) {
    setState(() => _offer = next);
    widget.onChanged(next);
  }

  Future<void> _reset() async {
    final s = AppStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.counterReset),
        content: Text(s.counterResetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.counterReset),
          ),
        ],
      ),
    );
    if (ok == true) {
      _commit(_offer.resetCount());
    }
  }

  void _addCountOnly() => _commit(_offer.incrementCount());

  void _decCountOnly() => _commit(_offer.decrementCount());

  void _addLog() {
    final note = _note.text.trim();
    _commit(_offer.incrementCount(note: note));
    _note.clear();
  }

  void _deleteLog(String id) => _commit(_offer.removeCounterLog(id));

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isLog = _offer.counterMode == OfferCounterMode.withLog;
    final logs = _offer.counterLogs;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isLog ? Icons.schedule : Icons.tag,
                color: isLog ? scheme.tertiary : scheme.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _offer.brand,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      isLog ? s.counterModeLogLabel : s.counterModeCountLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: (isLog
                      ? scheme.tertiaryContainer
                      : scheme.secondaryContainer)
                  .withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '${_offer.displayCount}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isLog ? scheme.tertiary : scheme.secondary,
                      ),
                ),
                Text(
                  isLog
                      ? s.counterLogEntries(_offer.displayCount)
                      : s.counterTimes(_offer.displayCount),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: isLog
                            ? scheme.onTertiaryContainer
                            : scheme.onSecondaryContainer,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!isLog)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _offer.displayCount > 0 ? _decCountOnly : null,
                    icon: const Icon(Icons.remove),
                    label: Text(s.counterDecrement),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _addCountOnly,
                    icon: const Icon(Icons.add),
                    label: Text(s.counterIncrement),
                  ),
                ),
              ],
            )
          else ...[
            TextField(
              controller: _note,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: s.counterLogNoteOptional,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.schedule),
              ),
              onSubmitted: (_) => _addLog(),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: _addLog,
              icon: const Icon(Icons.add),
              label: Text(s.counterAddLog),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                s.counterLogs,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.35,
              ),
              child: logs.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          s.counterNoLogs,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: logs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return Material(
                          color: scheme.tertiaryContainer.withValues(
                            alpha: 0.35,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.schedule,
                              size: 18,
                              color: scheme.tertiary,
                            ),
                            title: Text(
                              _dateTime.format(log.at.toLocal()),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: log.note.isEmpty ? null : Text(log.note),
                            trailing: IconButton(
                              tooltip: s.counterDeleteLog,
                              onPressed: () => _deleteLog(log.id),
                              icon: const Icon(Icons.delete_outline, size: 20),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _offer.displayCount > 0 ? _reset : null,
              child: Text(s.counterReset),
            ),
          ),
        ],
      ),
    );
  }
}
