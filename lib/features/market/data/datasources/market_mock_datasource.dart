import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../../core/errors/app_exception.dart';
import '../models/depth_model.dart';
import '../models/kline_model.dart';
import '../models/recent_trade_model.dart';
import '../models/symbol_info_model.dart';
import '../models/ticker_24hr_model.dart';
import 'market_datasource.dart';

/// Moment the generated mock data ends. MUST match `ANCHOR` in
/// tool/generate_mock_data.py.
final DateTime kMockAnchor = DateTime.utc(2026, 11, 14, 12);

/// Loads a text asset (injectable so tests can read files directly).
typedef AssetTextLoader = Future<String> Function(String path);

/// Current time (injectable for deterministic tests).
typedef Clock = DateTime Function();

/// Data source backed by the JSON files in `assets/mock/`.
///
/// The files use the exact shape of the Binance responses and are parsed by
/// the same models as the remote source. Timestamps are shifted by whole days
/// so the newest candle is always within 24 h of "now" while staying aligned
/// to UTC candle boundaries. All values are SAMPLE data, not market data.
class MarketMockDataSource implements MarketDataSource {
  MarketMockDataSource({AssetTextLoader? loadText, Clock? now})
      : _loadText = loadText ?? rootBundle.loadString,
        _now = now ?? DateTime.now;

  final AssetTextLoader _loadText;
  final Clock _now;
  final Map<String, Future<Object?>> _cache = <String, Future<Object?>>{};

  static const String _dir = 'assets/mock';

  /// Fixed, clearly-fake latency so the UI can show a value in mock mode.
  static const Duration mockLatency = Duration(milliseconds: 24);

  @override
  Future<Duration> ping() async => mockLatency;

  @override
  Future<List<SymbolInfoModel>> fetchSymbols() async =>
      SymbolInfoModel.parseExchangeInfo(await _read('trading_pairs.json'));

  @override
  Future<List<Ticker24hrModel>> fetchTickers() async =>
      Ticker24hrModel.parseList(await _read('ticker_24hr.json'));

  @override
  Future<List<KlineModel>> fetchKlines({
    required String symbol,
    required String interval,
    required int limit,
  }) async {
    final Map<String, dynamic> bySymbol =
        _asMap(await _read('klines.json'), 'klines.json');
    final Object? series = bySymbol[symbol];
    if (series is! Map<String, dynamic>) {
      throw NotFoundException('No sample candles for $symbol.');
    }
    final Object? rows = series[interval];
    if (rows is! List<dynamic>) {
      throw NotFoundException('No sample $interval candles for $symbol.');
    }
    final int shift = _shiftMs;
    final List<dynamic> recent = _lastN(rows, limit);
    return KlineModel.parseList(<dynamic>[
      for (final Object? row in recent)
        if (row is List<dynamic> && row.length >= 8)
          <dynamic>[
            (row[0] as int) + shift,
            ...row.sublist(1, 6),
            (row[6] as int) + shift,
            ...row.sublist(7),
          ],
    ]);
  }

  @override
  Future<List<RecentTradeModel>> fetchRecentTrades({
    required String symbol,
    required int limit,
  }) async {
    final Map<String, dynamic> bySymbol =
        _asMap(await _read('recent_trades.json'), 'recent_trades.json');
    final Object? rows = bySymbol[symbol];
    if (rows is! List<dynamic>) {
      throw NotFoundException('No sample trades for $symbol.');
    }
    final int shift = _shiftMs;
    return RecentTradeModel.parseList(<dynamic>[
      for (final Object? row in _lastN(rows, limit))
        if (row is Map<String, dynamic> && row['time'] is int)
          <String, dynamic>{...row, 'time': (row['time'] as int) + shift},
    ]);
  }

  @override
  Future<DepthModel> fetchDepth({
    required String symbol,
    required int limit,
  }) async {
    final Map<String, dynamic> bySymbol =
        _asMap(await _read('depth.json'), 'depth.json');
    final Object? book = bySymbol[symbol];
    if (book is! Map<String, dynamic>) {
      throw NotFoundException('No sample order book for $symbol.');
    }
    List<dynamic> firstN(Object? levels) => levels is List<dynamic>
        ? (levels.length > limit ? levels.sublist(0, limit) : levels)
        : <dynamic>[];
    return DepthModel.parse(<String, dynamic>{
      'lastUpdateId': book['lastUpdateId'],
      'bids': firstN(book['bids']),
      'asks': firstN(book['asks']),
    });
  }

  // --- helpers -------------------------------------------------------------

  /// Whole-day shift (ms) that moves [kMockAnchor] to the latest day <= now.
  int get _shiftMs {
    final int diff =
        _now().toUtc().difference(kMockAnchor).inMilliseconds;
    return (diff / Duration.millisecondsPerDay).floor() *
        Duration.millisecondsPerDay;
  }

  static List<dynamic> _lastN(List<dynamic> rows, int limit) {
    if (limit <= 0) return <dynamic>[];
    return rows.length > limit ? rows.sublist(rows.length - limit) : rows;
  }

  static Map<String, dynamic> _asMap(Object? json, String file) {
    if (json is Map<String, dynamic>) return json;
    throw ParseException('Sample file $file has an unexpected shape.');
  }

  Future<Object?> _read(String file) async {
    final Future<Object?>? hit = _cache[file];
    if (hit != null) return hit;
    final Future<Object?> pending = _load(file);
    _cache[file] = pending;
    try {
      return await pending;
    } catch (_) {
      _cache.remove(file); // allow a retry
      rethrow;
    }
  }

  Future<Object?> _load(String file) async {
    try {
      return jsonDecode(await _loadText('$_dir/$file'));
    } on FormatException {
      throw ParseException('Sample file $file is not valid JSON.');
    }
  }
}
