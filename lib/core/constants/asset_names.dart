/// Display names for popular base assets.
///
/// Binance market data has no asset names, so this is a small bundled map used
/// for search ("bitcoin" finds BTC pairs) and the watchlist subtitle.
/// Unknown assets fall back to their ticker code.
abstract final class AssetNames {
  static const Map<String, String> _names = <String, String>{
    'BTC': 'Bitcoin',
    'ETH': 'Ethereum',
    'SOL': 'Solana',
    'BNB': 'BNB Chain',
    'XRP': 'XRP',
    'ADA': 'Cardano',
    'DOGE': 'Dogecoin',
    'AVAX': 'Avalanche',
    'NEAR': 'NEAR Protocol',
    'SUI': 'Sui',
    'PEPE': 'Pepe',
    'LINK': 'Chainlink',
    'DOT': 'Polkadot',
    'POL': 'Polygon',
    'LTC': 'Litecoin',
    'TRX': 'TRON',
    'ATOM': 'Cosmos',
    'UNI': 'Uniswap',
    'APT': 'Aptos',
    'ARB': 'Arbitrum',
    'OP': 'Optimism',
    'INJ': 'Injective',
    'TON': 'Toncoin',
    'SHIB': 'Shiba Inu',
    'FIL': 'Filecoin',
    'AAVE': 'Aave',
    'USDT': 'Tether',
    'FDUSD': 'First Digital USD',
    'EUR': 'Euro',
  };

  /// Full name or the code itself when unknown.
  static String nameOf(String asset) => _names[asset] ?? asset;

  /// Name only when known (used by search to avoid matching the code twice).
  static String? knownNameOf(String asset) => _names[asset];
}
