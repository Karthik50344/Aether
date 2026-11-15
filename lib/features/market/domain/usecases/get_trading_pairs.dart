import '../../../../shared/domain/entities/trading_pair.dart';
import '../repositories/market_repository.dart';

/// Active Spot pairs with 24h stats, sorted by quote volume (descending).
class GetTradingPairs {
  const GetTradingPairs(this._repository);
  final MarketRepository _repository;

  Future<List<TradingPair>> call({bool forceRefresh = false}) =>
      _repository.getTradingPairs(forceRefresh: forceRefresh);
}
