import 'dart:io';

import 'package:aether_app/core/errors/app_exception.dart';
import 'package:aether_app/features/market/data/datasources/market_mock_datasource.dart';
import 'package:aether_app/features/market/data/repositories/market_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reads the real JSON files from the project (no Flutter asset bundle).
Future<String> _file(String path) => File(path).readAsString();

void main() {
  late MarketMockDataSource source;

  setUp(() {
    source = MarketMockDataSource(loadText: _file, now: () => kMockAnchor);
  });

  test('repository over the real sample files is active-only', () async {
    final repo = MarketRepositoryImpl(source);
    final pairs = await repo.getTradingPairs();
    expect(pairs, isNotEmpty);
    expect(pairs.any((p) => p.symbol == 'LUNAUSDT'), isFalse);
    expect(pairs.any((p) => p.symbol == 'WAVESUSDT'), isFalse);
    expect(pairs.first.quoteVolume >= pairs.last.quoteVolume, isTrue);
    final btc = await repo.getTradingPair('BTCUSDT');
    expect(btc.lastPrice, closeTo(67420.50, 0.01));
  });

  test('klines honour limit and are ordered oldest first', () async {
    final k = await source.fetchKlines(
        symbol: 'BTCUSDT', interval: '15m', limit: 96);
    expect(k.length, 96);
    expect(k.first.openTime.isBefore(k.last.openTime), isTrue);
    for (final c in k) {
      expect(c.high >= c.low, isTrue);
    }
  });

  test('timestamps shift by whole days and keep candle alignment', () async {
    final a = await source.fetchKlines(
        symbol: 'BTCUSDT', interval: '1h', limit: 5);
    final later = MarketMockDataSource(
      loadText: _file,
      now: () => kMockAnchor.add(const Duration(days: 3, hours: 5)),
    );
    final b = await later.fetchKlines(
        symbol: 'BTCUSDT', interval: '1h', limit: 5);
    expect(b.first.openTime.difference(a.first.openTime),
        const Duration(days: 3));
    expect(b.first.openTime.minute, 0);
  });

  test('depth and trades are returned; unknown symbol is NotFound', () async {
    final d = await source.fetchDepth(symbol: 'BTCUSDT', limit: 10);
    expect(d.bids.length, lessThanOrEqualTo(10));
    final t = await source.fetchRecentTrades(symbol: 'BTCUSDT', limit: 20);
    expect(t.length, lessThanOrEqualTo(20));
    await expectLater(
      source.fetchKlines(symbol: 'NOPEUSDT', interval: '1h', limit: 5),
      throwsA(isA<NotFoundException>()),
    );
  });
}
