import '../../../../shared/domain/entities/recent_trade.dart';
import '../../../market/domain/repositories/market_repository.dart';

class GetRecentTrades {
  const GetRecentTrades(this._repository);
  final MarketRepository _repository;

  Future<List<RecentTrade>> call(String symbol, {int limit = 20}) =>
      _repository.getRecentTrades(symbol, limit: limit);
}
