import '../../../../shared/domain/entities/trading_pair.dart';
import '../repositories/market_repository.dart';

/// One pair by symbol. Throws `NotFoundException` if it is not active.
class GetTradingPair {
  const GetTradingPair(this._repository);
  final MarketRepository _repository;

  Future<TradingPair> call(String symbol, {bool forceRefresh = false}) =>
      _repository.getTradingPair(symbol, forceRefresh: forceRefresh);
}
