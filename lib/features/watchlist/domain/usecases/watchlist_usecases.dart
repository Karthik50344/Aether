import '../repositories/watchlist_repository.dart';

class IsInWatchlist {
  const IsInWatchlist(this._repository);
  final WatchlistRepository _repository;
  Future<bool> call(String symbol) => _repository.contains(symbol);
}

/// Returns `true` when the symbol is in the watchlist afterwards.
class ToggleWatchlist {
  const ToggleWatchlist(this._repository);
  final WatchlistRepository _repository;
  Future<bool> call(String symbol) => _repository.toggle(symbol);
}

class GetWatchlist {
  const GetWatchlist(this._repository);
  final WatchlistRepository _repository;
  Future<List<String>> call() => _repository.getSymbols();
}

class RemoveFromWatchlist {
  const RemoveFromWatchlist(this._repository);
  final WatchlistRepository _repository;
  Future<void> call(String symbol) => _repository.remove(symbol);
}

class AddToWatchlist {
  const AddToWatchlist(this._repository);
  final WatchlistRepository _repository;

  /// Adds only when absent (never toggles an existing entry off).
  Future<void> call(String symbol) async {
    if (!await _repository.contains(symbol)) await _repository.toggle(symbol);
  }
}

class ReorderWatchlist {
  const ReorderWatchlist(this._repository);
  final WatchlistRepository _repository;
  Future<void> call(int oldIndex, int newIndex) =>
      _repository.reorder(oldIndex, newIndex);
}
