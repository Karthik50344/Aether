import 'package:equatable/equatable.dart';

import '../../../explore/domain/entities/explore_query.dart';
import 'market_state.dart';

sealed class MarketEvent extends Equatable {
  const MarketEvent();
  @override
  List<Object?> get props => const <Object?>[];
}

/// First load (shows the loading state).
final class MarketStarted extends MarketEvent {
  const MarketStarted();
}

/// Pull-to-refresh / auto-refresh. Keeps the old data on screen on failure.
final class MarketRefreshed extends MarketEvent {
  const MarketRefreshed({this.forceNetwork = true});
  final bool forceNetwork;
  @override
  List<Object?> get props => <Object?>[forceNetwork];
}

/// Retry after a failed first load.
final class MarketRetryRequested extends MarketEvent {
  const MarketRetryRequested();
}

final class MarketQuoteSelected extends MarketEvent {
  const MarketQuoteSelected(this.quote);
  final String quote;
  @override
  List<Object?> get props => <Object?>[quote];
}

final class MarketTrendSelected extends MarketEvent {
  const MarketTrendSelected(this.trend);
  final TrendKind trend;
  @override
  List<Object?> get props => <Object?>[trend];
}

final class MarketSectorSelected extends MarketEvent {
  const MarketSectorSelected(this.sectorId);
  final String sectorId;
  @override
  List<Object?> get props => <Object?>[sectorId];
}

final class MarketSortChanged extends MarketEvent {
  const MarketSortChanged(this.field, {required this.ascending});
  final SortField field;
  final bool ascending;
  @override
  List<Object?> get props => <Object?>[field, ascending];
}

/// Internal: sparkline data arrived.
final class MarketSparklinesArrived extends MarketEvent {
  const MarketSparklinesArrived(this.series);
  final Map<String, List<double>> series;
  @override
  List<Object?> get props => <Object?>[series];
}
