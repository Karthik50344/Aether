import '../../../../shared/domain/entities/order_book_depth.dart';
import '../../../market/domain/repositories/market_repository.dart';

class GetOrderBookDepth {
  const GetOrderBookDepth(this._repository);
  final MarketRepository _repository;

  Future<OrderBookDepth> call(String symbol, {int limit = 100}) =>
      _repository.getOrderBookDepth(symbol, limit: limit);
}
