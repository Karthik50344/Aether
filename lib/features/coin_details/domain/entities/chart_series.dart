import 'package:equatable/equatable.dart';

import '../../../../shared/domain/entities/candlestick.dart';

/// Everything the chart draws, computed once from candles (pure data).
class ChartSeries extends Equatable {
  const ChartSeries({
    required this.candles,
    required this.closes,
    required this.ma7,
    required this.rsi14,
    required this.volumes,
    required this.high,
    required this.low,
  });

  final List<Candlestick> candles;
  final List<double> closes;

  /// Same length as [closes]; `null` while there is not enough history.
  final List<double?> ma7;
  final List<double?> rsi14;
  final List<double> volumes;

  /// Highest candle high / lowest candle low in the range.
  final double high;
  final double low;

  bool get isEmpty => candles.isEmpty;
  int get length => candles.length;

  double get firstClose => closes.isEmpty ? 0 : closes.first;
  double get lastClose => closes.isEmpty ? 0 : closes.last;

  /// Change from the first to the last close of the range, in percent.
  double get changePercent =>
      firstClose == 0 ? 0 : (lastClose - firstClose) / firstClose * 100;

  @override
  List<Object?> get props =>
      <Object?>[candles, closes, ma7, rsi14, volumes, high, low];
}
