import '../../domain/entities/explore_query.dart';

/// Short UI labels for sort fields on the Explore screen.
abstract final class ExploreLabels {
  static String sort(SortField f) {
    if (f == SortField.volume) return 'Vol';
    if (f == SortField.price) return 'Price';
    if (f == SortField.change) return '24h Chg';
    return 'Name';
  }
}
