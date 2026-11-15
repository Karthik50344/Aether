import 'package:aether_app/core/storage/key_value_store.dart';
import 'package:aether_app/features/watchlist/data/watchlist_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryStore store;
  late WatchlistRepositoryImpl repo;

  setUp(() {
    store = InMemoryStore();
    repo = WatchlistRepositoryImpl(store);
  });

  test('starts empty', () async {
    expect(await repo.getSymbols(), isEmpty);
    expect(await repo.contains('BTCUSDT'), isFalse);
  });

  test('toggle adds (newest first), normalises case, and removes', () async {
    expect(await repo.toggle('btcusdt'), isTrue);
    expect(await repo.toggle('ETHUSDT'), isTrue);
    expect(await repo.getSymbols(), ['ETHUSDT', 'BTCUSDT']);
    expect(await repo.contains('BtcUsdt'), isTrue);

    expect(await repo.toggle('BTCUSDT'), isFalse);
    expect(await repo.getSymbols(), ['ETHUSDT']);
  });

  test('persists through a new repository on the same store', () async {
    await repo.toggle('SOLUSDT');
    expect(await WatchlistRepositoryImpl(store).getSymbols(), ['SOLUSDT']);
  });

  test('drops blanks and duplicates from stored data', () async {
    await store.writeStringList(
        WatchlistRepositoryImpl.storageKey, ['BTCUSDT', ' ', 'btcusdt', 'ETHUSDT']);
    expect(await repo.getSymbols(), ['BTCUSDT', 'ETHUSDT']);
  });

  test('remove ignores unknown symbols', () async {
    await repo.toggle('BTCUSDT');
    await repo.remove('NOPE');
    await repo.remove('BTCUSDT');
    expect(await repo.getSymbols(), isEmpty);
  });

  test('reorder follows ReorderableListView index semantics', () async {
    for (final s in ['C', 'B', 'A']) {
      await repo.toggle(s); // list becomes A, B, C
    }
    expect(await repo.getSymbols(), ['A', 'B', 'C']);
    await repo.reorder(0, 3); // drag A to the end
    expect(await repo.getSymbols(), ['B', 'C', 'A']);
    await repo.reorder(2, 0); // drag A back to the start
    expect(await repo.getSymbols(), ['A', 'B', 'C']);
    await repo.reorder(9, 0); // out of range: no change
    expect(await repo.getSymbols(), ['A', 'B', 'C']);
  });
}
