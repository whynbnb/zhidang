import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../utils/quantity_presets.dart';
import 'tag_chips.dart';

final _currency = NumberFormat('#,##0.##');

class OfferTile extends StatelessWidget {
  const OfferTile({
    super.key,
    required this.offer,
    required this.unit,
    required this.isBest,
    required this.rank,
    required this.onEdit,
    this.onCounterTap,
  });

  final Offer offer;
  final String unit;
  final bool isBest;
  final int rank;
  final VoidCallback onEdit;
  final VoidCallback? onCounterTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = AppStrings.of(context);
    final qty = offer.quantityFor(unit) ?? 0;
    final unitPrice = offer.unitPriceFor(unit) ?? 0;
    final allMeasures = offer.measures
        .where((m) => m.quantity > 0)
        .map((m) => '${formatQuantityValue(m.quantity)}${m.unit}')
        .join(' · ');
    final counterEnabled = offer.counterMode.enabled;
    final isLog = offer.counterMode == OfferCounterMode.withLog;

    return Card(
      elevation: 0,
      color: isBest
          ? scheme.primaryContainer.withValues(alpha: 0.55)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isBest ? scheme.primary : scheme.outlineVariant,
          width: isBest ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor:
                  isBest ? scheme.primary : scheme.surfaceContainerHighest,
              foregroundColor:
                  isBest ? scheme.onPrimary : scheme.onSurfaceVariant,
              child: Text(
                isBest ? s.bestBadge : '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: isBest && !s.isZh ? 10 : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.brand,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '¥${_currency.format(offer.price)} / ${_currency.format(qty)}$unit'
                    '${offer.shop.isNotEmpty ? ' · ${offer.shop}' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  if (offer.measures.length > 1)
                    Text(
                      allMeasures,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.primary,
                          ),
                    ),
                  if (counterEnabled) ...[
                    const SizedBox(height: 4),
                    _CounterBadge(offer: offer),
                  ],
                  if (offer.tags.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    TagChipRow(tags: offer.tags, dense: true),
                  ],
                  if (offer.note.isNotEmpty)
                    Text(
                      offer.note,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '¥${_currency.format(unitPrice)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isBest ? scheme.primary : scheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  '/ $unit',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            if (counterEnabled)
              IconButton(
                tooltip: isLog ? s.counterViewLogs : s.counterModeCountLabel,
                onPressed: onCounterTap,
                icon: Icon(
                  isLog ? Icons.schedule : Icons.tag,
                  color: isLog ? scheme.tertiary : scheme.secondary,
                ),
              ),
            IconButton(
              tooltip: s.edit,
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterBadge extends StatelessWidget {
  const _CounterBadge({required this.offer});

  final Offer offer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = AppStrings.of(context);
    final isLog = offer.counterMode == OfferCounterMode.withLog;
    final bg = isLog
        ? scheme.tertiaryContainer.withValues(alpha: 0.85)
        : scheme.secondaryContainer.withValues(alpha: 0.85);
    final fg = isLog ? scheme.onTertiaryContainer : scheme.onSecondaryContainer;
    final icon = isLog ? Icons.schedule : Icons.tag;
    final label = isLog
        ? s.counterLogEntries(offer.displayCount)
        : '${offer.displayCount}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
