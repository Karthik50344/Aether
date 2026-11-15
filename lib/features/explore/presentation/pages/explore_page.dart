import '../../../../shared/ui/settings_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../shared/domain/entities/trading_pair.dart';
import '../../../../shared/ui/search_focus_signal.dart';
import '../bloc/explore_bloc.dart';
import '../widgets/active_filter_chips.dart';
import '../widgets/explore_filter_sheet.dart';
import '../widgets/explore_pair_tile.dart';
import '../widgets/explore_search_field.dart';
import '../widgets/market_flow_card.dart';
import '../widgets/market_table_header.dart';
import '../widgets/pro_tip_banner.dart';
import '../widgets/quote_tabs.dart';

/// Explore Markets. Requires an [ExploreBloc] above it (provided by the router).
class ExplorePage extends StatefulWidget {
  const ExplorePage({
    this.sourceLabel = 'REST',
    this.focusSignal,
    super.key,
  });

  /// Shown in the status line ("SAMPLE DATA" in mock mode).
  final String sourceLabel;

  /// Set by the header search button to focus the search field.
  final SearchFocusSignal? focusSignal;

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.focusSignal?.addListener(_onFocusRequest);
    // The request may have been made before this (lazy) tab was built.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onFocusRequest());
  }

  /// The search field only exists once data is shown, so a request made
  /// earlier (or while loading) is remembered and applied after that build.
  bool _wantFocus = false;

  void _onFocusRequest() {
    if (!mounted) return;
    if (widget.focusSignal?.consume() ?? false) setState(() => _wantFocus = true);
  }

  @override
  void dispose() {
    widget.focusSignal?.removeListener(_onFocusRequest);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _openFilters(BuildContext context, ExploreState state) async {
    final ExploreBloc bloc = context.read<ExploreBloc>();
    final ExploreFilterResult? r =
        await showExploreFilterSheet(context, query: state.query);
    if (r == null) return;
    bloc.add(ExploreFiltersApplied(
      move: r.move,
      minQuoteVolume: r.minQuoteVolume,
      sortField: r.sortField,
      ascending: r.ascending,
    ));
  }

  void _resetAll(BuildContext context) {
    _controller.clear();
    context.read<ExploreBloc>()
      ..add(const ExploreSearchApplied(''))
      ..add(const ExploreFiltersReset());
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: BlocBuilder<ExploreBloc, ExploreState>(
        builder: (BuildContext context, ExploreState state) {
          if (state.isLoading && !state.hasData) {
            return const _ExploreSkeleton();
          }
          if (state.hasFailed && !state.hasData) {
            return AppErrorView(
              message: state.errorMessage ?? 'Could not load trading pairs.',
              onRetry: () => context
                  .read<ExploreBloc>()
                  .add(const ExploreRetryRequested()),
            );
          }
          return _body(context, state);
        },
      ),
    );
  }

  Widget _body(BuildContext context, ExploreState state) {
    final AppPalette p = context.palette;
    final ExploreBloc bloc = context.read<ExploreBloc>();
    final List<TradingPair> rows = state.visible;

    if (_wantFocus) {
      _wantFocus = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }

    return RefreshIndicator(
      color: p.primary,
      backgroundColor: p.surfaceHigh,
      onRefresh: () async {
        bloc.add(const ExploreRefreshed());
        await bloc.stream.firstWhere((ExploreState s) => !s.refreshing);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen, AppSpacing.md, AppSpacing.screen, 0),
            sliver: SliverToBoxAdapter(child: _header(context, state)),
          ),
          if (rows.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: AppEmptyView(
                  title: 'No pairs found',
                  message: 'Nothing matches your search and filters.',
                  icon: Icons.search_off,
                  actionLabel: 'Reset search & filters',
                  onAction: () => _resetAll(context),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int i) {
                    final TradingPair pair = rows[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.rowGap),
                      child: ExplorePairTile(
 compact: SettingsScope.compactOf(context),
                        key: ValueKey<String>(pair.symbol),
                        pair: pair,
                        sparkline: state.sparklines[pair.symbol],
                        onNeedSparkline: (String s) =>
                            bloc.add(ExploreSparklineRequested(s)),
                        onTap: () => context.push(RoutePaths.pair(pair.symbol)),
                      ),
                    );
                  },
                  childCount: rows.length,
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm,
                AppSpacing.screen, AppSpacing.xxl),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: <Widget>[
                  if (state.remaining > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: OutlinedButton(
                        onPressed: () => bloc.add(const ExploreShowMore()),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          foregroundColor: p.primaryLight,
                          side: BorderSide(color: p.surfaceHighest),
                          shape: const RoundedRectangleBorder(
                              borderRadius: AppRadii.cardRadius),
                        ),
                        child: Text(
                          'Show more (${Fmt.integer(state.remaining)} remaining)',
                          style:
                              AppTypography.label.copyWith(color: p.primaryLight),
                        ),
                      ),
                    ),
                  if (state.flow != null) MarketFlowCard(
 compact: SettingsScope.compactOf(context),flow: state.flow!),
                  const SizedBox(height: AppSpacing.md),
                  const ProTipBanner(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, ExploreState state) {
    final AppPalette p = context.palette;
    final ExploreBloc bloc = context.read<ExploreBloc>();
    final bool stale = state.refreshFailed;
    final Color statusColor = stale ? p.negative : p.positive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: statusColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                stale
                    ? 'OFFLINE · SHOWING LAST DATA'
                    : 'BINANCE SPOT · ${widget.sourceLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.micro
                    .copyWith(color: statusColor, letterSpacing: 0.3),
              ),
            ),
            if (state.latency != null && !stale)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: AppRadii.pillRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(AppIcons.signal, size: 12, color: p.textSecondary),
                    const SizedBox(width: 4),
                    Text('${state.latency!.inMilliseconds}ms',
                        style: AppTypography.label
                            .copyWith(color: p.textSecondary)),
                  ],
                ),
              ),
          ],
        ),
        if (stale) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            decoration: BoxDecoration(
              color: p.negativeBg,
              borderRadius: AppRadii.cardRadius,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${state.errorMessage ?? 'Refresh failed.'} Showing the last loaded data.',
                    style: AppTypography.label.copyWith(color: p.negativeLight),
                  ),
                ),
                TextButton(
                  onPressed: () => bloc.add(const ExploreRefreshed()),
                  child: Text('Retry',
                      style: AppTypography.labelStrong
                          .copyWith(color: p.negativeLight)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Text('Explore Markets',
            style: AppTypography.heroValue.copyWith(color: p.textPrimary)),
        const SizedBox(height: 2),
        Text(
          'Discover ${Fmt.integer(state.allPairs.length)} spot trading pairs across quote markets',
          style: AppTypography.valueMedium
              .copyWith(color: p.textSecondary, fontSize: 12, letterSpacing: 0),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: <Widget>[
            Expanded(
              child: ExploreSearchField(
                controller: _controller,
                focusNode: _focus,
                onChanged: (String t) => bloc.add(ExploreSearchChanged(t)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            FilterButton(
              count: state.activeFilterCount,
              onTap: () => _openFilters(context, state),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        QuoteTabs(
          quotes: state.quoteTabs,
          selected: state.query.quoteAsset,
          onSelected: (String? q) => bloc.add(ExploreQuoteSelected(q)),
        ),
        const SizedBox(height: AppSpacing.md),
        ActiveFilterChips(
          state: state,
          onSortTap: () => _openFilters(context, state),
          onClearMove: () => bloc.add(const ExploreMoveCleared()),
          onClearMinVolume: () => bloc.add(const ExploreMinVolumeCleared()),
        ),
        const SizedBox(height: AppSpacing.md),
        MarketTableHeader(
          sortField: state.effectiveSort,
          ascending: state.query.ascending,
          onSort: (f) => bloc.add(ExploreSortToggled(f)),
        ),
        const SizedBox(height: 2),
      ],
    );
  }
}

class _ExploreSkeleton extends StatelessWidget {
  const _ExploreSkeleton();

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
      label: 'Loading pairs',
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: <Widget>[
          box(32, w: 220),
          const SizedBox(height: 16),
          box(48),
          const SizedBox(height: 12),
          box(32),
          const SizedBox(height: 16),
          for (int i = 0; i < 6; i++) ...<Widget>[
            box(62),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}
