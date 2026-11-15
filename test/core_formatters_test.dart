import 'package:aether_app/core/formatters/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('volume formats compact and full', () {
    expect(Fmt.volume(12.4e9), '12.4B');
    expect(Fmt.volume(680e6), '680M');
    expect(Fmt.volume(3.9e3), '3.9K');
    expect(Fmt.volume(12400000000, compact: false), '12,400,000,000');
  });

  test('price precision adapts to magnitude', () {
    expect(Fmt.price(67420.5), '67,420.50');
    expect(Fmt.price(178.45), '178.45');
    expect(Fmt.price(7.32), '7.3200');
    expect(Fmt.price(0.0523), '0.052300');
    expect(Fmt.price(0.0000104), '0.00001040');
  });

  test('pricedIn prefixes dollar quotes only', () {
    expect(Fmt.pricedIn(67420.5, 'USDT'), '\$67,420.50');
    expect(Fmt.pricedIn(0.052, 'BTC'), '0.052000');
  });

  test('percent keeps explicit sign', () {
    expect(Fmt.percent(3.42), '+3.42%');
    expect(Fmt.percent(-2.1), '-2.10%');
    expect(Fmt.percent(0), '0.00%');
  });

  test('quoteAmount uses \$ for stablecoins and the ticker otherwise', () {
    expect(Fmt.quoteAmount(12.4e9, 'USDT'), '\$12.4B');
    expect(Fmt.quoteAmount(1200, 'BTC'), '1.2K BTC');
  });

  test('signed amounts and UTC time labels', () {
    expect(Fmt.signedAmount(2231.8, 'USDT'), '+\$2,231.80');
    expect(Fmt.signedAmount(-12, 'USDT'), '-\$12.00');
    expect(Fmt.signedAmount(0.0012, 'BTC'), '+0.001200');
    final t = DateTime.utc(2026, 11, 14, 14, 42, 1);
    expect(Fmt.clockSeconds(t), '14:42:01');
    expect(Fmt.chartAxis(t, '15m'), '14:42');
    expect(Fmt.chartAxis(t, '4h'), 'Nov 14');
    expect(Fmt.chartStamp(t, now: DateTime.utc(2026, 11, 14, 20)),
        'Today, 14:42 UTC',);
    expect(Fmt.chartStamp(t, now: DateTime.utc(2026, 11, 16)),
        'Nov 14, 14:42 UTC',);
  });

  test('ago', () {
    final now = DateTime.utc(2026, 1, 1, 12);
    expect(Fmt.ago(now.subtract(const Duration(seconds: 5)), now), '5s ago');
    expect(Fmt.ago(now.subtract(const Duration(minutes: 3)), now), '3m ago');
  });
}
