import '../../../../shared/domain/entities/candlestick.dart';
import '../../../market/domain/repositories/market_repository.dart';
import '../entities/chart_period.dart';

/// Candles for a chart period (interval and limit come from [ChartPeriod]).
class GetCandlesticks {
  const GetCandlesticks(this._repository);
  final MarketRepository _repository;

  Future<List<Candlestick>> call(String symbol, ChartPeriod period) =>
      _repository.getCandlesticks(
        symbol: symbol,
        interval: period.interval,
        limit: period.limit,
      );
}
