import '../../../../shared/domain/entities/candlestick.dart';
import '../../../../shared/domain/entities/order_book_depth.dart';
import '../../../../shared/domain/entities/recent_trade.dart';
import '../../../../shared/domain/entities/trading_pair.dart';

/// Single access point for Binance Spot market data.
///
/// The domain and presentation layers depend only on this contract; whether
/// data comes from local JSON or the Binance REST API is invisible to them.
/// All methods throw `AppException` subclasses on failure.
abstract interface class MarketRepository {
  /// Round-trip latency of the connectivity check (`/api/v3/ping`).
  Future<Duration> ping();

  /// Active Spot trading pairs with 24h statistics, sorted by 24h quote volume
  /// (descending). Cached briefly; [forceRefresh] bypasses the cache.
  Future<List<TradingPair>> getTradingPairs({bool forceRefresh = false});

  /// One pair by exchange symbol (case-insensitive).
  /// Throws `NotFoundException` when the pair is not active on Spot.
  Future<TradingPair> getTradingPair(String symbol, {bool forceRefresh = false});

  /// The most recent [limit] candles for [interval] (Binance interval string),
  /// oldest first.
  Future<List<Candlestick>> getCandlesticks({
    required String symbol,
    required String interval,
    required int limit,
  });

  /// The most recent public trades, oldest first.
  Future<List<RecentTrade>> getRecentTrades(String symbol, {int limit = 20});

  /// Order-book snapshot limited to [limit] levels per side.
  Future<OrderBookDepth> getOrderBookDepth(String symbol, {int limit = 100});

  /// Drops cached pairs/symbols (used by "Clear cache & reset datafeed").
  void clearCache();
}
