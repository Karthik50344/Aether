abstract final class RoutePaths {
  static const String market = '/market';
  static const String explore = '/explore';
  static const String watchlist = '/watchlist';
  static const String settings = '/settings';
  static const String pairDetails = '/pair/:symbol';
  static const String privacy = '/privacy';

  static String pair(String symbol) => '/pair/$symbol';
}

abstract final class RouteNames {
  static const String market = 'market';
  static const String explore = 'explore';
  static const String watchlist = 'watchlist';
  static const String settings = 'settings';
  static const String pairDetails = 'pairDetails';
  static const String privacy = 'privacy';
}
