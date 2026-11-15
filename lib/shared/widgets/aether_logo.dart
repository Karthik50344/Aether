import 'package:flutter/material.dart';

/// The Aether mark: an "A" whose crossbar is a rising price line that breaks
/// out through the right leg and ends in a dot.
///
/// Drawn in code (no image or SVG dependency). The geometry is identical to
/// `tool/generate_branding.py`, which produces the launcher / splash images,
/// so the in-app mark and the app icon always match.
///
/// [tile] paints the dark rounded-square app-icon tile behind the glyph.
class AetherLogo extends StatelessWidget {
  const AetherLogo({this.size = 32, this.tile = false, super.key});

  final double size;
  final bool tile;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Aether logo',
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _LogoPainter(tile: tile)),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter({required this.tile});
  final bool tile;

  static const Color _light = Color(0xFFBAC3FF);
  static const Color _deep = Color(0xFF6F82FF);
  static const Color _tileColor = Color(0xFF0D131E);

  static const List<Offset> _legs = <Offset>[
    Offset(26, 76),
    Offset(50, 24),
    Offset(74, 76),
  ];
  static const List<Offset> _line = <Offset>[
    Offset(46, 67),
    Offset(51, 62),
    Offset(56, 65),
    Offset(68, 50),
    Offset(81, 34),
  ];
  static const Offset _dot = Offset(81, 34);
  static const double _dotRadius = 5.5;

  Path _path(List<Offset> pts, double s) {
    final Path p = Path()..moveTo(pts.first.dx * s, pts.first.dy * s);
    for (final Offset o in pts.skip(1)) {
      p.lineTo(o.dx * s, o.dy * s);
    }
    return p;
  }

  Paint _stroke(double width, double s) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width * s
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide / 100;
    final Rect bounds = Offset.zero & size;

    if (tile) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(bounds, Radius.circular(22 * s)),
        Paint()..color = _tileColor,
      );
    }

    // Legs, with the crossbar's cut-out gap punched through them.
    canvas.saveLayer(bounds, Paint());
    canvas.drawPath(
      _path(_legs, s),
      _stroke(8, s)
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[_light, _deep],
        ).createShader(Rect.fromLTWH(26 * s, 24 * s, 48 * s, 52 * s)),
    );
    final Paint clear = Paint()..blendMode = BlendMode.clear;
    canvas.drawPath(
      _path(_line, s),
      _stroke(14, s)..blendMode = BlendMode.clear,
    );
    canvas.drawCircle(_dot * s, (_dotRadius + 4) * s, clear);
    canvas.restore();

    // The price line and its end dot.
    canvas.drawPath(_path(_line, s), _stroke(5, s)..color = _light);
    canvas.drawCircle(_dot * s, _dotRadius * s, Paint()..color = _light);
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.tile != tile;
}
