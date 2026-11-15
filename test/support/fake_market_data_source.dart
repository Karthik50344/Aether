import 'package:aether_app/features/market/data/datasources/market_datasource.dart';
import 'package:aether_app/features/market/data/models/depth_model.dart';
import 'package:aether_app/features/market/data/models/kline_model.dart';
import 'package:aether_app/features/market/data/models/recent_trade_model.dart';
import 'package:aether_app/features/market/data/models/symbol_info_model.dart';
import 'package:aether_app/features/market/data/models/ticker_24hr_model.dart';
import 'package:aether_app/shared/domain/entities/order_book_depth.dart';

import 'fixtures.dart';

/// Small in-memory data source for widget tests (no asset bundle, no timers).
class FakeMarketDataSource implements MarketDataSource {
  FakeMarketDataSource({
    this.failTickers = false,
    this.failTrades = false,
    this.failDepth = false,
  });

  bool failTickers;
  bool failTrades;
  bool failDepth;

  @override
  Future<Duration> ping() async => const Duration(milliseconds: 24);

  @override
  Future<List<SymbolInfoModel>> fetchSymbols() async => <SymbolInfoModel>[
        symbolInfo('BTC', 'USDT'),
        symbolInfo('ETH', 'USDT'),
        symbolInfo('SOL', 'USDT'),
        symbolInfo('BNB', 'USDT'),
        symbolInfo('ETH', 'BTC'),
      ];

  @override
  Future<List<Ticker24hrModel>> fetchTickers() async {
    if (failTickers) throw StateError('boom');
    return <Ticker24hrModel>[
      ticker('BTCUSDT', last: 67420.5, percent: 3.42, quoteVolume: 12.4e9),
      ticker('ETHUSDT', last: 3500, percent: -1.2, quoteVolume: 6e9),
      ticker('SOLUSDT', last: 178.45, percent: 12.8, quoteVolume: 3.9e9),
      ticker('BNBUSDT', last: 590, percent: -0.5, quoteVolume: 1.1e9),
      ticker('ETHBTC', last: 0.052, percent: 0.4, quoteVolume: 900),
    ];
  }

  @override
  Future<List<KlineModel>> fetchKlines({
    required String symbol,
    required String interval,
    required int limit,
  }) async {
    final DateTime t = DateTime.utc(2026, 11, 14);
    return <KlineModel>[
      for (int i = 0; i < limit; i++)
        KlineModel(
          openTime: t.add(Duration(hours: i)),
          open: 100.0 + i,
          high: 102.0 + i,
          low: 99.0 + i,
          close: 101.0 + i,
          volume: 10,
          closeTime: t.add(Duration(hours: i, minutes: 59)),
          quoteAssetVolume: 1000,
          takerBuyBaseVolume: 6,
          takerBuyQuoteVolume: 600,
        ),
    ];
  }

  @override
  Future<List<RecentTradeModel>> fetchRecentTrades({
    required String symbol,
    required int limit,
  }) async {
    if (failTrades) throw StateError('trades boom');
    final DateTime t = DateTime.utc(2026, 11, 14, 14, 42, 1);
    return <RecentTradeModel>[
      for (int i = 0; i < limit && i < 12; i++)
        RecentTradeModel(
          id: i,
          price: 67420.5 + i,
          qty: 0.5 + i,
          quoteQty: (0.5 + i) * (67420.5 + i),
          time: t.add(Duration(seconds: i)),
          isBuyerMaker: i.isOdd, // odd -> taker SELL
        ),
    ];
  }

  @override
  Future<DepthModel> fetchDepth({required String symbol, required int limit}) async {
    if (failDepth) throw StateError('depth boom');
    return const DepthModel(
      lastUpdateId: 1,
      bids: <DepthLevel>[DepthLevel(price: 100, quantity: 6)], // 600
      asks: <DepthLevel>[DepthLevel(price: 100, quantity: 4)], // 400
    );
  }
}
