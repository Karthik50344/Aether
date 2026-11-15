import 'package:equatable/equatable.dart';

import '../../../../core/state/load_status.dart';

import '../../../../core/constants/quote_assets.dart';
import '../../../../core/constants/sectors.dart';
import '../../../../shared/domain/entities/trading_pair.dart';
import '../../../explore/domain/entities/explore_query.dart';
import '../../domain/entities/market_overview.dart';

export '../../../../core/state/load_status.dart';

/// Which trend list the dashboard shows (typed constants, not an enum).
class TrendKind extends Equatable {
  const TrendKind._(this.id, this.label);
  final String id;
  final String label;

  static const TrendKind gainers = TrendKind._('gainers', 'Top Gainers');
  static const TrendKind losers = TrendKind._('losers', 'Top Losers');
  static const TrendKind volume = TrendKind._('volume', '24h Vol');
  static const List<TrendKind> all = <TrendKind>[gainers, losers, volume];

  @override
  List<Object?> get props => <Object?>[id];
}

class MarketState extends Equatable {
  const MarketState({
    this.status = LoadStatus.initial,
    this.pairs = const <TradingPair>[],
    this.quote = QuoteAssets.usdt,
    this.trend = TrendKind.gainers,
    this.sector = Sector.all,
    this.sortField,
    this.ascending = false,
    this.overview,
    this.trendPairs = const <TradingPair>[],
    this.listPairs = const <TradingPair>[],
    this.sectorCounts = const <String, int>{},
    this.sparklines = const <String, List<double>>{},
    this.latency,
    this.lastUpdated,
    this.refreshing = false,
    this.errorMessage,
    this.refreshFailed = false,
  });

  final LoadStatus status;

  /// Every active pair (all quotes).
  final List<TradingPair> pairs;
  final String quote;
  final TrendKind trend;
  final Sector sector;

  /// `null` -> volume.
  final SortField? sortField;
  final bool ascending;

  // Derived (computed in the bloc by use cases, never in widgets).
  final MarketOverview? overview;
  final List<TradingPair> trendPairs;
  final List<TradingPair> listPairs;

  /// Pairs per sector id for the selected quote ("All" count included).
  final Map<String, int> sectorCounts;

  final Map<String, List<double>> sparklines;
  final Duration? latency;
  final DateTime? lastUpdated;
  final bool refreshing;
  final String? errorMessage;

  /// A background refresh failed but older data is still shown.
  final bool refreshFailed;

  bool get isLoading =>
      status == LoadStatus.loading || status == LoadStatus.initial;
  bool get hasFailed => status == LoadStatus.failure;
  bool get hasData => pairs.isNotEmpty;

  /// Quote assets present in the loaded data, primary ones first.
  List<String> get availableQuotes {
    final Set<String> present = <String>{for (final TradingPair p in pairs) p.quoteAsset};
    return <String>[
      for (final String q in QuoteAssets.dashboard)
        if (present.contains(q)) q,
    ];
  }

  MarketState copyWith({
    LoadStatus? status,
    List<TradingPair>? pairs,
    String? quote,
    TrendKind? trend,
    Sector? sector,
    SortField? sortField,
    bool? ascending,
    MarketOverview? overview,
    List<TradingPair>? trendPairs,
    List<TradingPair>? listPairs,
    Map<String, int>? sectorCounts,
    Map<String, List<double>>? sparklines,
    Duration? latency,
    DateTime? lastUpdated,
    bool? refreshing,
    String? errorMessage,
    bool clearError = false,
    bool? refreshFailed,
  }) {
    return MarketState(
      status: status ?? this.status,
      pairs: pairs ?? this.pairs,
      quote: quote ?? this.quote,
      trend: trend ?? this.trend,
      sector: sector ?? this.sector,
      sortField: sortField ?? this.sortField,
      ascending: ascending ?? this.ascending,
      overview: overview ?? this.overview,
      trendPairs: trendPairs ?? this.trendPairs,
      listPairs: listPairs ?? this.listPairs,
      sectorCounts: sectorCounts ?? this.sectorCounts,
      sparklines: sparklines ?? this.sparklines,
      latency: latency ?? this.latency,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      refreshing: refreshing ?? this.refreshing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      refreshFailed: refreshFailed ?? this.refreshFailed,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        pairs,
        quote,
        trend,
        sector,
        sortField,
        ascending,
        overview,
        trendPairs,
        listPairs,
        sectorCounts,
        sparklines,
        latency,
        lastUpdated,
        refreshing,
        errorMessage,
        refreshFailed,
      ];
}
