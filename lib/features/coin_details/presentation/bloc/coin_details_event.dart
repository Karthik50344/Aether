import 'package:equatable/equatable.dart';

import '../../domain/entities/chart_indicator.dart';
import '../../domain/entities/chart_period.dart';

sealed class CoinDetailsEvent extends Equatable {
  const CoinDetailsEvent();
  @override
  List<Object?> get props => const <Object?>[];
}

final class CoinDetailsStarted extends CoinDetailsEvent {
  const CoinDetailsStarted();
}

/// Reloads everything (pull-to-refresh, auto-refresh, any "Retry").
final class CoinDetailsRefreshed extends CoinDetailsEvent {
  const CoinDetailsRefreshed();
}

final class ChartPeriodSelected extends CoinDetailsEvent {
  const ChartPeriodSelected(this.period);
  final ChartPeriod period;
  @override
  List<Object?> get props => <Object?>[period];
}

final class ChartIndicatorToggled extends CoinDetailsEvent {
  const ChartIndicatorToggled(this.indicator);
  final ChartIndicator indicator;
  @override
  List<Object?> get props => <Object?>[indicator];
}

final class WatchlistToggled extends CoinDetailsEvent {
  const WatchlistToggled();
}
