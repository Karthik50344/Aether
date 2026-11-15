import 'package:aether_app/core/errors/app_exception.dart';
import 'package:aether_app/features/market/data/datasources/market_datasource.dart';
import 'package:aether_app/features/market/data/repositories/market_repository_impl.dart';
import 'package:aether_app/shared/domain/entities/trading_pair.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fixtures.dart';

class _MockSource extends Mock implements MarketDataSource {}

void main() {
  late _MockSource source;
  late DateTime now;
  late MarketRepositoryImpl repo;

  setUp(() {
    source = _MockSource();
    now = DateTime.utc(2026, 11, 14, 12);
    when(() => source.fetchSymbols()).thenAnswer((_) async => [
          symbolInfo('BTC', 'USDT'),
          symbolInfo('ETH', 'USDT'),
          symbolInfo('LUNA', 'USDT', status: 'BREAK'),
          symbolInfo('WAVES', 'USDT', spot: false),
          symbolInfo('XRP', 'USDT'), // no ticker -> skipped
        ],);
    when(() => source.fetchTickers()).thenAnswer((_) async => [
          ticker('ETHUSDT', quoteVolume: 5e6),
          ticker('BTCUSDT', quoteVolume: 9e6),
          ticker('LUNAUSDT', quoteVolume: 9e9),
          ticker('WAVESUSDT', quoteVolume: 9e9),
        ],);
    repo = MarketRepositoryImpl(source, now: () => now);
  });

  test('keeps only active spot pairs with a ticker, sorted by volume', () async {
    final List<TradingPair> pairs = await repo.getTradingPairs();
    expect(pairs.map((p) => p.symbol), ['BTCUSDT', 'ETHUSDT']);
  });

  test('caches within the TTL and refetches after it', () async {
    await repo.getTradingPairs();
    await repo.getTradingPairs();
    verify(() => source.fetchTickers()).called(1);

    now = now.add(const Duration(seconds: 11));
    await repo.getTradingPairs();
    verify(() => source.fetchTickers()).called(1);
    // symbols stay cached for an hour
    verify(() => source.fetchSymbols()).called(1);
  });

  test('forceRefresh bypasses the cache', () async {
    await repo.getTradingPairs();
    await repo.getTradingPairs(forceRefresh: true);
    verify(() => source.fetchTickers()).called(2);
  });

  test('concurrent callers share one request', () async {
    await Future.wait([repo.getTradingPairs(), repo.getTradingPairs()]);
    verify(() => source.fetchTickers()).called(1);
  });

  test('a failed load is not cached', () async {
    when(() => source.fetchTickers())
        .thenThrow(const NetworkUnavailableException());
    await expectLater(
        repo.getTradingPairs(), throwsA(isA<NetworkUnavailableException>()),);
    when(() => source.fetchTickers())
        .thenAnswer((_) async => [ticker('BTCUSDT')]);
    expect((await repo.getTradingPairs()).length, 1);
  });

  test('getTradingPair is case-insensitive and throws NotFound', () async {
    expect((await repo.getTradingPair('btcusdt')).symbol, 'BTCUSDT');
    await expectLater(
        repo.getTradingPair('LUNAUSDT'), throwsA(isA<NotFoundException>()),);
  });

  test('clearCache forces a reload', () async {
    await repo.getTradingPairs();
    repo.clearCache();
    await repo.getTradingPairs();
    verify(() => source.fetchSymbols()).called(2);
  });
}
