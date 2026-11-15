import 'package:equatable/equatable.dart';

import '../../../../shared/domain/entities/trading_pair.dart';

/// Sort key (typed constants instead of an enum).
class SortField extends Equatable {
  const SortField._(this.id, this.label, this._compare);

  final String id;
  final String label;
  final int Function(TradingPair a, TradingPair b) _compare;

  static const SortField volume = SortField._('volume', 'Volume', _byVolume);
  static const SortField price = SortField._('price', 'Price', _byPrice);
  static const SortField change = SortField._('change', '24h Change', _byChange);
  static const SortField name = SortField._('name', 'Name', _byName);

  static const List<SortField> all = <SortField>[volume, price, change, name];

  static int _byVolume(TradingPair a, TradingPair b) =>
      a.quoteVolume.compareTo(b.quoteVolume);
  static int _byPrice(TradingPair a, TradingPair b) =>
      a.lastPrice.compareTo(b.lastPrice);
  static int _byChange(TradingPair a, TradingPair b) =>
      a.priceChangePercent.compareTo(b.priceChangePercent);
  static int _byName(TradingPair a, TradingPair b) =>
      a.baseAsset.compareTo(b.baseAsset);

  /// Compares in natural ascending order for this field.
  int compare(TradingPair a, TradingPair b) => _compare(a, b);

  @override
  List<Object?> get props => <Object?>[id];
}

/// Gainers/losers filter (typed constants instead of an enum).
class MoveFilter extends Equatable {
  const MoveFilter._(this.id, this.label);
  final String id;
  final String label;

  static const MoveFilter none = MoveFilter._('all', 'All');
  static const MoveFilter gainers = MoveFilter._('gainers', 'Gainers');
  static const MoveFilter losers = MoveFilter._('losers', 'Losers');
  static const List<MoveFilter> all = <MoveFilter>[none, gainers, losers];

  @override
  List<Object?> get props => <Object?>[id];
}

/// Everything the Explore screen can ask of the list.
class ExploreQuery extends Equatable {
  const ExploreQuery({
    this.search = '',
    this.quoteAsset,
    this.move = MoveFilter.none,
    this.minQuoteVolume = 0,
    this.sortField,
    this.ascending = false,
  });

  /// Free text matched against symbol, base asset and display name.
  final String search;

  /// `null` = every quote asset.
  final String? quoteAsset;
  final MoveFilter move;
  final double minQuoteVolume;

  /// `null` -> [SortField.volume].
  final SortField? sortField;
  final bool ascending;

  ExploreQuery copyWith({
    String? search,
    String? quoteAsset,
    bool clearQuote = false,
    MoveFilter? move,
    double? minQuoteVolume,
    SortField? sortField,
    bool? ascending,
  }) {
    return ExploreQuery(
      search: search ?? this.search,
      quoteAsset: clearQuote ? null : (quoteAsset ?? this.quoteAsset),
      move: move ?? this.move,
      minQuoteVolume: minQuoteVolume ?? this.minQuoteVolume,
      sortField: sortField ?? this.sortField,
      ascending: ascending ?? this.ascending,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        search,
        quoteAsset,
        move,
        minQuoteVolume,
        sortField,
        ascending,
      ];
}
