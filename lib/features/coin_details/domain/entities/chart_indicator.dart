/// Chart overlays/panels the user can toggle (typed constants, not an enum).
///
/// Deliberately NOT Equatable: the constants are canonical, so identity
/// equality is correct, and a type that overrides `==` cannot be an element of
/// a `const` Set (used as a default in CoinDetailsState).
class ChartIndicator {
  const ChartIndicator._(this.id, this.label);
  final String id;
  final String label;

  /// 7-period simple moving average of closes, drawn on the price line.
  static const ChartIndicator ma7 = ChartIndicator._('ma7', 'MA(7)');

  /// Volume bars under the price line.
  static const ChartIndicator volume = ChartIndicator._('vol', 'VOL');

  /// 14-period RSI (Wilder) panel.
  static const ChartIndicator rsi = ChartIndicator._('rsi', 'RSI');

  static const List<ChartIndicator> all = <ChartIndicator>[ma7, volume, rsi];
}
