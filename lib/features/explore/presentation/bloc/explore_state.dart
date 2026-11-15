import 'package:equatable/equatable.dart';

import '../../../../core/constants/quote_assets.dart';
import '../../../../core/state/load_status.dart';
import '../../../../shared/domain/entities/trading_pair.dart';
import '../../domain/entities/explore_query.dart';
import '../../domain/entities/market_flow.dart';

export '../../../../core/state/load_status.dart';

class ExploreState extends Equatable {
  const ExploreState({
    this.status = LoadStatus.initial,
    this.allPairs = const <TradingPair>[],
    this.query = const ExploreQuery(quoteAsset: QuoteAssets.defaultQuote),
    this.results = const <TradingPair>[],
    this.visibleCount = pageSize,
    this.quoteCounts = const <String, int>{},
    this.flow,
    this.sparklines = const <String, List<double>>{},
    this.latency,
    this.lastUpdated,
    this.refreshing = false,
    this.refreshFailed = false,
    this.errorMessage,
  });

  /// Rows added per "Show more".
  static const int pageSize = 50;

  final LoadStatus status;
  final List<TradingPair> allPairs;
  final ExploreQuery query;

  /// `allPairs` after search + filters + sort.
  final List<TradingPair> results;
  final int visibleCount;

  /// Pairs per quote asset (all pairs, ignoring other filters).
  final Map<String, int> quoteCounts;
  final MarketFlow? flow;
  final Map<String, List<double>> sparklines;
  final Duration? latency;
  final DateTime? lastUpdated;
  final bool refreshing;
  final bool refreshFailed;
  final String? errorMessage;

  bool get isLoading =>
      status == LoadStatus.loading || status == LoadStatus.initial;
  bool get hasFailed => status == LoadStatus.failure;
  bool get hasData => allPairs.isNotEmpty;

  List<TradingPair> get visible => results.length <= visibleCount
      ? results
      : results.sublist(0, visibleCount);
  int get remaining => results.length - visible.length;

  SortField get effectiveSort => query.sortField ?? SortField.volume;

  /// True when the sort differs from the default (volume, descending).
  bool get hasCustomSort =>
      effectiveSort != SortField.volume || query.ascending;

  /// Number of non-default filters; shown as the badge on the filter button.
  int get activeFilterCount =>
      (query.move != MoveFilter.none ? 1 : 0) +
      (query.minQuoteVolume > 0 ? 1 : 0) +
      (hasCustomSort ? 1 : 0);

  /// Quote tabs: primary assets first (those present), then the rest by
  /// number of pairs.
  List<String> get quoteTabs {
    final List<String> primary = <String>[
      for (final String q in QuoteAssets.primary)
        if (quoteCounts.containsKey(q)) q,
    ];
    final List<String> others = <String>[
      for (final String q in quoteCounts.keys)
        if (!QuoteAssets.primary.contains(q)) q,
    ]..sort((String a, String b) {
        final int c = quoteCounts[b]!.compareTo(quoteCounts[a]!);
        return c != 0 ? c : a.compareTo(b);
      });
    return <String>[...primary, ...others.take(8)];
  }

  ExploreState copyWith({
    LoadStatus? status,
    List<TradingPair>? allPairs,
    ExploreQuery? query,
    List<TradingPair>? results,
    int? visibleCount,
    Map<String, int>? quoteCounts,
    MarketFlow? flow,
    Map<String, List<double>>? sparklines,
    Duration? latency,
    DateTime? lastUpdated,
    bool? refreshing,
    bool? refreshFailed,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ExploreState(
      status: status ?? this.status,
      allPairs: allPairs ?? this.allPairs,
      query: query ?? this.query,
      results: results ?? this.results,
      visibleCount: visibleCount ?? this.visibleCount,
      quoteCounts: quoteCounts ?? this.quoteCounts,
      flow: flow ?? this.flow,
      sparklines: sparklines ?? this.sparklines,
      latency: latency ?? this.latency,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      refreshing: refreshing ?? this.refreshing,
      refreshFailed: refreshFailed ?? this.refreshFailed,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        allPairs,
        query,
        results,
        visibleCount,
        quoteCounts,
        flow,
        sparklines,
        latency,
        lastUpdated,
        refreshing,
        refreshFailed,
        errorMessage,
      ];
}
