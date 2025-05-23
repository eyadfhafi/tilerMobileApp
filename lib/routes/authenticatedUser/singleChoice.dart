import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/styles.dart';

class SingleChoice extends StatefulWidget {
  final Function? onChanged;
  final TilePriority priority;
  const SingleChoice({super.key, this.onChanged, required this.priority});

  @override
  State<SingleChoice> createState() => _SingleChoiceState();
}

class _SingleChoiceState extends State<SingleChoice> {
  late TilePriority _priorityView;
  @override
  void initState() {
    super.initState();
    _priorityView = this.widget.priority;
  }

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TilePriority>(
      style: ButtonStyle(
          foregroundColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return TileStyles.appBarTextColor;
              }
              return TileStyles.primaryColor;
            },
          ),
          backgroundColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return TileStyles.primaryColor;
              }
              return Colors.transparent;
            },
          ),
          side: MaterialStateBorderSide.resolveWith(
              (states) => BorderSide(color: TileStyles.primaryColor))),
      segments: <ButtonSegment<TilePriority>>[
        ButtonSegment<TilePriority>(
            value: TilePriority.low,
            label: Text(AppLocalizations.of(context)!.lowPriorityTrunc),
            icon: Icon(Icons.circle)),
        ButtonSegment<TilePriority>(
            value: TilePriority.medium,
            label: Text(AppLocalizations.of(context)!.mediumPriorityTrunc),
            icon: Icon(Icons.calendar_view_week)),
        ButtonSegment<TilePriority>(
            value: TilePriority.high,
            label: Text(AppLocalizations.of(context)!.highPriorityTrunc),
            icon: Icon(Icons.calendar_view_month)),
      ],
      selected: <TilePriority>{_priorityView},
      onSelectionChanged: (Set<TilePriority> newSelection) {
        setState(() {
          // By default there is only a single segment that can be
          // selected at one time, so its value is always the first
          // item in the selected set.
          _priorityView = newSelection.first;
        });
        if (this.widget.onChanged != null) {
          this.widget.onChanged!(newSelection.first);
        }
      },
    );
  }
}
