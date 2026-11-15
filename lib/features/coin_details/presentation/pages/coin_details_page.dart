import '../../../../shared/ui/settings_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../shared/domain/entities/trading_pair.dart';
import '../../../../shared/widgets/avatar_button.dart';
import '../../../../shared/widgets/floating_pill_nav.dart';
import '../bloc/coin_details_bloc.dart';
import '../widgets/chart_card.dart';
import '../widgets/depth_meter.dart';
import '../widgets/pair_overview.dart';
import '../widgets/recent_trades_table.dart';
import '../widgets/stat_grid.dart';

/// Trading-pair details. Requires a [CoinDetailsBloc] above it (the router
/// creates one per opened pair).
class CoinDetailsPage extends StatelessWidget {
  const CoinDetailsPage({required this.symbol, this.now, super.key});

  final String symbol;

  /// Injectable clock for the chart's "Today" label (tests).
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      body: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              BlocBuilder<CoinDetailsBloc, CoinDetailsState>(
                buildWhen: (CoinDetailsState a, CoinDetailsState b) =>
                    a.isWatched != b.isWatched,
                builder: (BuildContext context, CoinDetailsState s) =>
                    _Header(isWatched: s.isWatched),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSpacing.maxContentWidth,
                    ),
                    child: MediaQuery.withClampedTextScaling(
                      maxScaleFactor: 1.3,
                      child: _Body(symbol: symbol, now: now),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: FloatingPillNav(
                items: <FloatingNavItem>[
                  FloatingNavItem(
                    label: 'Market',
                    icon: Icons.trending_up,
                    onTap: () => context.go(RoutePaths.market),
                  ),
                  FloatingNavItem(
                    label: 'Explore',
                    icon: Icons.explore_outlined,
                    onTap: () => context.go(RoutePaths.explore),
                  ),
                  FloatingNavItem(
                    label: 'Watchlist',
                    icon: Icons.star_border,
                    onTap: () => context.go(RoutePaths.watchlist),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isWatched});
  final bool isWatched;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Material(
      color: p.headerBg,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: AppSpacing.headerHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: <Widget>[
                IconButton(
                  tooltip: 'Back',
                  icon: Icon(Icons.arrow_back, color: p.textPrimary),
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go(RoutePaths.market),
                ),
                Expanded(
                  child: Text(
                    'Asset Detail',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sectionTitle.copyWith(color: p.textPrimary),
                  ),
                ),
                IconButton(
                  tooltip: isWatched ? 'Remove from watchlist' : 'Add to watchlist',
                  icon: Icon(
                    isWatched ? Icons.star : Icons.star_border,
                    color: isWatched ? p.primaryLight : p.textSecondary,
                  ),
                  onPressed: () =>
                      context.read<CoinDetailsBloc>().add(const WatchlistToggled()),
                ),
                AvatarButton(onTap: () => context.go(RoutePaths.settings)),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.symbol, this.now});
  final String symbol;
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CoinDetailsBloc, CoinDetailsState>(
      builder: (BuildContext context, CoinDetailsState s) {
        if (s.isLoading && !s.hasPair) return const _Skeleton();
        if (s.hasFailed && !s.hasPair) {
          return AppErrorView(
            title: 'Could not load $symbol',
            message: s.errorMessage ?? 'Please try again.',
            onRetry: () =>
                context.read<CoinDetailsBloc>().add(const CoinDetailsRefreshed()),
          );
        }
        return _Content(state: s, now: now);
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.state, this.now});

  final CoinDetailsState state;
  final DateTime Function()? now;

  Future<void> _share(BuildContext context, TradingPair pair) async {
    final String q = pair.quoteAsset;
    final String text =
        '${pair.baseAsset}/$q on Binance Spot: ${Fmt.pricedIn(pair.lastPrice, q)} '
        '(${Fmt.percent(pair.priceChangePercent)} 24h). '
        '24h high ${Fmt.pricedIn(pair.highPrice, q)}, low ${Fmt.pricedIn(pair.lowPrice, q)}, '
        'volume ${Fmt.quoteAmount(pair.quoteVolume, q)}.';
    String message;
    try {
      await Clipboard.setData(ClipboardData(text: text));
      message = 'Summary copied to clipboard';
    } catch (_) {
      message = 'Could not copy to the clipboard';
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final CoinDetailsBloc bloc = context.read<CoinDetailsBloc>();
    final TradingPair pair = state.pair!;
    final String q = pair.quoteAsset;
    void retry() => bloc.add(const CoinDetailsRefreshed());

    return RefreshIndicator(
      color: p.primary,
      backgroundColor: p.surfaceHigh,
      onRefresh: () async {
        bloc.add(const CoinDetailsRefreshed());
        await bloc.stream.firstWhere((CoinDetailsState s) => !s.refreshing);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.md, AppSpacing.screen, 96),
        children: <Widget>[
          if (state.refreshFailed) ...<Widget>[
            _StaleBanner(message: state.errorMessage ?? 'Refresh failed.', onRetry: retry),
            const SizedBox(height: AppSpacing.md),
          ],
          PairOverview(
            pair: pair,
            isWatched: state.isWatched,
            lastUpdated: state.lastUpdated,
            onToggleWatch: () => bloc.add(const WatchlistToggled()),
            onOpenWatchlist: () => context.go(RoutePaths.watchlist),
            onShare: () => _share(context, pair),
          ),
          if (state.orderflow != null) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            OrderflowBanner(
 compact: SettingsScope.compactOf(context),flow: state.orderflow!, quote: q),
          ],
          const SizedBox(height: AppSpacing.lg),
          ChartCard(
            period: state.period,
            indicators: state.indicators,
            series: state.series,
            loading: state.chartStatus == LoadStatus.loading ||
                state.chartStatus == LoadStatus.initial,
            failed: state.chartStatus == LoadStatus.failure,
            quote: q,
            now: now,
            onPeriod: (period) => bloc.add(ChartPeriodSelected(period)),
            onToggle: (i) => bloc.add(ChartIndicatorToggled(i)),
            onRetry: () => bloc.add(ChartPeriodSelected(state.period)),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionTitle(title: '24H Market Statistics', trailing: 'Binance Spot'),
          const SizedBox(height: AppSpacing.md),
          if (state.stats != null) StatGrid(
 compact: SettingsScope.compactOf(context),pair: pair, stats: state.stats!),
          const SizedBox(height: AppSpacing.lg),
          _Section(
            status: state.depthStatus,
            hasData: state.depth != null,
            failureText: 'Could not load the order book.',
            onRetry: retry,
            child: state.depth == null
                ? const SizedBox.shrink()
                : DepthMeter(
 compact: SettingsScope.compactOf(context),depth: state.depth!, quote: q, levels: bloc.depthLimit),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionTitle(title: 'Recent Trades', trailing: '● Polling'),
          const SizedBox(height: AppSpacing.md),
          _Section(
            status: state.tradesStatus,
            hasData: state.trades.isNotEmpty,
            failureText: 'Could not load recent trades.',
            onRetry: retry,
            child: RecentTradesTable(
              trades: state.trades,
              baseAsset: pair.baseAsset,
              quoteAsset: q,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _Footnote(),
        ],
      ),
    );
  }
}

/// Shows a section's loading / failure state, otherwise its [child].
class _Section extends StatelessWidget {
  const _Section({
    required this.status,
    required this.hasData,
    required this.failureText,
    required this.onRetry,
    required this.child,
  });

  final LoadStatus status;
  final bool hasData;
  final String failureText;
  final VoidCallback onRetry;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    if (hasData || status == LoadStatus.success) return child;
    final bool failed = status == LoadStatus.failure;
    return Container(
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadii.cardRadius,
      ),
      child: failed
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(failureText,
                    style: AppTypography.label.copyWith(color: p.textSecondary)),
                TextButton(
                  onPressed: onRetry,
                  child: Text('Retry',
                      style: AppTypography.labelStrong.copyWith(color: p.primaryLight)),
                ),
              ],
            )
          : SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: p.primary),
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.trailing});
  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(title,
              style: AppTypography.symbol.copyWith(color: p.textPrimary, fontSize: 15)),
        ),
        Text(trailing,
            style: AppTypography.label.copyWith(color: p.textSecondary, fontSize: 10)),
      ],
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
      decoration: BoxDecoration(color: p.negativeBg, borderRadius: AppRadii.cardRadius),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text('$message Showing the last loaded data.',
                style: AppTypography.label.copyWith(color: p.negativeLight)),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text('Retry',
                style: AppTypography.labelStrong.copyWith(color: p.negativeLight)),
          ),
        ],
      ),
    );
  }
}

class _Footnote extends StatelessWidget {
  const _Footnote();

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: p.surface, borderRadius: AppRadii.cardRadius),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline, size: 16, color: p.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Figures come from Binance Spot public market-data endpoints '
              '(24h ticker, klines, trades, order book), refreshed by polling. '
              'In sample-data mode they are generated, not real. MA(7) and RSI(14) '
              'are calculated in the app. For research only - not investment advice.',
              style: AppTypography.label.copyWith(color: p.textSecondary, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    Widget box(double h, {double? w}) => Container(
          height: h,
          width: w,
          decoration: BoxDecoration(color: p.surface, borderRadius: AppRadii.cardRadius),
        );
    return Semantics(
      label: 'Loading pair',
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: <Widget>[
          box(40, w: 180),
          const SizedBox(height: 16),
          box(44, w: 260),
          const SizedBox(height: 16),
          box(300),
          const SizedBox(height: 16),
          Row(children: <Widget>[
            Expanded(child: box(74)),
            const SizedBox(width: 4),
            Expanded(child: box(74)),
          ]),
        ],
      ),
    );
  }
}
