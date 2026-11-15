import 'package:aether_app/features/market/data/models/symbol_info_model.dart';
import 'package:aether_app/features/market/data/models/ticker_24hr_model.dart';
import 'package:aether_app/shared/domain/entities/trading_pair.dart';

SymbolInfoModel symbolInfo(
  String base,
  String quote, {
  String status = 'TRADING',
  bool spot = true,
}) =>
    SymbolInfoModel(
      symbol: '$base$quote',
      status: status,
      baseAsset: base,
      quoteAsset: quote,
      isSpotTradingAllowed: spot,
    );

Ticker24hrModel ticker(
  String symbol, {
  double last = 100,
  double percent = 1,
  double quoteVolume = 1000000,
}) =>
    Ticker24hrModel(
      symbol: symbol,
      priceChange: last * percent / 100,
      priceChangePercent: percent,
      lastPrice: last,
      highPrice: last * 1.1,
      lowPrice: last * 0.9,
      volume: quoteVolume / last,
      quoteVolume: quoteVolume,
    );

TradingPair pair(
  String base,
  String quote, {
  double last = 100,
  double percent = 1,
  double quoteVolume = 2000000,
}) =>
    TradingPair(
      symbol: '$base$quote',
      baseAsset: base,
      quoteAsset: quote,
      lastPrice: last,
      priceChange: last * percent / 100,
      priceChangePercent: percent,
      highPrice: last * 1.1,
      lowPrice: last * 0.9,
      volume: quoteVolume / last,
      quoteVolume: quoteVolume,
    );
