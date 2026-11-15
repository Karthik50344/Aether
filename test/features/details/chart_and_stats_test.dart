import 'package:aether_app/features/coin_details/domain/usecases/build_chart_series.dart';
import 'package:aether_app/features/coin_details/domain/usecases/compute_pair_stats.dart';
import 'package:aether_app/shared/domain/entities/candlestick.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';

Candlestick candle(
  int i, {
  double close = 100,
  double high = 101,
  double low = 99,
  double volume = 10,
  double quoteVolume = 1000,
  double? takerBase,
  double? takerQuote,
}) =>
    Candlestick(
      openTime: DateTime.utc(2026, 11, 1 + i),
      open: close,
      high: high,
      low: low,
      close: close,
      volume: volume,
      closeTime: DateTime.utc(2026, 11, 1 + i, 23, 59),
      quoteAssetVolume: quoteVolume,
      takerBuyBaseVolume: takerBase,
      takerBuyQuoteVolume: takerQuote,
    );

void main() {
  group('moving average', () {
    test('is null until the window is full, then exact', () {
      final ma = BuildChartSeries.movingAverage(
          [for (int i = 1; i <= 10; i++) i.toDouble()], 7);
      expect(ma.take(6), everyElement(isNull));
      expect(ma[6], 4); // mean of 1..7
      expect(ma[9], 7); // mean of 4..10
    });

    test('handles short input and a bad period', () {
      expect(BuildChartSeries.movingAverage([1, 2], 7), [null, null]);
      expect(BuildChartSeries.movingAverage([1, 2], 0), [null, null]);
      expect(BuildChartSeries.movingAverage(const [], 7), isEmpty);
    });
  });

  group('RSI (Wilder)', () {
    // Classic 20-price worked example (StockCharts / Wilder).
    const closes = <double>[
      44.34, 44.09, 44.15, 43.61, 44.33, 44.83, 45.10, 45.42, 45.84, 46.08,
      45.89, 46.03, 45.61, 46.28, 46.28, 46.00, 46.03, 46.41, 46.22, 45.64,
    ];

    test('matches the reference values', () {
      final r = BuildChartSeries.rsi(closes, 14);
      expect(r.take(14), everyElement(isNull));
      expect(r[14]!, closeTo(70.46, 0.01));
      expect(r[15]!, closeTo(66.25, 0.01));
      expect(r[16]!, closeTo(66.48, 0.01));
      expect(r[17]!, closeTo(69.35, 0.01));
      expect(r[18]!, closeTo(66.29, 0.01));
      expect(r[19]!, closeTo(57.92, 0.01));
    });

    test('only gains -> 100, flat -> 50, always within 0..100', () {
      final up = BuildChartSeries.rsi(
          [for (int i = 0; i < 30; i++) 100.0 + i], 14);
      expect(up.last, 100);
      final flat = BuildChartSeries.rsi(List.filled(30, 100.0), 14);
      expect(flat.last, 50);
      for (final v in BuildChartSeries.rsi(closes, 14).whereType<double>()) {
        expect(v, inInclusiveRange(0, 100));
      }
    });

    test('too few prices -> all null', () {
      expect(BuildChartSeries.rsi([1, 2, 3], 14), everyElement(isNull));
    });
  });

  test('BuildChartSeries computes range, change and aligned lists', () {
    final candles = [
      for (int i = 0; i < 20; i++)
        candle(i, close: 100.0 + i, high: 105.0 + i, low: 95.0 + i, volume: i + 1),
    ];
    final s = const BuildChartSeries()(candles);
    expect(s.length, 20);
    expect(s.ma7.length, 20);
    expect(s.rsi14.length, 20);
    expect(s.high, 124);
    expect(s.low, 95);
    expect(s.firstClose, 100);
    expect(s.lastClose, 119);
    expect(s.changePercent, closeTo(19, 1e-9));
    expect(const BuildChartSeries()(const []).isEmpty, isTrue);
  });

  group('ComputePairStats', () {
    const compute = ComputePairStats();
    final p = pair('BTC', 'USDT', last: 100, percent: 5, quoteVolume: 2000);
    // base volume = 20

    test('fromHigh / aboveLow percentages', () {
      final s = compute(p);
      expect(s.fromHighPercent, closeTo((100 - 110) / 110 * 100, 1e-9));
      expect(s.aboveLowPercent, closeTo((100 - 90) / 90 * 100, 1e-9));
      expect(s.volumeVs7dAvgPercent, isNull); // no daily data
    });

    test('volume vs 7D average excludes today and uses at most 7 days', () {
      final daily = [
        candle(0, volume: 1000), // older than the 7-day window
        for (int i = 1; i <= 7; i++) candle(i, volume: 10),
        candle(8, volume: 999), // "today" - excluded
      ];
      final s = compute(p, daily: daily);
      expect(s.volumeVs7dAvgPercent, closeTo(100, 1e-9)); // 20 vs avg 10
    });

    test('needs at least two daily candles', () {
      expect(compute(p, daily: [candle(0)]).volumeVs7dAvgPercent, isNull);
    });

    test('orderflow from the latest daily candle', () {
      final o = compute.orderflow([
        candle(0),
        candle(1, volume: 10, quoteVolume: 1000, takerBase: 6, takerQuote: 600),
      ])!;
      expect(o.takerBuyShare, closeTo(0.6, 1e-9));
      expect(o.netQuoteFlow, closeTo(200, 1e-9)); // 600 buy - 400 sell
    });

    test('orderflow is null without taker fields or volume', () {
      expect(compute.orderflow(const []), isNull);
      expect(compute.orderflow([candle(0)]), isNull);
      expect(
        compute.orderflow([candle(0, volume: 0, takerBase: 0, takerQuote: 0)]),
        isNull,
      );
    });
  });
}
