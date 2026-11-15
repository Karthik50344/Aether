import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// Tiny dependency-free line chart. Fewer than two points draws a dashed flat
/// line, so a missing series never breaks the layout.
class Sparkline extends StatelessWidget {
  const Sparkline({
    required this.values,
    required this.positive,
    this.width = double.infinity,
    this.height = 28,
    super.key,
  });

  final List<double> values;
  final bool positive;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: SparklinePainter(
            values: values,
            color: positive ? p.positive : p.negative,
            placeholder: p.surfaceHighest,
          ),
        ),
      ),
    );
  }
}

class SparklinePainter extends CustomPainter {
  SparklinePainter({
    required this.values,
    required this.color,
    required this.placeholder,
  });

  final List<double> values;
  final Color color;
  final Color placeholder;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    if (values.length < 2) {
      _dashed(canvas, size);
      return;
    }
    double lo = values.first;
    double hi = values.first;
    for (final double v in values) {
      if (v < lo) lo = v;
      if (v > hi) hi = v;
    }
    final double range = hi - lo;
    const double pad = 2;
    final double h = size.height - pad * 2;
    final Path path = Path();
    for (int i = 0; i < values.length; i++) {
      final double x = size.width * i / (values.length - 1);
      final double t = range == 0 ? 0.5 : (values[i] - lo) / range;
      final double y = pad + h * (1 - t);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _dashed(Canvas canvas, Size size) {
    final Path line = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width, size.height / 2);
    final Paint paint = Paint()
      ..color = placeholder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final PathMetric m in line.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 4), paint);
        d += 8;
      }
    }
  }

  @override
  bool shouldRepaint(SparklinePainter old) =>
      old.color != color || old.values != values;
}
