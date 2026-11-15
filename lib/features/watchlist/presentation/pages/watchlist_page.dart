import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/state/load_status.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../shared/ui/data_reset_signal.dart';
import '../bloc/watchlist_bloc.dart';
import '../widgets/add_pair_sheet.dart';
import '../widgets/watchlist_row.dart';
import '../widgets/watchlist_summary_pill.dart';

/// Watchlist tab (Figma 3:972). Alert bells from the design are omitted:
/// the app has no notification backend (spec section 9).
class WatchlistPage extends StatefulWidget {
  const WatchlistPage({this.resetSignal, super.key});

  /// Fires after "Clear cache & reset datafeed" in Settings.
  final DataResetSignal? resetSignal;

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  @override
  void initState() {
    super.initState();
    widget.resetSignal?.addListener(_onReset);
  }

  void _onReset() {
    if (mounted) {
      context.read<WatchlistBloc>().add(const WatchlistRefreshed(force: true));
    }
  }

  @override
  void dispose() {
    widget.resetSignal?.removeListener(_onReset);
    super.dispose();
  }

  void _openAdd(BuildContext context, WatchlistState s) {
    final WatchlistBloc bloc = context.read<WatchlistBloc>();
    showAddPairSheet(
      context,
      pairs: s.allPairs,
      saved: s.symbols.toSet(),
      onAdd: (String sym) => bloc.add(WatchlistPairAdded(sym)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return BlocBuilder<WatchlistBloc, WatchlistState>(
      builder: (BuildContext context, WatchlistState s) {
        if (s.status == LoadStatus.initial || s.status == LoadStatus.loading) {
          return const AppLoadingView();
        }
        if (s.status == LoadStatus.failure) {
          return AppErrorView(
            title: 'Could not load your watchlist',
            message: s.errorMessage ?? 'Please try again.',
            onRetry: () =>
                context.read<WatchlistBloc>().add(const WatchlistStarted()),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            context.read<WatchlistBloc>().add(const WatchlistRefreshed(force: true));
          },
          child: s.isEmpty ? _empty(context, p, s) : _list(context, p, s),
        );
      },
    );
  }

  Widget _header(BuildContext context, AppPalette p, WatchlistState s) {
    final WatchlistBloc bloc = context.read<WatchlistBloc>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('My Watchlist',
            style: AppTypography.heroValue
                .copyWith(color: p.textPrimary, fontSize: 28),),
        const SizedBox(height: 4),
        Text(
          '${s.symbols.length} SAVED PAIRS · STORED ON THIS DEVICE',
          style: AppTypography.micro.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            if (!s.isEmpty)
              OutlinedButton(
                onPressed: () => bloc.add(const WatchlistEditToggled()),
                child: Text(s.editing ? 'Done' : 'Edit'),
              ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _openAdd(context, s),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Pair'),
              style: FilledButton.styleFrom(
                backgroundColor: p.primary,
                foregroundColor: p.onPrimary,
              ),
            ),
          ],
        ),
        if (s.refreshFailed)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Could not refresh - showing the last data. ${s.errorMessage ?? ''}',
              style: AppTypography.label.copyWith(color: p.negativeLight),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _list(BuildContext context, AppPalette p, WatchlistState s) {
    final WatchlistBloc bloc = context.read<WatchlistBloc>();
    Widget rowFor(int i) {
      final String sym = s.symbols[i];
      return Padding(
        key: ValueKey<String>(sym),
        padding: const EdgeInsets.only(bottom: AppSpacing.rowGap),
        child: WatchlistRow(
          symbol: sym,
          pair: s.pairsBySymbol[sym],
          editing: s.editing,
          dragIndex: i,
          onTap: () => context.push(RoutePaths.pair(sym)),
          onRemove: () => bloc.add(WatchlistPairRemoved(sym)),
        ),
      );
    }

    final Widget head = Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, AppSpacing.xl, AppSpacing.screen, 0,),
      child: _header(context, p, s),
    );
    final Widget pill = Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, 12),
      child: WatchlistSummaryPill(summary: s.summary),
    );

    if (s.editing) {
      return Column(
        children: <Widget>[
          head,
          pill,
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              buildDefaultDragHandles: false,
              itemCount: s.symbols.length,
              onReorder: (int a, int b) => bloc.add(WatchlistReordered(a, b)),
              itemBuilder: (_, int i) => rowFor(i),
            ),
          ),
        ],
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: <Widget>[
        head,
        pill,
        for (int i = 0; i < s.symbols.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: rowFor(i),
          ),
      ],
    );
  }

  Widget _empty(BuildContext context, AppPalette p, WatchlistState s) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: <Widget>[
        const SizedBox(height: AppSpacing.xl),
        Text('My Watchlist',
            style: AppTypography.heroValue
                .copyWith(color: p.textPrimary, fontSize: 28),),
        const SizedBox(height: 48),
        Center(
          child: CustomPaint(
            painter: _DashedCirclePainter(p.surfaceHighest),
            child: SizedBox(
              width: 120,
              height: 120,
              child: Icon(Icons.star_border, size: 40, color: p.primaryLight),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Your watchlist is empty',
            textAlign: TextAlign.center,
            style: AppTypography.sectionTitle.copyWith(color: p.textPrimary),),
        const SizedBox(height: 8),
        Text(
          'Save pairs with the star on a pair page, or add one here. '
          'Your list stays on this device.',
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FilledButton(
              onPressed: () => context.go(RoutePaths.explore),
              style: FilledButton.styleFrom(
                backgroundColor: p.primary,
                foregroundColor: p.onPrimary,
              ),
              child: const Text('Explore Markets →'),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () => _openAdd(context, s),
              child: const Text('Add Pair'),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final double r = size.shortestSide / 2 - 1;
    final Offset c = size.center(Offset.zero);
    const int dashes = 36;
    const double sweep = 2 * 3.141592653589793 / dashes;
    for (int i = 0; i < dashes; i++) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), i * sweep,
          sweep * 0.55, false, paint,);
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color;
}
