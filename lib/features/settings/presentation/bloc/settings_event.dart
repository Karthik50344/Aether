import 'package:equatable/equatable.dart';

import '../../../coin_details/domain/entities/chart_period.dart';
import '../../domain/entities/theme_preference.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => const <Object?>[];
}

final class ThemeChanged extends SettingsEvent {
  const ThemeChanged(this.theme);
  final ThemePreference theme;
  @override
  List<Object?> get props => <Object?>[theme];
}

final class DefaultQuoteChanged extends SettingsEvent {
  const DefaultQuoteChanged(this.quote);
  final String quote;
  @override
  List<Object?> get props => <Object?>[quote];
}

final class DefaultPeriodChanged extends SettingsEvent {
  const DefaultPeriodChanged(this.period);
  final ChartPeriod period;
  @override
  List<Object?> get props => <Object?>[period];
}

final class CompactMetricsChanged extends SettingsEvent {
  const CompactMetricsChanged({required this.compact});
  final bool compact;
  @override
  List<Object?> get props => <Object?>[compact];
}
