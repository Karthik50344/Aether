import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../models/depth_model.dart';
import '../models/kline_model.dart';
import '../models/recent_trade_model.dart';
import '../models/symbol_info_model.dart';
import '../models/ticker_24hr_model.dart';
import 'market_datasource.dart';

/// Binance Spot public market-data REST (`https://data-api.binance.vision`).
/// No API key, no signed requests, no account endpoints.
///
/// Request weights (Binance): ping 1 - exchangeInfo 20 (cached 1 h by the
/// repository) - ticker/24hr all symbols 80 (cached 10 s) - klines 2 -
/// trades 25 - depth(100) 5. The repository's caching keeps the app far below
/// the 6000 weight/minute limit; the [ApiClient] cooldown covers 429/418.
class MarketRemoteDataSource implements MarketDataSource {
  MarketRemoteDataSource(this._api, {Stopwatch Function()? stopwatch})
      : _newStopwatch = stopwatch ?? Stopwatch.new;

  final ApiClient _api;
  final Stopwatch Function() _newStopwatch;

  static final RegExp _symbolPattern = RegExp(r'^[A-Z0-9]{2,20}$');

  /// Symbols go into the query string; anything that is not a plain exchange
  /// symbol is rejected locally (and never reaches the network).
  static String _symbol(String raw) {
    final String s = raw.trim().toUpperCase();
    if (!_symbolPattern.hasMatch(s)) {
      throw NotFoundException('"$raw" is not a valid trading pair.');
    }
    return s;
  }

  @override
  Future<Duration> ping() async {
    final Stopwatch sw = _newStopwatch()..start();
    await _api.getJson('/api/v3/ping', retries: 0);
    sw.stop();
    return sw.elapsed;
  }

  @override
  Future<List<SymbolInfoModel>> fetchSymbols() async =>
      SymbolInfoModel.parseExchangeInfo(
        await _api.getJson(
          '/api/v3/exchangeInfo',
          query: const <String, Object?>{'permissions': 'SPOT'},
        ),
      );

  @override
  Future<List<Ticker24hrModel>> fetchTickers() async =>
      Ticker24hrModel.parseList(await _api.getJson('/api/v3/ticker/24hr'));

  @override
  Future<List<KlineModel>> fetchKlines({
    required String symbol,
    required String interval,
    required int limit,
  }) async =>
      KlineModel.parseList(
        await _api.getJson(
          '/api/v3/klines',
          query: <String, Object?>{
            'symbol': _symbol(symbol),
            'interval': interval,
            'limit': limit.clamp(1, 1000),
          },
        ),
      );

  @override
  Future<List<RecentTradeModel>> fetchRecentTrades({
    required String symbol,
    required int limit,
  }) async =>
      RecentTradeModel.parseList(
        await _api.getJson(
          '/api/v3/trades',
          query: <String, Object?>{
            'symbol': _symbol(symbol),
            'limit': limit.clamp(1, 1000),
          },
        ),
      );

  @override
  Future<DepthModel> fetchDepth({
    required String symbol,
    required int limit,
  }) async =>
      DepthModel.parse(
        await _api.getJson(
          '/api/v3/depth',
          query: <String, Object?>{
            'symbol': _symbol(symbol),
            'limit': limit,
          },
        ),
      );
}
