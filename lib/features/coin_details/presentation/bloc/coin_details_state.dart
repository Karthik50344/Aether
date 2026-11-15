import 'package:equatable/equatable.dart';

import '../../../../core/state/load_status.dart';
import '../../../../shared/domain/entities/order_book_depth.dart';
import '../../../../shared/domain/entities/recent_trade.dart';
import '../../../../shared/domain/entities/trading_pair.dart';
import '../../domain/entities/chart_indicator.dart';
import '../../domain/entities/chart_period.dart';
import '../../domain/entities/chart_series.dart';
import '../../domain/entities/orderflow.dart';
import '../../domain/entities/pair_stats.dart';

export '../../../../core/state/load_status.dart';

/// The page loads the pair first (page-level status); chart, trades and depth
/// then load independently so one failing section never blanks the screen.
class CoinDetailsState extends Equatable {
  const CoinDetailsState({
    required this.symbol,
    this.pairStatus = LoadStatus.initial,
    this.pair,
    this.errorMessage,
    this.period = ChartPeriod.defaultPeriod,
    this.indicators = const <ChartIndicator>{ChartIndicator.ma7},
    this.chartStatus = LoadStatus.initial,
    this.series,
    this.stats,
    this.orderflow,
    this.tradesStatus = LoadStatus.initial,
    this.trades = const <RecentTrade>[],
    this.depthStatus = LoadStatus.initial,
    this.depth,
    this.isWatched = false,
    this.lastUpdated,
    this.refreshing = false,
    this.refreshFailed = false,
  });

  final String symbol;

  final LoadStatus pairStatus;
  final TradingPair? pair;
  final String? errorMessage;

  final ChartPeriod period;
  final Set<ChartIndicator> indicators;
  final LoadStatus chartStatus;
  final ChartSeries? series;

  final PairStats? stats;
  final Orderflow? orderflow;

  final LoadStatus tradesStatus;

  /// Newest first.
  final List<RecentTrade> trades;
  final LoadStatus depthStatus;
  final OrderBookDepth? depth;

  final bool isWatched;
  final DateTime? lastUpdated;
  final bool refreshing;

  /// A background refresh failed; older data is still shown.
  final bool refreshFailed;

  bool get isLoading =>
      pairStatus == LoadStatus.loading || pairStatus == LoadStatus.initial;
  bool get hasFailed => pairStatus == LoadStatus.failure;
  bool get hasPair => pair != null;
  bool showsIndicator(ChartIndicator i) => indicators.contains(i);

  CoinDetailsState copyWith({
    LoadStatus? pairStatus,
    TradingPair? pair,
    String? errorMessage,
    bool clearError = false,
    ChartPeriod? period,
    Set<ChartIndicator>? indicators,
    LoadStatus? chartStatus,
    ChartSeries? series,
    bool clearSeries = false,
    PairStats? stats,
    Orderflow? orderflow,
    bool clearOrderflow = false,
    LoadStatus? tradesStatus,
    List<RecentTrade>? trades,
    LoadStatus? depthStatus,
    OrderBookDepth? depth,
    bool? isWatched,
    DateTime? lastUpdated,
    bool? refreshing,
    bool? refreshFailed,
  }) {
    return CoinDetailsState(
      symbol: symbol,
      pairStatus: pairStatus ?? this.pairStatus,
      pair: pair ?? this.pair,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      period: period ?? this.period,
      indicators: indicators ?? this.indicators,
      chartStatus: chartStatus ?? this.chartStatus,
      series: clearSeries ? null : (series ?? this.series),
      stats: stats ?? this.stats,
      orderflow: clearOrderflow ? null : (orderflow ?? this.orderflow),
      tradesStatus: tradesStatus ?? this.tradesStatus,
      trades: trades ?? this.trades,
      depthStatus: depthStatus ?? this.depthStatus,
      depth: depth ?? this.depth,
      isWatched: isWatched ?? this.isWatched,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      refreshing: refreshing ?? this.refreshing,
      refreshFailed: refreshFailed ?? this.refreshFailed,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        symbol,
        pairStatus,
        pair,
        errorMessage,
        period,
        indicators,
        chartStatus,
        series,
        stats,
        orderflow,
        tradesStatus,
        trades,
        depthStatus,
        depth,
        isWatched,
        lastUpdated,
        refreshing,
        refreshFailed,
      ];
}
