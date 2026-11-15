import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/chart_indicator.dart';
import '../../domain/entities/chart_period.dart';
import '../../domain/entities/chart_series.dart';
import 'interactive_price_chart.dart';

/// Chart card: period selector, indicator toggles, and the chart itself with
/// its own loading / error states.
class ChartCard extends StatelessWidget {
  const ChartCard({
    required this.period,
    required this.indicators,
    required this.series,
    required this.loading,
    required this.failed,
    required this.quote,
    required this.onPeriod,
    required this.onToggle,
    required this.onRetry,
    this.now,
    super.key,
  });

  final ChartPeriod period;
  final Set<ChartIndicator> indicators;
  final ChartSeries? series;
  final bool loading;
  final bool failed;
  final String quote;
  final ValueChanged<ChartPeriod> onPeriod;
  final ValueChanged<ChartIndicator> onToggle;
  final VoidCallback onRetry;
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadii.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _PeriodSelector(selected: period, onSelected: onPeriod),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final ChartIndicator i in ChartIndicator.all)
                _IndicatorToggle(
                  indicator: i,
                  active: indicators.contains(i),
                  onTap: () => onToggle(i),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _body(context),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    final AppPalette p = context.palette;
    const double h = 224;
    if (loading) {
      return SizedBox(
        height: h,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: p.primary),
          ),
        ),
      );
    }
    final ChartSeries? s = series;
    if (failed || s == null) {
      return SizedBox(
        height: h,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Could not load the chart.',
                style: AppTypography.label.copyWith(color: p.textSecondary),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onRetry,
                child: Text('Retry',
                    style: AppTypography.labelStrong.copyWith(color: p.primaryLight)),
              ),
            ],
          ),
        ),
      );
    }
    return InteractivePriceChart(
      key: ValueKey<String>('chart-${period.id}'),
      series: s,
      interval: period.interval,
      indicators: indicators,
      quote: quote,
      // 1D shows the true 24h window; other ranges say "Period".
      highLowLabel: period == ChartPeriod.day1 ? '24h' : 'Period',
      now: now,
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onSelected});

  final ChartPeriod selected;
  final ValueChanged<ChartPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final ChartPeriod period in ChartPeriod.all)
          Semantics(
            button: true,
            selected: period == selected,
            label: 'Chart range ${period.label}',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(period),
              child: Container(
                constraints: const BoxConstraints(minHeight: 32, minWidth: 40),
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: period == selected ? p.surfaceHigh : Colors.transparent,
                  borderRadius: AppRadii.badgeRadius,
                ),
                child: Text(
                  period.label,
                  style: (period == selected
                          ? AppTypography.labelStrong
                          : AppTypography.label)
                      .copyWith(
                    color: period == selected ? p.primaryLight : p.textSecondary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _IndicatorToggle extends StatelessWidget {
  const _IndicatorToggle({
    required this.indicator,
    required this.active,
    required this.onTap,
  });

  final ChartIndicator indicator;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Semantics(
      button: true,
      selected: active,
      label: '${indicator.label} indicator',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 28),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? p.positiveBg : Colors.transparent,
            border: Border.all(color: active ? Colors.transparent : p.surfaceHighest),
            borderRadius: AppRadii.badgeRadius,
          ),
          child: Text(
            indicator.label,
            style: (active ? AppTypography.labelStrong : AppTypography.label)
                .copyWith(color: active ? p.positive : p.textSecondary),
          ),
        ),
      ),
    );
  }
}
