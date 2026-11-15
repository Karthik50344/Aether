import '../../../../shared/domain/entities/candlestick.dart';
import '../../../market/domain/repositories/market_repository.dart';

/// Last 8 daily candles: today's taker flow + the 7-day volume average.
class GetDailyCandles {
  const GetDailyCandles(this._repository);
  final MarketRepository _repository;

  static const int count = 8;

  Future<List<Candlestick>> call(String symbol) =>
      _repository.getCandlesticks(symbol: symbol, interval: '1d', limit: count);
}
