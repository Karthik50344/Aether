import '../../../../shared/domain/entities/candlestick.dart';
import '../entities/chart_series.dart';

/// Pure indicator maths. No I/O.
class BuildChartSeries {
  const BuildChartSeries();

  static const int maPeriod = 7;
  static const int rsiPeriod = 14;

  ChartSeries call(List<Candlestick> candles) {
    final List<double> closes = <double>[for (final Candlestick c in candles) c.close];
    double high = double.negativeInfinity;
    double low = double.infinity;
    for (final Candlestick c in candles) {
      if (c.high > high) high = c.high;
      if (c.low < low) low = c.low;
    }
    return ChartSeries(
      candles: candles,
      closes: closes,
      ma7: movingAverage(closes, maPeriod),
      rsi14: rsi(closes, rsiPeriod),
      volumes: <double>[for (final Candlestick c in candles) c.volume],
      high: candles.isEmpty ? 0 : high,
      low: candles.isEmpty ? 0 : low,
    );
  }

  /// Simple moving average; `null` until [period] values exist.
  static List<double?> movingAverage(List<double> values, int period) {
    final List<double?> out = List<double?>.filled(values.length, null);
    if (period <= 0) return out;
    double sum = 0;
    for (int i = 0; i < values.length; i++) {
      sum += values[i];
      if (i >= period) sum -= values[i - period];
      if (i >= period - 1) out[i] = sum / period;
    }
    return out;
  }

  /// Wilder's RSI. First value at index [period]; 100 when there were no
  /// losses, 50 when the price never moved.
  static List<double?> rsi(List<double> closes, int period) {
    final List<double?> out = List<double?>.filled(closes.length, null);
    if (period <= 0 || closes.length <= period) return out;

    double gain = 0;
    double loss = 0;
    for (int i = 1; i <= period; i++) {
      final double d = closes[i] - closes[i - 1];
      if (d >= 0) {
        gain += d;
      } else {
        loss -= d;
      }
    }
    double avgGain = gain / period;
    double avgLoss = loss / period;
    out[period] = _rsiValue(avgGain, avgLoss);

    for (int i = period + 1; i < closes.length; i++) {
      final double d = closes[i] - closes[i - 1];
      final double g = d > 0 ? d : 0;
      final double l = d < 0 ? -d : 0;
      avgGain = (avgGain * (period - 1) + g) / period;
      avgLoss = (avgLoss * (period - 1) + l) / period;
      out[i] = _rsiValue(avgGain, avgLoss);
    }
    return out;
  }

  static double _rsiValue(double avgGain, double avgLoss) {
    if (avgLoss == 0) return avgGain == 0 ? 50 : 100;
    final double rs = avgGain / avgLoss;
    return 100 - 100 / (1 + rs);
  }
}
