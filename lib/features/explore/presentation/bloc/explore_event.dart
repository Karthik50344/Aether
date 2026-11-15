import 'package:equatable/equatable.dart';

import '../../domain/entities/explore_query.dart';

sealed class ExploreEvent extends Equatable {
  const ExploreEvent();
  @override
  List<Object?> get props => const <Object?>[];
}

final class ExploreStarted extends ExploreEvent {
  const ExploreStarted();
}

final class ExploreRetryRequested extends ExploreEvent {
  const ExploreRetryRequested();
}

final class ExploreRefreshed extends ExploreEvent {
  const ExploreRefreshed();
}

/// Raw keystrokes; applied after a debounce.
final class ExploreSearchChanged extends ExploreEvent {
  const ExploreSearchChanged(this.text);
  final String text;
  @override
  List<Object?> get props => <Object?>[text];
}

/// Internal: the debounce elapsed (or the field was cleared).
final class ExploreSearchApplied extends ExploreEvent {
  const ExploreSearchApplied(this.text);
  final String text;
  @override
  List<Object?> get props => <Object?>[text];
}

/// `null` = All Pairs.
final class ExploreQuoteSelected extends ExploreEvent {
  const ExploreQuoteSelected(this.quote);
  final String? quote;
  @override
  List<Object?> get props => <Object?>[quote];
}

/// Result of the filter sheet.
final class ExploreFiltersApplied extends ExploreEvent {
  const ExploreFiltersApplied({
    required this.move,
    required this.minQuoteVolume,
    required this.sortField,
    required this.ascending,
  });
  final MoveFilter move;
  final double minQuoteVolume;
  final SortField sortField;
  final bool ascending;
  @override
  List<Object?> get props =>
      <Object?>[move, minQuoteVolume, sortField, ascending];
}

/// Tap on a sortable table header: same field flips direction.
final class ExploreSortToggled extends ExploreEvent {
  const ExploreSortToggled(this.field);
  final SortField field;
  @override
  List<Object?> get props => <Object?>[field];
}

/// Clears move, min volume and sort (not search / quote).
final class ExploreFiltersReset extends ExploreEvent {
  const ExploreFiltersReset();
}

final class ExploreMoveCleared extends ExploreEvent {
  const ExploreMoveCleared();
}

final class ExploreMinVolumeCleared extends ExploreEvent {
  const ExploreMinVolumeCleared();
}

final class ExploreShowMore extends ExploreEvent {
  const ExploreShowMore();
}

/// A row became visible and wants its sparkline.
final class ExploreSparklineRequested extends ExploreEvent {
  const ExploreSparklineRequested(this.symbol);
  final String symbol;
  @override
  List<Object?> get props => <Object?>[symbol];
}

final class ExploreSparklinesArrived extends ExploreEvent {
  const ExploreSparklinesArrived(this.series);
  final Map<String, List<double>> series;
  @override
  List<Object?> get props => <Object?>[series];
}
