import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

/// Volume bars aligned with the price line: candle i sits at
/// `x = i / (n - 1) * width`, exactly like the fl_chart spots above it.
class VolumePanel extends StatelessWidget {
  const VolumePanel({
    required this.volumes,
    required this.bullish,
    required this.highlightIndex,
    this.height = 44,
    super.key,
  });

  final List<double> volumes;

  /// Same length as [volumes]; true -> green bar, false -> red bar.
  final List<bool> bullish;
  final int? highlightIndex;
  final double height;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _VolumePainter(
          volumes: volumes,
          bullish: bullish,
          up: p.positive.withAlpha(150),
          down: p.negative.withAlpha(150),
          line: p.textSecondary,
          highlightIndex: highlightIndex,
        ),
      ),
    );
  }
}

class _VolumePainter extends CustomPainter {
  _VolumePainter({
    required this.volumes,
    required this.bullish,
    required this.up,
    required this.down,
    required this.line,
    required this.highlightIndex,
  });

  final List<double> volumes;
  final List<bool> bullish;
  final Color up;
  final Color down;
  final Color line;
  final int? highlightIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final int n = volumes.length;
    if (n < 2 || size.isEmpty) return;
    double maxV = 0;
    for (final double v in volumes) {
      if (v > maxV) maxV = v;
    }
    if (maxV <= 0) return;
    final double slot = size.width / (n - 1);
    final double barW = (slot * 0.7).clamp(1.0, 12.0);
    final Paint paint = Paint();
    for (int i = 0; i < n; i++) {
      final double h = volumes[i] / maxV * size.height;
      final double x = i * slot;
      paint.color = bullish[i] ? up : down;
      canvas.drawRect(
        Rect.fromLTWH(x - barW / 2, size.height - h, barW, h),
        paint,
      );
    }
    _crosshair(canvas, size, highlightIndex, n, line);
  }

  @override
  bool shouldRepaint(_VolumePainter old) =>
      old.volumes != volumes ||
      old.highlightIndex != highlightIndex ||
      old.up != up;
}

/// RSI(14) line with the usual 30 / 70 guides.
class RsiPanel extends StatelessWidget {
  const RsiPanel({
    required this.values,
    required this.highlightIndex,
    this.height = 64,
    super.key,
  });

  final List<double?> values;
  final int? highlightIndex;
  final double height;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _RsiPainter(
          values: values,
          color: p.primaryLight,
          guide: p.surfaceHighest,
          line: p.textSecondary,
          highlightIndex: highlightIndex,
        ),
      ),
    );
  }
}

class _RsiPainter extends CustomPainter {
  _RsiPainter({
    required this.values,
    required this.color,
    required this.guide,
    required this.line,
    required this.highlightIndex,
  });

  final List<double?> values;
  final Color color;
  final Color guide;
  final Color line;
  final int? highlightIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final int n = values.length;
    if (n < 2 || size.isEmpty) return;
    double y(double v) => size.height * (1 - v / 100);

    final Paint guidePaint = Paint()
      ..color = guide
      ..strokeWidth = 1;
    for (final double level in <double>[30, 70]) {
      canvas.drawLine(Offset(0, y(level)), Offset(size.width, y(level)), guidePaint);
    }

    final Path path = Path();
    bool started = false;
    for (int i = 0; i < n; i++) {
      final double? v = values[i];
      if (v == null) continue;
      final double x = i / (n - 1) * size.width;
      if (!started) {
        path.moveTo(x, y(v));
        started = true;
      } else {
        path.lineTo(x, y(v));
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round,
    );
    _crosshair(canvas, size, highlightIndex, n, line);
  }

  @override
  bool shouldRepaint(_RsiPainter old) =>
      old.values != values ||
      old.highlightIndex != highlightIndex ||
      old.color != color;
}

void _crosshair(Canvas canvas, Size size, int? index, int n, Color color) {
  if (index == null || index < 0 || index >= n) return;
  final double x = index / (n - 1) * size.width;
  final Paint paint = Paint()
    ..color = color.withAlpha(160)
    ..strokeWidth = 1;
  double yy = 0;
  while (yy < size.height) {
    canvas.drawLine(Offset(x, yy), Offset(x, (yy + 3).clamp(0, size.height)), paint);
    yy += 6;
  }
}
