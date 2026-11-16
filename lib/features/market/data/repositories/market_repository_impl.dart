import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/clock.dart';
import '../../../../shared/domain/entities/candlestick.dart';
import '../../../../shared/domain/entities/order_book_depth.dart';
import '../../../../shared/domain/entities/recent_trade.dart';
import '../../../../shared/domain/entities/trading_pair.dart';
import '../../domain/repositories/market_repository.dart';
import '../datasources/market_datasource.dart';
import '../models/depth_model.dart';
import '../models/kline_model.dart';
import '../models/recent_trade_model.dart';
import '../models/symbol_info_model.dart';
import '../models/ticker_24hr_model.dart';

class MarketRepositoryImpl implements MarketRepository {
  MarketRepositoryImpl(
      this._dataSource, {
        Clock? now,
        this.pairsTtl = const Duration(seconds: 10),
        this.symbolsTtl = const Duration(hours: 1),
      }) : _now = now ?? DateTime.now;

  final MarketDataSource _dataSource;
  final Clock _now;
  final Duration pairsTtl;
  final Duration symbolsTtl;

  List<SymbolInfoModel>? _symbols;
  DateTime? _symbolsAt;

  List<TradingPair>? _pairs;
  DateTime? _pairsAt;
  Future<List<TradingPair>>? _pairsInFlight;

  @override
  Future<Duration> ping() => _dataSource.ping();

  @override
  Future<List<TradingPair>> getTradingPairs({bool forceRefresh = false}) {
    final List<TradingPair>? cached = _pairs;
    final DateTime? at = _pairsAt;
    if (!forceRefresh &&
        cached != null &&
        at != null &&
        _now().difference(at) < pairsTtl) {
      return Future<List<TradingPair>>.value(cached);
    }
    return _pairsInFlight ??= _loadPairs().whenComplete(() {
      _pairsInFlight = null;
    });
  }

  Future<List<TradingPair>> _loadPairs() async {
    final (List<SymbolInfoModel> symbols, List<Ticker24hrModel> tickers) =
    await (_loadSymbols(), _dataSource.fetchTickers()).wait;

    final Map<String, Ticker24hrModel> tickerBySymbol = <String, Ticker24hrModel>{
      for (final Ticker24hrModel t in tickers) t.symbol: t,
    };

    // Only eligible (TRADING + Spot-allowed) symbols that have a usable ticker.
    final List<TradingPair> pairs = <TradingPair>[
      for (final SymbolInfoModel s in symbols)
        if (s.isActiveSpot)
          if (tickerBySymbol[s.symbol] case final Ticker24hrModel t)
            _toPair(s, t),
    ]..sort((TradingPair a, TradingPair b) {
      final int byVolume = b.quoteVolume.compareTo(a.quoteVolume);
      return byVolume != 0 ? byVolume : a.symbol.compareTo(b.symbol);
    });

    final List<TradingPair> result = List<TradingPair>.unmodifiable(pairs);
    _pairs = result;
    _pairsAt = _now();
    return result;
  }

  Future<List<SymbolInfoModel>> _loadSymbols() async {
    final List<SymbolInfoModel>? cached = _symbols;
    final DateTime? at = _symbolsAt;
    if (cached != null && at != null && _now().difference(at) < symbolsTtl) {
      return cached;
    }
    final List<SymbolInfoModel> fresh = await _dataSource.fetchSymbols();
    _symbols = fresh;
    _symbolsAt = _now();
    return fresh;
  }

  static TradingPair _toPair(SymbolInfoModel s, Ticker24hrModel t) {
    return TradingPair(
      symbol: s.symbol,
      baseAsset: s.baseAsset,
      quoteAsset: s.quoteAsset,
      lastPrice: t.lastPrice,
      priceChange: t.priceChange,
      priceChangePercent: t.priceChangePercent,
      highPrice: t.highPrice,
      lowPrice: t.lowPrice,
      volume: t.volume,
      quoteVolume: t.quoteVolume,
      tradeCount: t.count,
      openPrice: t.openPrice,
      weightedAvgPrice: t.weightedAvgPrice,
    );
  }

  @override
  Future<TradingPair> getTradingPair(
      String symbol, {
        bool forceRefresh = false,
      }) async {
    final String wanted = symbol.trim().toUpperCase();
    final List<TradingPair> pairs =
    await getTradingPairs(forceRefresh: forceRefresh);
    for (final TradingPair p in pairs) {
      if (p.symbol == wanted) return p;
    }
    throw NotFoundException('Trading pair $wanted was not found.');
  }

  @override
  Future<List<Candlestick>> getCandlesticks({
    required String symbol,
    required String interval,
    required int limit,
  }) async {
    final List<KlineModel> rows = await _dataSource.fetchKlines(
      symbol: symbol.trim().toUpperCase(),
      interval: interval,
      limit: limit,
    );
    return <Candlestick>[for (final KlineModel k in rows) k.toEntity()];
  }

  @override
  Future<List<RecentTrade>> getRecentTrades(String symbol, {int limit = 20}) async {
    final List<RecentTradeModel> rows = await _dataSource.fetchRecentTrades(
      symbol: symbol.trim().toUpperCase(),
      limit: limit,
    );
    return <RecentTrade>[for (final RecentTradeModel t in rows) t.toEntity()];
  }

  @override
  Future<OrderBookDepth> getOrderBookDepth(String symbol, {int limit = 100}) async {
    final DepthModel depth = await _dataSource.fetchDepth(
      symbol: symbol.trim().toUpperCase(),
      limit: limit,
    );
    return depth.toEntity();
  }

  @override
  void clearCache() {
    _symbols = null;
    _symbolsAt = null;
    _pairs = null;
    _pairsAt = null;
  }
}