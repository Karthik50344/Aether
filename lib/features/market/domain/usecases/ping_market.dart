import '../repositories/market_repository.dart';

/// Connectivity check; returns the measured round-trip latency.
class PingMarket {
  const PingMarket(this._repository);
  final MarketRepository _repository;

  Future<Duration> call() => _repository.ping();
}
