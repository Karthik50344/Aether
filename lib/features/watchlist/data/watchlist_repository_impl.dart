import '../../../core/storage/key_value_store.dart';
import '../domain/repositories/watchlist_repository.dart';

/// Persists the watchlist as a string list. Corrupt or missing data reads as
/// an empty list; duplicates are dropped.
class WatchlistRepositoryImpl implements WatchlistRepository {
  WatchlistRepositoryImpl(this._store);

  static const String storageKey = 'watchlist_symbols_v1';
  final KeyValueStore _store;

  static String _norm(String s) => s.trim().toUpperCase();

  @override
  Future<List<String>> getSymbols() async {
    final List<String> raw =
        await _store.readStringList(storageKey) ?? const <String>[];
    final Set<String> seen = <String>{};
    return <String>[
      for (final String s in raw)
        if (s.trim().isNotEmpty && seen.add(_norm(s))) _norm(s),
    ];
  }

  @override
  Future<bool> contains(String symbol) async =>
      (await getSymbols()).contains(_norm(symbol));

  @override
  Future<bool> toggle(String symbol) async {
    final String s = _norm(symbol);
    final List<String> list = await getSymbols();
    final bool had = list.remove(s);
    if (!had) list.insert(0, s);
    await _store.writeStringList(storageKey, list);
    return !had;
  }

  @override
  Future<void> remove(String symbol) async {
    final List<String> list = await getSymbols()..remove(_norm(symbol));
    await _store.writeStringList(storageKey, list);
  }

  @override
  Future<void> reorder(int oldIndex, int newIndex) async {
    final List<String> list = await getSymbols();
    if (oldIndex < 0 || oldIndex >= list.length) return;
    // Flutter's ReorderableListView passes newIndex AFTER removal semantics.
    int target = newIndex;
    if (target > oldIndex) target -= 1;
    target = target.clamp(0, list.length - 1);
    final String item = list.removeAt(oldIndex);
    list.insert(target, item);
    await _store.writeStringList(storageKey, list);
  }
}
