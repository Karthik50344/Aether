/// App-curated sector tags. Binance exposes NO category data, so this is a
/// small hand-maintained list of well-known base assets. It is labelled as
/// "app-curated" in the UI and only covers assets listed here.
class Sector {
  const Sector._(this.id, this.label, this._assets);

  final String id;
  final String label;
  final Set<String> _assets;

  /// Matches every pair.
  static const Sector all = Sector._('all', 'All', <String>{});

  static const Sector layer1 = Sector._('layer1', 'Layer 1', <String>{
    'BTC', 'ETH', 'SOL', 'BNB', 'ADA', 'AVAX', 'NEAR', 'DOT', 'ATOM', 'TRX',
    'SUI', 'APT', 'ALGO', 'XRP', 'LTC', 'ICP', 'FIL', 'TON', 'XLM', 'ETC',
    'BCH', 'HBAR', 'EGLD', 'FTM', 'SEI',
  });
  static const Sector defi = Sector._('defi', 'DeFi', <String>{
    'UNI', 'AAVE', 'LINK', 'MKR', 'CRV', 'LDO', 'COMP', 'SNX', 'SUSHI',
    'DYDX', 'CAKE', 'INJ', 'RUNE', '1INCH',
  });
  static const Sector aiData = Sector._('ai', 'AI & Data', <String>{
    'FET', 'RENDER', 'RNDR', 'TAO', 'GRT', 'AGIX', 'OCEAN', 'WLD', 'AKT',
    'ARKM', 'NMR',
  });
  static const Sector layer2 = Sector._('layer2', 'Layer 2', <String>{
    'MATIC', 'POL', 'ARB', 'OP', 'IMX', 'STRK', 'MANTA', 'METIS', 'ZK',
    'LRC', 'BLAST',
  });
  static const Sector meme = Sector._('meme', 'Meme', <String>{
    'DOGE', 'SHIB', 'PEPE', 'FLOKI', 'BONK', 'WIF', '1000PEPE', '1000SHIB',
    'BOME', 'MEME',
  });

  /// Display order (matches Figma: All, Layer 1, DeFi, AI & Data, Layer 2, Meme).
  static const List<Sector> values = <Sector>[
    all, layer1, defi, aiData, layer2, meme,
  ];

  static Sector fromId(String? id) {
    for (final Sector s in values) {
      if (s.id == id) return s;
    }
    return all;
  }

  /// True when [baseAsset] belongs to this sector ([all] accepts everything).
  bool contains(String baseAsset) =>
      identical(this, all) || _assets.contains(baseAsset);
}
