import '../repositories/market_repository.dart';

/// Drops cached pairs/symbols so the next request hits the data source.
class ClearMarketCache {
  const ClearMarketCache(this._repository);
  final MarketRepository _repository;

  void call() => _repository.clearCache();
}
