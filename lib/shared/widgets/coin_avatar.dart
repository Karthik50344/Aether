import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// Round avatar with a text glyph (no network images: Binance supplies none).
/// Well-known assets get their symbol glyph, everything else its first letters.
class CoinAvatar extends StatelessWidget {
  const CoinAvatar({
    required this.baseAsset,
    this.size = 40,
    this.negative = false,
    this.tinted = false,
    super.key,
  });

  final String baseAsset;
  final double size;

  /// Red-tinted glyph (design uses it for assets that are down).
  final bool negative;

  /// Translucent tinted background (trend cards) instead of solid.
  final bool tinted;

  static const Map<String, String> _glyphs = <String, String>{
    'BTC': '₿',
    'ETH': 'Ξ',
    'ADA': '₳',
    'DOGE': 'Ð',
    'LTC': 'Ł',
  };

  static String glyphFor(String asset) {
    final String? g = _glyphs[asset];
    if (g != null) return g;
    final String a = asset.toUpperCase();
    return a.length <= 2 ? a : a.substring(0, 2);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final Color fg = negative ? p.negativeLight : p.primaryLight;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tinted ? fg.withAlpha(26) : p.surfaceHighest,
          shape: BoxShape.circle,
        ),
        child: Text(
          glyphFor(baseAsset),
          maxLines: 1,
          style: TextStyle(
            fontFamily: 'Inter',
            fontFamilyFallback: const <String>['serif'],
            fontWeight: FontWeight.w700,
            fontSize: size * 0.4,
            color: fg,
          ),
        ),
      ),
    );
  }
}
