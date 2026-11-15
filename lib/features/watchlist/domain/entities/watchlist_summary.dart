import 'package:equatable/equatable.dart';

import '../../../../shared/domain/entities/trading_pair.dart';

/// Figures over the SAVED pairs only (24h, Binance Spot).
///  * [averageReturn] - simple mean of the pairs' 24h % change (not weighted,
///    not a portfolio return: the app holds no positions).
///  * [advancing]/[declining] - pairs with change > 0 / < 0.
class WatchlistSummary extends Equatable {
  const WatchlistSummary({
    required this.count,
    required this.averageReturn,
    required this.advancing,
    required this.declining,
  });

  const WatchlistSummary.empty()
      : count = 0,
        averageReturn = 0,
        advancing = 0,
        declining = 0;

  final int count;
  final double averageReturn;
  final int advancing;
  final int declining;

  @override
  List<Object?> get props => <Object?>[count, averageReturn, advancing, declining];
}

class ComputeWatchlistSummary {
  const ComputeWatchlistSummary();

  WatchlistSummary call(List<TradingPair> saved) {
    if (saved.isEmpty) return const WatchlistSummary.empty();
    double sum = 0;
    int up = 0, down = 0;
    for (final TradingPair p in saved) {
      sum += p.priceChangePercent;
      if (p.priceChangePercent > 0) up++;
      if (p.priceChangePercent < 0) down++;
    }
    return WatchlistSummary(
      count: saved.length,
      averageReturn: sum / saved.length,
      advancing: up,
      declining: down,
    );
  }
}
