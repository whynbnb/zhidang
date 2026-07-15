import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/product.dart';

final _currency = NumberFormat('#,##0.##');

class OfferTile extends StatelessWidget {
  const OfferTile({
    super.key,
    required this.offer,
    required this.unit,
    required this.isBest,
    required this.rank,
    required this.onEdit,
    required this.onDelete,
  });

  final Offer offer;
  final String unit;
  final bool isBest;
  final int rank;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor:
                  isBest ? scheme.primary : scheme.surfaceContainerHighest,
              foregroundColor:
                  isBest ? scheme.onPrimary : scheme.onSurfaceVariant,
              child: Text(
                isBest ? '优' : '$rank',
                style: const TextStyle(fontWeight: FontWeight.w700),
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
                    '¥${_currency.format(offer.price)} / ${_currency.format(offer.quantity)}$unit'
                    '${offer.shop.isNotEmpty ? ' · ${offer.shop}' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
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
                  '¥${_currency.format(offer.unitPrice)}',
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
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('编辑')),
                PopupMenuItem(value: 'delete', child: Text('删除')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
