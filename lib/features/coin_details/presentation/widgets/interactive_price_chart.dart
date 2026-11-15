import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/formatters/formatters.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/entities/candlestick.dart';
import '../../domain/entities/chart_indicator.dart';
import '../../domain/entities/chart_series.dart';
import 'chart_panels.dart';

/// Line + area price chart with a touch crosshair, optional MA(7) overlay and
/// VOL / RSI panels. Touching or dragging moves the crosshair and updates the
/// readout; releasing returns to the latest candle.
class InteractivePriceChart extends StatefulWidget {
  const InteractivePriceChart({
    required this.series,
    required this.interval,
    required this.indicators,
    required this.quote,
    required this.highLowLabel,
    this.now,
    this.height = 224,
    super.key,
  });

  final ChartSeries series;

  /// Binance interval of the candles ("15m"): decides the axis label format.
  final String interval;
  final Set<ChartIndicator> indicators;
  final String quote;

  /// "24h" or "Period": prefix of the High/Low tags.
  final String highLowLabel;
  final DateTime Function()? now;
  final double height;

  @override
  State<InteractivePriceChart> createState() => _InteractivePriceChartState();
}

class _InteractivePriceChartState extends State<InteractivePriceChart> {
  int? _touched;

  ChartSeries get _s => widget.series;

  int get _shownIndex {
    final int last = _s.length - 1;
    final int? t = _touched;
    return (t == null || t < 0 || t > last) ? last : t;
  }

  void _onTouch(FlTouchEvent event, LineTouchResponse? response) {
    final List<TouchLineBarSpot>? spots = response?.lineBarSpots;
    final int? next = (!event.isInterestedForInteractions ||
            spots == null ||
            spots.isEmpty)
        ? null
        : spots.first.spotIndex;
    if (next != _touched) setState(() => _touched = next);
  }

  @override
  void didUpdateWidget(InteractivePriceChart old) {
    super.didUpdateWidget(old);
    if (!identical(old.series, widget.series)) _touched = null;
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    if (_s.length < 2) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'Not enough candles for this range.',
            style: AppTypography.label.copyWith(color: p.textSecondary),
          ),
        ),
      );
    }
    final int i = _shownIndex;
    final Candlestick candle = _s.candles[i];
    final double? ma = _s.ma7[i];
    final bool showMa = widget.indicators.contains(ChartIndicator.ma7);
    final bool showVol = widget.indicators.contains(ChartIndicator.volume);
    final bool showRsi = widget.indicators.contains(ChartIndicator.rsi);
    final int? crosshair = _touched == null ? null : i;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Readout(
          price: Fmt.pricedIn(_s.closes[i], widget.quote),
          stamp: Fmt.chartStamp(candle.openTime, now: widget.now?.call()),
          maText: showMa && ma != null
              ? 'MA(7) ${Fmt.pricedIn(ma, widget.quote)}'
              : null,
          live: _touched == null,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: widget.height,
          child: _priceChart(p, showMa),
        ),
        if (showVol) ...<Widget>[
          const SizedBox(height: 8),
          _PanelLabel('VOL'),
          VolumePanel(
            key: const ValueKey<String>('panel-vol'),
            volumes: _s.volumes,
            bullish: <bool>[for (final Candlestick c in _s.candles) c.isBullish],
            highlightIndex: crosshair,
          ),
        ],
        if (showRsi) ...<Widget>[
          const SizedBox(height: 8),
          _PanelLabel(
            _s.rsi14[i] == null
                ? 'RSI(14)'
                : 'RSI(14)  ${_s.rsi14[i]!.toStringAsFixed(1)}',
          ),
          RsiPanel(
            key: const ValueKey<String>('panel-rsi'),
            values: _s.rsi14,
            highlightIndex: crosshair,
          ),
        ],
        const SizedBox(height: 6),
        _TimeAxis(series: _s, interval: widget.interval),
      ],
    );
  }

  Widget _priceChart(AppPalette p, bool showMa) {
    final Color lineColor = _s.lastClose >= _s.firstClose ? p.positive : p.negative;

    double minY = _s.low;
    double maxY = _s.high;
    for (final double? v in _s.ma7) {
      if (showMa && v != null) {
        minY = math.min(minY, v);
        maxY = math.max(maxY, v);
      }
    }
    final double pad = (maxY - minY) == 0 ? math.max(maxY.abs() * 0.01, 1e-9) : (maxY - minY) * 0.12;
    minY -= pad;
    maxY += pad;

    final LineChartBarData price = LineChartBarData(
      spots: <FlSpot>[
        for (int k = 0; k < _s.closes.length; k++) FlSpot(k.toDouble(), _s.closes[k]),
      ],
      isCurved: true,
      curveSmoothness: 0.2,
      preventCurveOverShooting: true,
      color: lineColor,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[lineColor.withAlpha(70), lineColor.withAlpha(0)],
        ),
      ),
    );

    final LineChartBarData? maBar = showMa
        ? LineChartBarData(
            spots: <FlSpot>[
              for (int k = 0; k < _s.ma7.length; k++)
                if (_s.ma7[k] != null) FlSpot(k.toDouble(), _s.ma7[k]!),
            ],
            isCurved: true,
            curveSmoothness: 0.2,
            preventCurveOverShooting: true,
            color: p.primaryLight,
            barWidth: 1.5,
            dashArray: <int>[4, 4],
            dotData: const FlDotData(show: false),
          )
        : null;

    HorizontalLine tag(double y, String text, Color color, Alignment align) {
      return HorizontalLine(
        y: y,
        color: color.withAlpha(90),
        strokeWidth: 1,
        dashArray: <int>[4, 4],
        label: HorizontalLineLabel(
          show: true,
          alignment: align,
          padding: const EdgeInsets.only(left: 6, right: 6, bottom: 2),
          style: AppTypography.label.copyWith(color: color, fontSize: 10),
          labelResolver: (_) => text,
        ),
      );
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (_s.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 3,
          getDrawingHorizontalLine: (_) => FlLine(
            color: p.surfaceHighest.withAlpha(120),
            strokeWidth: 1,
            dashArray: <int>[3, 5],
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: <HorizontalLine>[
            tag(_s.high, '${widget.highLowLabel} High ${Fmt.pricedIn(_s.high, widget.quote)}',
                p.positive, Alignment.topLeft),
            tag(_s.low, '${widget.highLowLabel} Low ${Fmt.pricedIn(_s.low, widget.quote)}',
                p.negative, Alignment.bottomRight),
          ],
        ),
        lineBarsData: <LineChartBarData>[price, if (maBar != null) maBar],
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchCallback: _onTouch,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> spots) =>
                <LineTooltipItem?>[for (final LineBarSpot _ in spots) null],
          ),
          getTouchedSpotIndicator:
              (LineChartBarData bar, List<int> indexes) => <TouchedSpotIndicatorData>[
            for (final int _ in indexes)
              bar.dashArray != null
                  ? const TouchedSpotIndicatorData(
                      FlLine(color: Colors.transparent),
                      FlDotData(show: false),
                    )
                  : TouchedSpotIndicatorData(
                      FlLine(
                        color: p.textSecondary,
                        strokeWidth: 1,
                        dashArray: <int>[4, 4],
                      ),
                      FlDotData(
                        getDotPainter: (FlSpot s, double pct, LineChartBarData b, int idx) =>
                            FlDotCirclePainter(
                          radius: 5,
                          color: p.background,
                          strokeWidth: 2,
                          strokeColor: lineColor,
                        ),
                      ),
                    ),
          ],
        ),
      ),
    );
  }
}

class _Readout extends StatelessWidget {
  const _Readout({
    required this.price,
    required this.stamp,
    required this.maText,
    required this.live,
  });

  final String price;
  final String stamp;
  final String? maText;

  /// No finger on the chart: shows the latest candle.
  final bool live;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: p.primaryLight, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text.rich(
            TextSpan(children: <InlineSpan>[
              TextSpan(
                text: live ? 'Latest: ' : 'Crosshair: ',
                style: AppTypography.label.copyWith(color: p.textSecondary),
              ),
              TextSpan(
                text: price,
                style: AppTypography.price.copyWith(color: p.textPrimary),
              ),
              if (maText != null)
                TextSpan(
                  text: '  $maText',
                  style: AppTypography.label
                      .copyWith(color: p.primaryLight, fontSize: 10),
                ),
            ]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          stamp,
          maxLines: 1,
          style: AppTypography.label.copyWith(color: p.textSecondary, fontSize: 10),
        ),
      ],
    );
  }
}

class _PanelLabel extends StatelessWidget {
  const _PanelLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: AppTypography.micro
            .copyWith(color: context.palette.textSecondary, fontSize: 10),
      ),
    );
  }
}

class _TimeAxis extends StatelessWidget {
  const _TimeAxis({required this.series, required this.interval});

  final ChartSeries series;
  final String interval;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final int n = series.length;
    final List<int> idx = <int>{
      0,
      (n - 1) ~/ 4,
      (n - 1) ~/ 2,
      (n - 1) * 3 ~/ 4,
      n - 1,
    }.toList();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        for (final int k in idx)
          Text(
            Fmt.chartAxis(series.candles[k].openTime, interval),
            style: AppTypography.label.copyWith(color: p.textSecondary, fontSize: 10),
          ),
      ],
    );
  }
}
