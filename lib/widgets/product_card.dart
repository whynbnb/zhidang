import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/product.dart';
import 'tag_chips.dart';

final _currency = NumberFormat('#,##0.##');

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.selected,
    required this.onTap,
    this.onLongPress,
    this.compact = false,
  });

  final Product product;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// Dense row without a large card.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = AppStrings.of(context);
    final primaryUnit = product.displayUnit;
    final best = product.bestOfferFor(primaryUnit) ?? product.bestOffer;
    final bestUnit = best == null
        ? primaryUnit
        : (best.hasUnit(primaryUnit) ? primaryUnit : best.unit);
    final bestPrice = best?.unitPriceFor(bestUnit);
    final units = product.measureUnits;

    if (compact) {
      final meta = <String>[
        units.length > 1
            ? s.dimensionCount(units.length)
            : s.unitLabel(primaryUnit),
        if (product.offers.isNotEmpty) s.brandCount(product.offers.length),
      ].join(' · ');

      return Material(
        color: selected
            ? scheme.primaryContainer.withValues(alpha: 0.35)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 9, 12, 9),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                      ),
                      if (product.tags.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        TagChipRow(tags: product.tags, dense: true),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 170),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (best != null) ...[
                        Text(
                          '¥${_currency.format(bestPrice ?? 0)} / $bestUnit',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      const SizedBox(height: 2),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: Text(
                          best.brand,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      ),
                    ] else
                      Text(
                        s.noOfferHintCard,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: selected ? 2 : 0,
      color: selected ? scheme.primaryContainer.withValues(alpha: 0.45) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (product.offers.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        s.brandCount(product.offers.length),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSecondaryContainer,
                            ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                units.length > 1
                    ? s.dimensionCount(units.length)
                    : s.unitLabel(primaryUnit),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              if (best != null) ...[
                Text(
                  s.bestBrand(best.brand),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '¥${_currency.format(bestPrice ?? 0)} / $bestUnit',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ] else
                Text(
                  s.noOfferHintCard,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              if (product.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                TagChipRow(tags: product.tags, dense: true),
              ],
              if (product.note.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  product.note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
