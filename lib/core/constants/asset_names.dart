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

  static String nameOf(String asset) => _names[asset] ?? asset;
  static String? knownNameOf(String asset) => _names[asset];
}
