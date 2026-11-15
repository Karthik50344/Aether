import '../models/depth_model.dart';
import '../models/kline_model.dart';
import '../models/recent_trade_model.dart';
import '../models/symbol_info_model.dart';
import '../models/ticker_24hr_model.dart';

/// Raw market-data access. Two implementations exist:
///  * `MarketMockDataSource`   - local JSON in assets/mock 
///  * `MarketRemoteDataSource` - Binance public REST via Dio 
///
/// Both return the SAME API-shaped models, so all business logic (joining
/// symbols with tickers, filtering, caching, entity conversion) lives once, in
/// the repository. Implementations throw `AppException` subclasses only.
abstract interface class MarketDataSource {
  /// Round-trip time of `GET /api/v3/ping`.
  Future<Duration> ping();

  /// `GET /api/v3/exchangeInfo` -> symbols (all statuses).
  Future<List<SymbolInfoModel>> fetchSymbols();

  /// `GET /api/v3/ticker/24hr` for all symbols.
  Future<List<Ticker24hrModel>> fetchTickers();

  /// `GET /api/v3/klines`. The most recent [limit] candles, oldest first.
  Future<List<KlineModel>> fetchKlines({
    required String symbol,
    required String interval,
    required int limit,
  });

  /// `GET /api/v3/trades`. The most recent [limit] trades, oldest first.
  Future<List<RecentTradeModel>> fetchRecentTrades({
    required String symbol,
    required int limit,
  });

  /// `GET /api/v3/depth`.
  Future<DepthModel> fetchDepth({
    required String symbol,
    required int limit,
  });
}
