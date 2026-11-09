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
    this.onToggleFavorite,
    this.isPreferred = false,
  });

  final Offer offer;
  final String unit;
  final bool isBest;
  final int rank;
  final VoidCallback onEdit;
  final VoidCallback? onCounterTap;
  final VoidCallback? onToggleFavorite;
  final bool isPreferred;

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
    final highlight = isPreferred || isBest;
    final hasMeta = counterEnabled || offer.tags.isNotEmpty;

    final actions = _OfferActions(
      offer: offer,
      counterEnabled: counterEnabled,
      isLog: isLog,
      onToggleFavorite: onToggleFavorite,
      onCounterTap: onCounterTap,
      onEdit: onEdit,
    );

    return Card(
      elevation: 0,
      color: highlight
          ? scheme.primaryContainer.withValues(alpha: 0.55)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: highlight ? scheme.primary : scheme.outlineVariant,
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 6, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: highlight
                      ? scheme.primary
                      : scheme.surfaceContainerHighest,
                  foregroundColor: highlight
                      ? scheme.onPrimary
                      : scheme.onSurfaceVariant,
                  child: Text(
                    isPreferred && offer.favorite
                        ? s.favoriteBadge
                        : (isBest ? s.bestBadge : '$rank'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: isBest && !s.isZh ? 10 : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              offer.brand,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (offer.favorite)
                            Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: scheme.tertiary,
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '¥${_currency.format(offer.price)} / ${_currency.format(qty)}$unit'
                        '${offer.shop.isNotEmpty ? ' · ${offer.shop}' : ''}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      if (offer.measures.length > 1)
                        Text(
                          allMeasures,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: scheme.primary,
                                  ),
                        ),
                      if (offer.note.isNotEmpty)
                        Text(
                          offer.note,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '¥${_currency.format(unitPrice)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color:
                                highlight ? scheme.primary : scheme.onSurface,
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
              ],
            ),
            if (hasMeta) ...[
              const SizedBox(height: 6),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (counterEnabled) _CounterBadge(offer: offer),
                          if (counterEnabled && offer.tags.isNotEmpty)
                            const SizedBox(height: 6),
                          if (offer.tags.isNotEmpty)
                            TagChipRow(tags: offer.tags, dense: true),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    actions,
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OfferActions extends StatelessWidget {
  const _OfferActions({
    required this.offer,
    required this.counterEnabled,
    required this.isLog,
    required this.onEdit,
    this.onToggleFavorite,
    this.onCounterTap,
  });

  final Offer offer;
  final bool counterEnabled;
  final bool isLog;
  final VoidCallback onEdit;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onCounterTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = AppStrings.of(context);

    Widget btn({
      required String tooltip,
      required VoidCallback? onPressed,
      required IconData icon,
      Color? color,
    }) {
      return IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
        padding: const EdgeInsets.all(6),
        icon: Icon(icon, size: 22, color: color),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onToggleFavorite != null)
              btn(
                tooltip:
                    offer.favorite ? s.unfavoriteOffer : s.favoriteOffer,
                onPressed: onToggleFavorite,
                icon: offer.favorite ? Icons.star_rounded : Icons.star_outline,
                color: offer.favorite ? scheme.tertiary : null,
              ),
            if (counterEnabled)
              btn(
                tooltip:
                    isLog ? s.counterViewLogs : s.counterModeCountLabel,
                onPressed: onCounterTap,
                icon: isLog ? Icons.schedule : Icons.tag,
                color: isLog ? scheme.tertiary : scheme.secondary,
              ),
            btn(
              tooltip: s.edit,
              onPressed: onEdit,
              icon: Icons.edit_outlined,
            ),
          ],
        ),
      ],
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

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
