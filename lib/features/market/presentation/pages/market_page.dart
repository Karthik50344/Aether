import '../../../../shared/ui/settings_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../shared/domain/entities/trading_pair.dart';
import '../../../../shared/widgets/ago_text.dart';
import '../../../explore/domain/entities/explore_query.dart';
import '../bloc/market_bloc.dart';
import '../widgets/market_overview_card.dart';
import '../widgets/sector_chips.dart';
import '../widgets/sort_menu_button.dart';
import '../widgets/spot_market_tile.dart';
import '../widgets/status_strip.dart';
import '../widgets/trend_card.dart';
import '../widgets/trend_tabs.dart';

/// Market dashboard. Requires a [MarketBloc] above it (provided by the router).
class MarketPage extends StatelessWidget {
  const MarketPage({this.sourceLabel = 'SPOT', super.key});

  /// Right side of the status strip ("SAMPLE DATA" in mock mode).
  final String sourceLabel;

  /// Rows shown before the "See all" button.
  static const int visibleRows = 20;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: BlocBuilder<MarketBloc, MarketState>(
        builder: (BuildContext context, MarketState state) {
          if (state.isLoading && !state.hasData) {
            return const _DashboardSkeleton();
          }
          if (state.hasFailed && !state.hasData) {
            return AppErrorView(
              message: state.errorMessage ?? 'Could not load markets.',
              onRetry: () =>
                  context.read<MarketBloc>().add(const MarketRetryRequested()),
            );
          }
          return _Content(state: state, sourceLabel: sourceLabel);
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.state, required this.sourceLabel});

  final MarketState state;
  final String sourceLabel;

  void _openPair(BuildContext context, TradingPair p) =>
      context.push(RoutePaths.pair(p.symbol));

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final MarketBloc bloc = context.read<MarketBloc>();
    final List<String> quotes =
        state.availableQuotes.isEmpty ? <String>[state.quote] : state.availableQuotes;
    final List<TradingPair> rows =
        state.listPairs.take(MarketPage.visibleRows).toList();

    return RefreshIndicator(
      color: p.primary,
      backgroundColor: p.surfaceHigh,
      onRefresh: () async {
        bloc.add(const MarketRefreshed());
        // Complete when the bloc finishes refreshing.
        await bloc.stream.firstWhere((MarketState s) => !s.refreshing);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.md, AppSpacing.screen, AppSpacing.xxl,),
        children: <Widget>[
          StatusStrip(
            latency: state.latency,
            stale: state.refreshFailed,
            sourceLabel: sourceLabel,
          ),
          if (state.refreshFailed) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            _StaleBanner(
              message: state.errorMessage ?? 'Refresh failed.',
              onRetry: () => bloc.add(const MarketRefreshed()),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (state.overview != null)
            MarketOverviewCard(
 compact: SettingsScope.compactOf(context),
              overview: state.overview!,
              quotes: quotes,
              onQuoteSelected: (String q) => bloc.add(MarketQuoteSelected(q)),
            ),
          const SizedBox(height: 6),
          const OverviewFootnote(),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: <Widget>[
              TrendTabs(
                selected: state.trend,
                onSelected: (TrendKind k) => bloc.add(MarketTrendSelected(k)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AgoText(
                    since: state.lastUpdated,
                    style: AppTypography.label
                        .copyWith(color: p.textSecondary, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _TrendScroller(state: state, onOpen: (TradingPair t) => _openPair(context, t)),
          const SizedBox(height: AppSpacing.xl),
          SectorChips(
            selected: state.sector,
            counts: state.sectorCounts,
            onSelected: (s) => bloc.add(MarketSectorSelected(s.id)),
          ),
          const SizedBox(height: 4),
          Text(
            'Sector tags are app-curated, not Binance data.',
            style: AppTypography.label.copyWith(color: p.textSecondary, fontSize: 10),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Spot Markets',
                  style: AppTypography.sectionTitle.copyWith(color: p.textPrimary),
                ),
              ),
              SortMenuButton(
                field: state.sortField ?? SortField.volume,
                ascending: state.ascending,
                onChanged: (SortField f, bool asc) =>
                    bloc.add(MarketSortChanged(f, ascending: asc)),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: AppSpacing.touchTarget,
                height: AppSpacing.touchTarget,
                child: IconButton(
                  tooltip: 'Filter in Explore',
                  onPressed: () => context.go(RoutePaths.explore),
                  icon: Icon(AppIcons.filter, size: 18, color: p.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: AppEmptyView(
                title: 'No pairs here',
                message: 'No pairs match this sector for the selected quote asset.',
                icon: Icons.search_off,
              ),
            )
          else
            for (final TradingPair pair in rows) ...<Widget>[
              SpotMarketTile(
 compact: SettingsScope.compactOf(context),pair: pair, onTap: () => _openPair(context, pair),),
              const SizedBox(height: AppSpacing.rowGap),
            ],
          if (state.listPairs.length > MarketPage.visibleRows)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: OutlinedButton(
                onPressed: () => context.go(RoutePaths.explore),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  foregroundColor: p.primaryLight,
                  side: BorderSide(color: p.surfaceHighest),
                  shape: const RoundedRectangleBorder(
                      borderRadius: AppRadii.cardRadius,),
                ),
                child: Text(
                  'See all ${state.listPairs.length} pairs in Explore',
                  style: AppTypography.label.copyWith(color: p.primaryLight),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrendScroller extends StatelessWidget {
  const _TrendScroller({required this.state, required this.onOpen});

  final MarketState state;
  final ValueChanged<TradingPair> onOpen;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    if (state.trendPairs.isEmpty) {
      return Container(
        height: 118,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: AppRadii.cardRadius,
        ),
        child: Text(
          'No ${state.trend.label.toLowerCase()} for ${state.quote} right now.',
          style: AppTypography.label.copyWith(color: p.textSecondary),
        ),
      );
    }
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: state.trendPairs.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (BuildContext context, int i) {
          final TradingPair pair = state.trendPairs[i];
          return TrendCard(
 compact: SettingsScope.compactOf(context),
            pair: pair,
            sparkline: state.sparklines[pair.symbol] ?? const <double>[],
            onTap: () => onOpen(pair),
          );
        },
      ),
    );
  }
}

class _StaleBanner extends StatelessWidget {
  const _StaleBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: p.negativeBg,
        borderRadius: AppRadii.cardRadius,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '$message Showing the last loaded data.',
              style: AppTypography.label.copyWith(color: p.negativeLight),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text('Retry',
                style: AppTypography.labelStrong.copyWith(color: p.negativeLight),),
          ),
        ],
      ),
    );
  }
}

/// Static placeholder shapes shown during the first load.
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    Widget box(double h, {double? w}) => Container(
          height: h,
          width: w,
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: AppRadii.cardRadius,
          ),
        );
    return Semantics(
      label: 'Loading markets',
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: <Widget>[
          box(28, w: 160),
          const SizedBox(height: 12),
          box(170),
          const SizedBox(height: 16),
          Row(children: <Widget>[
            Expanded(child: box(118)),
            const SizedBox(width: 8),
            Expanded(child: box(118)),
          ],),
          const SizedBox(height: 16),
          for (int i = 0; i < 4; i++) ...<Widget>[
            box(64),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}
