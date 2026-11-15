import 'package:flutter/material.dart';

import '../../../../core/formatters/formatters.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/entities/recent_trade.dart';

/// Newest public trades. Side comes from `isBuyerMaker`: a taker BUY is a
/// trade where the buyer was the aggressor (`isBuyerMaker == false`).
class RecentTradesTable extends StatelessWidget {
  const RecentTradesTable({
    required this.trades,
    required this.baseAsset,
    required this.quoteAsset,
    this.maxRows = 8,
    super.key,
  });

  final List<RecentTrade> trades;
  final String baseAsset;
  final String quoteAsset;
  final int maxRows;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final List<RecentTrade> rows =
        trades.length > maxRows ? trades.sublist(0, maxRows) : trades;
    TextStyle head() =>
        AppTypography.label.copyWith(color: p.textSecondary, fontSize: 10);

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadii.cardRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          Container(
            color: p.surfaceHigh.withAlpha(120),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: <Widget>[
                Expanded(flex: 3, child: Text('Time (UTC)', style: head())),
                Expanded(flex: 2, child: Center(child: Text('Side', style: head()))),
                Expanded(
                  flex: 3,
                  child: Text('Size ($baseAsset)',
                      textAlign: TextAlign.right, style: head()),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Price ($quoteAsset)',
                      textAlign: TextAlign.right, style: head()),
                ),
              ],
            ),
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('No recent trades.',
                  style: AppTypography.label.copyWith(color: p.textSecondary)),
            )
          else
            for (int i = 0; i < rows.length; i++)
              _Row(trade: rows[i], shaded: i.isOdd),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.trade, required this.shaded});

  final RecentTrade trade;
  final bool shaded;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final bool buy = trade.isTakerBuy;
    final Color c = buy ? p.positive : p.negative;
    return Container(
      color: shaded ? p.surfaceHigh.withAlpha(60) : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Text(
              Fmt.clockSeconds(trade.time),
              style: AppTypography.label.copyWith(color: p.textSecondary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: buy ? p.positiveBg : p.negativeBg,
                  borderRadius: AppRadii.badgeRadius,
                ),
                child: Text(
                  buy ? 'BUY' : 'SELL',
                  style: AppTypography.labelStrong.copyWith(color: c, fontSize: 10),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              trade.quantity.toStringAsFixed(trade.quantity >= 100 ? 2 : 4),
              textAlign: TextAlign.right,
              style: AppTypography.label.copyWith(color: p.textPrimary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              Fmt.price(trade.price),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label.copyWith(color: c),
            ),
          ),
        ],
      ),
    );
  }
}
