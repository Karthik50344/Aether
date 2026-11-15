import 'package:flutter/material.dart';

import '../../../../core/formatters/formatters.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/explore_query.dart';
import '../../domain/entities/volume_presets.dart';
import 'explore_labels.dart';

/// Values chosen in the sheet.
class ExploreFilterResult {
  const ExploreFilterResult({
    required this.move,
    required this.minQuoteVolume,
    required this.sortField,
    required this.ascending,
  });

  final MoveFilter move;
  final double minQuoteVolume;
  final SortField sortField;
  final bool ascending;
}

/// Opens the filter / sort sheet. Returns `null` when dismissed.
Future<ExploreFilterResult?> showExploreFilterSheet(
  BuildContext context, {
  required ExploreQuery query,
}) {
  return showModalBottomSheet<ExploreFilterResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext _) => _FilterSheet(query: query),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.query});
  final ExploreQuery query;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late MoveFilter _move = widget.query.move;
  late double _minVol = widget.query.minQuoteVolume;
  late SortField _sort = widget.query.sortField ?? SortField.volume;
  late bool _asc = widget.query.ascending;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final String? quote = widget.query.quoteAsset;
    final List<double> presets = VolumePresets.forQuote(quote);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: p.surfaceHighest,
                borderRadius: AppRadii.pillRadius,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Filters & sort',
              style: AppTypography.sectionTitle.copyWith(color: p.textPrimary)),
          const SizedBox(height: 16),
          _Section(
            title: '24H PRICE MOVE',
            child: _Options<MoveFilter>(
              values: MoveFilter.all,
              selected: _move,
              label: (MoveFilter m) => m.label,
              onSelected: (MoveFilter m) => setState(() => _move = m),
            ),
          ),
          _Section(
            title: 'MIN 24H VOLUME',
            child: presets.isEmpty
                ? Text(
                    'Select a quote asset tab first - volume is measured in that asset.',
                    style: AppTypography.label.copyWith(color: p.textSecondary),
                  )
                : _Options<double>(
                    values: <double>[0, ...presets],
                    selected: _minVol,
                    label: (double v) =>
                        v == 0 ? 'Any' : '>${Fmt.quoteAmount(v, quote ?? '')}',
                    onSelected: (double v) => setState(() => _minVol = v),
                  ),
          ),
          _Section(
            title: 'SORT BY',
            child: _Options<SortField>(
              values: SortField.all,
              selected: _sort,
              label: ExploreLabels.sort,
              onSelected: (SortField f) => setState(() {
                if (f != _sort) _asc = f == SortField.name;
                _sort = f;
              }),
            ),
          ),
          _Section(
            title: 'ORDER',
            child: _Options<bool>(
              values: const <bool>[false, true],
              selected: _asc,
              label: (bool asc) => asc ? 'Ascending ↑' : 'Descending ↓',
              onSelected: (bool v) => setState(() => _asc = v),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _move = MoveFilter.none;
                    _minVol = 0;
                    _sort = SortField.volume;
                    _asc = false;
                  }),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    side: BorderSide(color: p.surfaceHighest),
                    foregroundColor: p.textPrimary,
                    shape: const RoundedRectangleBorder(
                        borderRadius: AppRadii.cardRadius),
                  ),
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(
                    ExploreFilterResult(
                      move: _move,
                      minQuoteVolume: _minVol,
                      sortField: _sort,
                      ascending: _asc,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    backgroundColor: p.primary,
                    foregroundColor: p.onPrimary,
                    shape: const RoundedRectangleBorder(
                        borderRadius: AppRadii.cardRadius),
                  ),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title,
              style: AppTypography.micro.copyWith(color: p.textSecondary)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Options<T> extends StatelessWidget {
  const _Options({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final T v in values)
          Semantics(
            button: true,
            selected: v == selected,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(v),
              child: Container(
                constraints: const BoxConstraints(minHeight: 36),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: v == selected ? p.primary : p.surfaceHigh,
                  borderRadius: AppRadii.pillRadius,
                ),
                child: Text(
                  label(v),
                  style: (v == selected
                          ? AppTypography.labelStrong
                          : AppTypography.label)
                      .copyWith(
                          color: v == selected ? p.onPrimary : p.textSecondary),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
