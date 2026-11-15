import '../repositories/market_repository.dart';

/// Close prices of the last 24 one-hour candles, oldest first.
/// Returns an empty list when no history is available for the symbol
/// (a missing sparkline must never break a list row).
class GetSparkline {
  const GetSparkline(this._repository);
  final MarketRepository _repository;

  static const String interval = '1h';
  static const int points = 24;

  Future<List<double>> call(String symbol) async {
    final candles = await _repository.getCandlesticks(
      symbol: symbol,
      interval: interval,
      limit: points,
    );
    return <double>[for (final c in candles) c.close];
  }
}
