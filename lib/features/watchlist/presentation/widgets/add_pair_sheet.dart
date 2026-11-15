import 'package:flutter/material.dart';

import '../../../../core/formatters/formatters.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/entities/trading_pair.dart';
import '../../../../shared/widgets/coin_avatar.dart';

/// Searchable list of every active pair; tapping adds it to the watchlist.
/// Pairs already saved show a filled star and are not added twice.
Future<void> showAddPairSheet(
  BuildContext context, {
  required List<TradingPair> pairs,
  required Set<String> saved,
  required void Function(String symbol) onAdd,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.palette.surface,
    builder: (_) => _AddPairSheet(pairs: pairs, saved: saved, onAdd: onAdd),
  );
}

class _AddPairSheet extends StatefulWidget {
  const _AddPairSheet(
      {required this.pairs, required this.saved, required this.onAdd});
  final List<TradingPair> pairs;
  final Set<String> saved;
  final void Function(String symbol) onAdd;

  @override
  State<_AddPairSheet> createState() => _AddPairSheetState();
}

class _AddPairSheetState extends State<_AddPairSheet> {
  String _query = '';
  late final Set<String> _saved = <String>{...widget.saved};

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final String q = _query.trim().toUpperCase().replaceAll('/', '');
    final List<TradingPair> rows = <TradingPair>[
      for (final TradingPair t in widget.pairs)
        if (q.isEmpty || t.symbol.contains(q)) t,
    ];
    final int shown = rows.length > 100 ? 100 : rows.length;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: Column(
            children: <Widget>[
              const SizedBox(height: 16),
              Text('Add Pair',
                  style: AppTypography.sectionTitle
                      .copyWith(color: p.textPrimary)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  autofocus: false,
                  onChanged: (String v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search BTC, ETHUSDT…',
                    prefixIcon: const Icon(AppIcons.search),
                    filled: true,
                    fillColor: p.surfaceHigh,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: rows.isEmpty
                    ? Center(
                        child: Text('No pairs match "$_query".',
                            style: AppTypography.body
                                .copyWith(color: p.textSecondary)))
                    : ListView.builder(
                        itemCount: shown,
                        itemBuilder: (BuildContext _, int i) {
                          final TradingPair t = rows[i];
                          final bool isSaved = _saved.contains(t.symbol);
                          return ListTile(
                            leading: CoinAvatar(baseAsset: t.baseAsset, size: 36),
                            title: Text(t.displayName,
                                style: AppTypography.symbol
                                    .copyWith(color: p.textPrimary)),
                            subtitle: Text(
                              Fmt.pricedIn(t.lastPrice, t.quoteAsset),
                              style: AppTypography.label
                                  .copyWith(color: p.textSecondary),
                            ),
                            trailing: Icon(
                              isSaved ? AppIcons.starFilled : AppIcons.starOutline,
                              color: isSaved ? p.primaryLight : p.textSecondary,
                            ),
                            onTap: isSaved
                                ? null
                                : () {
                                    widget.onAdd(t.symbol);
                                    setState(() => _saved.add(t.symbol));
                                  },
                          );
                        },
                      ),
              ),
              if (rows.length > shown)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('Showing $shown of ${rows.length} - refine your search.',
                      style: AppTypography.label.copyWith(color: p.textSecondary)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
