/// The user's saved symbols, in their chosen order (newest first on add).
abstract interface class WatchlistRepository {
  Future<List<String>> getSymbols();
  Future<bool> contains(String symbol);

  /// Adds or removes [symbol]; returns `true` when it is now in the list.
  Future<bool> toggle(String symbol);
  Future<void> remove(String symbol);
  Future<void> reorder(int oldIndex, int newIndex);
}
