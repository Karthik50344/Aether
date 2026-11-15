import 'package:equatable/equatable.dart';

import '../../../../core/constants/quote_assets.dart';
import '../../../coin_details/domain/entities/chart_period.dart';
import 'theme_preference.dart';

/// User preferences (persisted locally).
class AppSettings extends Equatable {
  const AppSettings({
    this.theme = ThemePreference.defaultValue,
    this.defaultQuote = QuoteAssets.defaultQuote,
    this.defaultPeriod = ChartPeriod.defaultPeriod,
    this.compactMetrics = true,
  });

  final ThemePreference theme;

  /// Quote asset selected on Market and Explore.
  final String defaultQuote;

  /// Chart range a pair opens with.
  final ChartPeriod defaultPeriod;

  /// `$1.2B` (true) vs `$1,200,000,000` (false).
  final bool compactMetrics;

  /// Quote assets offered in Settings (all are real Binance quote assets).
  static const List<String> quoteOptions = <String>[
    QuoteAssets.usdt,
    QuoteAssets.btc,
    QuoteAssets.fdusd,
    QuoteAssets.eur,
  ];

  AppSettings copyWith({
    ThemePreference? theme,
    String? defaultQuote,
    ChartPeriod? defaultPeriod,
    bool? compactMetrics,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      defaultQuote: defaultQuote ?? this.defaultQuote,
      defaultPeriod: defaultPeriod ?? this.defaultPeriod,
      compactMetrics: compactMetrics ?? this.compactMetrics,
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[theme, defaultQuote, defaultPeriod, compactMetrics];
}
