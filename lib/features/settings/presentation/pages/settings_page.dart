import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/info/app_info.dart';
import '../../../../core/state/load_status.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../coin_details/domain/entities/chart_period.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/theme_preference.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/telemetry_bloc.dart';
import '../../../../shared/widgets/aether_logo.dart';
import '../widgets/settings_section.dart';

/// Settings tab (Figma 3:1218). Every control is wired:
/// theme, default quote, default timeframe and compact metrics are persisted
/// and applied app-wide; telemetry measures the real REST ping.
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.appInfo,
    required this.refreshPolicy,
    required this.dataSourceLabel,
    super.key,
  });

  final AppInfo appInfo;
  final RefreshPolicy refreshPolicy;

  /// "Sample data (offline JSON)" or "Binance Spot REST".
  final String dataSourceLabel;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (BuildContext context, SettingsState state) {
        final AppSettings s = state.settings;
        final SettingsBloc bloc = context.read<SettingsBloc>();
        return ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen, AppSpacing.xl, AppSpacing.screen, 32,),
          children: <Widget>[
            Text('Settings',
                style: AppTypography.heroValue
                    .copyWith(color: p.textPrimary, fontSize: 28),),
            const SizedBox(height: 16),
            _AppCard(info: appInfo),
            const SizedBox(height: 20),
            SettingsSection(
              title: 'Terminal Preferences',
              children: <Widget>[
                const SettingsRow(label: 'Theme', hint: 'Dark is the reference design'),
                SegmentRow<ThemePreference>(
                  options: ThemePreference.all,
                  selected: s.theme,
                  labelOf: (ThemePreference t) => t.label,
                  onSelected: (ThemePreference t) => bloc.add(ThemeChanged(t)),
                ),
                const SettingsRow(
                    label: 'Default Quote Asset',
                    hint: 'Pre-selected on Market and Explore',),
                SegmentRow<String>(
                  options: AppSettings.quoteOptions,
                  selected: s.defaultQuote,
                  labelOf: (String q) => q,
                  onSelected: (String q) => bloc.add(DefaultQuoteChanged(q)),
                ),
                SettingsRow(
                  label: 'Default Timeframe',
                  hint: 'Chart range a pair opens with',
                  trailing: DropdownButton<ChartPeriod>(
                    value: s.defaultPeriod,
                    underline: const SizedBox.shrink(),
                    dropdownColor: p.surfaceHigh,
                    items: <DropdownMenuItem<ChartPeriod>>[
                      for (final ChartPeriod c in ChartPeriod.all)
                        DropdownMenuItem<ChartPeriod>(
                            value: c, child: Text(c.label),),
                    ],
                    onChanged: (ChartPeriod? c) {
                      if (c != null) bloc.add(DefaultPeriodChanged(c));
                    },
                  ),
                ),
                SettingsRow(
                  label: 'Compact Metrics',
                  hint: s.compactMetrics ? r'e.g. $1.2B' : r'e.g. $1,200,000,000',
                  trailing: Switch(
                    value: s.compactMetrics,
                    onChanged: (bool v) =>
                        bloc.add(CompactMetricsChanged(compact: v)),
                  ),
                ),
                if (state.persistFailed)
                  SettingsRow(
                    label: 'Could not save settings',
                    hint: 'Changes apply now but may not survive a restart.',
                    trailing: Icon(Icons.warning_amber, color: p.negativeLight),
                  ),
              ],
            ),
            _TelemetrySection(
              dataSourceLabel: dataSourceLabel,
              refreshPolicy: refreshPolicy,
            ),
            SettingsSection(
              title: 'Research Policy',
              children: <Widget>[
                SettingsRow(
                  label: 'Privacy',
                  trailing: Icon(Icons.chevron_right, color: p.textSecondary),
                  onTap: () => context.push(RoutePaths.privacy),
                ),
                SettingsRow(
                  label: 'Open Source Licenses',
                  trailing: Icon(Icons.chevron_right, color: p.textSecondary),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: appInfo.name,
                    applicationVersion: appInfo.version,
                  ),
                ),
                SettingsRow(
                  label: 'Build',
                  trailing: Text(appInfo.full,
                      style: AppTypography.label.copyWith(color: p.textSecondary),),
                ),
              ],
            ),
            Text(
              'Strictly local research tool. Market data comes from Binance '
              'Spot public endpoints. No account login or custody required.',
              textAlign: TextAlign.center,
              style: AppTypography.label.copyWith(color: p.textSecondary),
            ),
          ],
        );
      },
    );
  }
}

class _AppCard extends StatelessWidget {
  const _AppCard({required this.info});
  final AppInfo info;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: p.surface, borderRadius: AppRadii.cardRadius),
      child: Row(
        children: <Widget>[
          const AetherLogo(size: 48, tile: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Aether Crypto Terminal',
                    style: AppTypography.sectionTitle.copyWith(color: p.textPrimary),),
                const SizedBox(height: 2),
                Text('Version ${info.version} (${info.buildNumber})',
                    style: AppTypography.label.copyWith(color: p.textSecondary),),
                const SizedBox(height: 4),
                BlocBuilder<TelemetryBloc, TelemetryState>(
                  builder: (BuildContext context, TelemetryState t) {
                    final bool ok = t.status == LoadStatus.success;
                    final bool bad = t.status == LoadStatus.failure;
                    final Color c = ok ? p.positive : (bad ? p.negativeLight : p.textSecondary);
                    final String text = ok
                        ? 'Operational · ${t.latency!.inMilliseconds} ms'
                        : bad
                            ? 'Unreachable'
                            : 'Checking…';
                    return Text('● $text',
                        style: AppTypography.labelStrong.copyWith(color: c),);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TelemetrySection extends StatelessWidget {
  const _TelemetrySection({
    required this.dataSourceLabel,
    required this.refreshPolicy,
  });
  final String dataSourceLabel;
  final RefreshPolicy refreshPolicy;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return BlocConsumer<TelemetryBloc, TelemetryState>(
      listenWhen: (TelemetryState a, TelemetryState b) =>
          a.clearedCount != b.clearedCount,
      listener: (BuildContext context, TelemetryState s) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('Cache cleared. Data reloaded.')),
        );
      },
      builder: (BuildContext context, TelemetryState t) {
        final String latency = t.status == LoadStatus.failure
            ? 'Unreachable'
            : t.latency == null
                ? '…'
                : '${t.latency!.inMilliseconds} ms'
                    '${t.average != null ? ' (avg ${t.average!.inMilliseconds} ms)' : ''}';
        final TelemetryBloc bloc = context.read<TelemetryBloc>();
        return SettingsSection(
          title: 'Exchange Telemetry',
          children: <Widget>[
            SettingsRow(
              label: 'Binance Spot Public API',
              hint: 'Market data only · no keys',
              trailing: Icon(
                t.status == LoadStatus.failure ? Icons.cloud_off : Icons.cloud_done,
                color: t.status == LoadStatus.failure ? p.negativeLight : p.positive,
              ),
            ),
            SettingsRow(
              label: 'REST Ping Latency',
              hint: 'Tap to measure again',
              onTap: () => bloc.add(const TelemetryPinged()),
              trailing: Text(latency,
                  style: AppTypography.valueMedium.copyWith(color: p.textPrimary),),
            ),
            SettingsRow(
              label: 'Polling Interval',
              trailing: Text(refreshPolicy.label,
                  style: AppTypography.label.copyWith(color: p.textSecondary),),
            ),
            SettingsRow(
              label: 'Data Source',
              trailing: Text(dataSourceLabel,
                  style: AppTypography.label.copyWith(color: p.textSecondary),),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: t.clearing
                      ? null
                      : () => bloc.add(const CacheClearRequested()),
                  child: Text(t.clearing
                      ? 'Resetting…'
                      : 'Clear Cache & Reset Datafeed',),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
