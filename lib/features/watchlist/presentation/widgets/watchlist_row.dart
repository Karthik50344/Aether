import 'package:flutter/material.dart';

import '../../../../core/formatters/formatters.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/entities/trading_pair.dart';
import '../../../../shared/widgets/coin_avatar.dart';

/// One saved pair. In edit mode it shows a remove button and a drag handle
/// (the handle comes from the parent ReorderableListView via [dragIndex]).
/// [pair] is null when the symbol is no longer active on Spot.
class WatchlistRow extends StatelessWidget {
  const WatchlistRow({
    required this.symbol,
    required this.pair,
    required this.editing,
    required this.onTap,
    required this.onRemove,
    this.dragIndex,
    super.key,
  });

  final String symbol;
  final TradingPair? pair;
  final bool editing;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final int? dragIndex;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final TradingPair? pr = pair;
    final Color changeColor =
        (pr?.isPositive ?? true) ? p.positive : p.negativeLight;
    return Material(
      color: p.surface,
      borderRadius: AppRadii.cardRadius,
      child: InkWell(
        borderRadius: AppRadii.cardRadius,
        onTap: editing ? null : onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 68),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: <Widget>[
                if (editing)
                  IconButton(
                    tooltip: 'Remove $symbol from watchlist',
                    onPressed: onRemove,
                    icon: Icon(Icons.remove_circle, color: p.negativeLight),
                  ),
                CoinAvatar(
                  baseAsset: pr?.baseAsset ?? symbol,
                  size: 40,
                  negative: !(pr?.isPositive ?? true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        pr?.displayName ?? symbol,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.symbol.copyWith(color: p.textPrimary),
                      ),
                      Text(
                        pr == null
                            ? 'Not available on Binance Spot'
                            : 'Vol ${Fmt.quoteAmount(pr.quoteVolume, pr.quoteAsset)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label.copyWith(color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (pr != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        Fmt.pricedIn(pr.lastPrice, pr.quoteAsset),
                        maxLines: 1,
                        style: AppTypography.price.copyWith(color: p.textPrimary),
                      ),
                      Text(
                        Fmt.percent(pr.priceChangePercent),
                        style: AppTypography.valueMedium
                            .copyWith(color: changeColor, fontSize: 12),
                      ),
                    ],
                  ),
                const SizedBox(width: 8),
                if (editing && dragIndex != null)
                  ReorderableDragStartListener(
                    index: dragIndex!,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.drag_handle, color: p.textSecondary),
                    ),
                  )
                else if (!editing)
                  IconButton(
                    tooltip: 'Remove $symbol from watchlist',
                    onPressed: onRemove,
                    icon: Icon(AppIcons.starFilled, color: p.primaryLight),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
