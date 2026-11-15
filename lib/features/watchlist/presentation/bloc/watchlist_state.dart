import 'package:equatable/equatable.dart';

import '../../../../core/state/load_status.dart';
import '../../../../shared/domain/entities/trading_pair.dart';
import '../../domain/entities/watchlist_summary.dart';

class WatchlistState extends Equatable {
  const WatchlistState({
    this.status = LoadStatus.initial,
    this.symbols = const <String>[],
    this.pairsBySymbol = const <String, TradingPair>{},
    this.allPairs = const <TradingPair>[],
    this.summary = const WatchlistSummary.empty(),
    this.editing = false,
    this.refreshFailed = false,
    this.errorMessage,
    this.updatedAt,
  });

  final LoadStatus status;

  /// Saved symbols in the user's order (includes symbols with no live pair).
  final List<String> symbols;
  final Map<String, TradingPair> pairsBySymbol;

  /// Every active pair (feeds the "Add Pair" picker).
  final List<TradingPair> allPairs;
  final WatchlistSummary summary;
  final bool editing;

  /// A refresh failed; the last data is still shown.
  final bool refreshFailed;
  final String? errorMessage;
  final DateTime? updatedAt;

  bool get isEmpty => symbols.isEmpty;

  WatchlistState copyWith({
    LoadStatus? status,
    List<String>? symbols,
    Map<String, TradingPair>? pairsBySymbol,
    List<TradingPair>? allPairs,
    WatchlistSummary? summary,
    bool? editing,
    bool? refreshFailed,
    String? errorMessage,
    bool clearError = false,
    DateTime? updatedAt,
  }) =>
      WatchlistState(
        status: status ?? this.status,
        symbols: symbols ?? this.symbols,
        pairsBySymbol: pairsBySymbol ?? this.pairsBySymbol,
        allPairs: allPairs ?? this.allPairs,
        summary: summary ?? this.summary,
        editing: editing ?? this.editing,
        refreshFailed: refreshFailed ?? this.refreshFailed,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => <Object?>[
        status,
        symbols,
        pairsBySymbol,
        allPairs,
        summary,
        editing,
        refreshFailed,
        errorMessage,
        updatedAt,
      ];
}
