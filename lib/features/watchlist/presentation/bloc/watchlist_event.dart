import 'package:equatable/equatable.dart';

sealed class WatchlistEvent extends Equatable {
  const WatchlistEvent();
  @override
  List<Object?> get props => const <Object?>[];
}

final class WatchlistStarted extends WatchlistEvent {
  const WatchlistStarted();
}

final class WatchlistRefreshed extends WatchlistEvent {
  const WatchlistRefreshed({this.force = false});
  final bool force;
  @override
  List<Object?> get props => <Object?>[force];
}

final class WatchlistEditToggled extends WatchlistEvent {
  const WatchlistEditToggled();
}

final class WatchlistPairRemoved extends WatchlistEvent {
  const WatchlistPairRemoved(this.symbol);
  final String symbol;
  @override
  List<Object?> get props => <Object?>[symbol];
}

final class WatchlistPairAdded extends WatchlistEvent {
  const WatchlistPairAdded(this.symbol);
  final String symbol;
  @override
  List<Object?> get props => <Object?>[symbol];
}

final class WatchlistReordered extends WatchlistEvent {
  const WatchlistReordered(this.oldIndex, this.newIndex);

  /// ReorderableListView semantics (newIndex is before removal).
  final int oldIndex;
  final int newIndex;
  @override
  List<Object?> get props => <Object?>[oldIndex, newIndex];
}
