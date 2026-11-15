import 'package:aether_app/core/errors/app_exception.dart';
import 'package:aether_app/core/network/api_client.dart';
import 'package:aether_app/features/market/data/datasources/market_remote_datasource.dart';
import 'package:aether_app/features/market/data/models/depth_model.dart';
import 'package:aether_app/features/market/data/models/kline_model.dart';
import 'package:aether_app/features/market/data/models/recent_trade_model.dart';
import 'package:aether_app/features/market/data/models/symbol_info_model.dart';
import 'package:aether_app/features/market/data/models/ticker_24hr_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_adapter.dart';

void main() {
  late FakeHttpAdapter http;
  late MarketRemoteDataSource ds;

  setUp(() {
    http = FakeHttpAdapter();
    ds = MarketRemoteDataSource(
      ApiClient(
        Dio(BaseOptions(
          baseUrl: 'https://data-api.binance.vision',
          responseType: ResponseType.plain,
          validateStatus: (_) => true,
        ))
          ..httpClientAdapter = http,
        retryDelay: Duration.zero,
      ),
    );
  });

  test('fetchSymbols calls exchangeInfo for SPOT and parses', () async {
    http.enqueueJson('''
{"symbols":[{"symbol":"BTCUSDT","status":"TRADING","baseAsset":"BTC",
"quoteAsset":"USDT","isSpotTradingAllowed":true}]}''');
    final List<SymbolInfoModel> r = await ds.fetchSymbols();
    expect(r.single.symbol, 'BTCUSDT');
    expect(http.requests.single.path, '/api/v3/exchangeInfo');
    expect(http.requests.single.queryParameters['permissions'], 'SPOT');
  });

  test('fetchTickers parses the 24hr array', () async {
    http.enqueueJson('''
[{"symbol":"BTCUSDT","priceChange":"10","priceChangePercent":"1.5",
"lastPrice":"100","highPrice":"110","lowPrice":"90","volume":"5",
"quoteVolume":"500"}]''');
    final List<Ticker24hrModel> r = await ds.fetchTickers();
    expect(r.single.priceChangePercent, 1.5);
    expect(http.requests.single.path, '/api/v3/ticker/24hr');
  });

  test('fetchKlines sends symbol, interval and limit', () async {
    http.enqueueJson('[]');
    final List<KlineModel> r =
        await ds.fetchKlines(symbol: 'btcusdt', interval: '15m', limit: 96);
    expect(r, isEmpty);
    expect(http.requests.single.queryParameters, <String, dynamic>{
      'symbol': 'BTCUSDT',
      'interval': '15m',
      'limit': 96,
    });
  });

  test('limits are clamped to Binance maximum (1000)', () async {
    http.enqueueJson('[]');
    await ds.fetchRecentTrades(symbol: 'BTCUSDT', limit: 5000);
    expect(http.requests.single.queryParameters['limit'], 1000);
  });

  test('fetchRecentTrades and fetchDepth hit their endpoints', () async {
    http.enqueueJson(
        '[{"id":1,"price":"1","qty":"2","quoteQty":"2","time":1700000000000,"isBuyerMaker":true}]');
    final List<RecentTradeModel> t =
        await ds.fetchRecentTrades(symbol: 'BTCUSDT', limit: 20);
    expect(t, hasLength(1));
    expect(http.requests.last.path, '/api/v3/trades');

    http.enqueueJson('{"lastUpdateId":1,"bids":[["1.0","2.0"]],"asks":[["1.1","3.0"]]}');
    final DepthModel d = await ds.fetchDepth(symbol: 'BTCUSDT', limit: 100);
    expect(d.bids, hasLength(1));
    expect(http.requests.last.path, '/api/v3/depth');
  });

  test('a malformed symbol is rejected locally with no request', () async {
    await expectLater(
      ds.fetchKlines(symbol: 'BTC&limit=1', interval: '1m', limit: 10),
      throwsA(isA<NotFoundException>()),
    );
    expect(http.requests, isEmpty);
  });

  test('ping returns a duration and does not retry', () async {
    http.enqueueJson('{}');
    expect(await ds.ping(), isA<Duration>());
    http.enqueueError(DioExceptionType.connectionError);
    await expectLater(ds.ping(), throwsA(isA<NetworkUnavailableException>()));
    expect(http.requests, hasLength(2));
  });

  test('an unexpected shape -> ParseException', () async {
    http.enqueueJson('{"oops":true}');
    await expectLater(ds.fetchKlines(symbol: 'BTCUSDT', interval: '1m', limit: 5),
        throwsA(isA<ParseException>()));
  });
}
