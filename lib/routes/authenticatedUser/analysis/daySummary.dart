import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/routes/authenticatedUser/summaryPage.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

import '../../../bloc/uiDateManager/ui_date_manager_bloc.dart';

class DaySummary extends StatefulWidget {
  TimelineSummary dayTimelineSummary;
  DaySummary({required this.dayTimelineSummary});
  @override
  State createState() => _DaySummaryState();
}

class _DaySummaryState extends State<DaySummary> {
  TimelineSummary? dayData;
  bool pendingFlag = false;

  @override
  void initState() {
    super.initState();
    dayData = this.widget.dayTimelineSummary;
  }

  bool get isPending {
    bool retValue = false;
    retValue = retValue ||
        this.context.read<ScheduleSummaryBloc>().state
            is ScheduleDaySummaryLoading;
    retValue = pendingFlag || retValue;
    return retValue;
  }

  Widget renderDayMetricInfo() {
    List<Widget> rowSymbolElements = <Widget>[];
    const iconMargin = EdgeInsets.fromLTRB(5, 0, 5, 0);
    Widget pendingShimmer = Shimmer.fromColors(
        baseColor: TileStyles.primaryColorLightHSL.toColor().withAlpha(50),
        highlightColor: Colors.white.withAlpha(100),
        child: Container(
          decoration: BoxDecoration(
              color: Color.fromRGBO(31, 31, 31, 0.8),
              borderRadius: BorderRadius.circular(8)),
          width: 30.0,
          height: 30.0,
        ));

    Widget? warnWidget = isPending ? pendingShimmer : null;
    if ((dayData?.nonViable?.length ?? 0) > 0) {
      warnWidget = Container(
        child: Row(
          children: [
            Icon(
              Icons.error,
              color: Colors.redAccent,
              size: 30.0,
            ),
            Text(
              (dayData?.nonViable?.length ?? 0).toString(),
              style: TileStyles.daySummaryStyle,
            )
          ],
        ),
      );
    }
    if (warnWidget != null) {
      rowSymbolElements.add(Container(margin: iconMargin, child: warnWidget));
    }
    Widget? completeWidget = isPending ? pendingShimmer : null;
    if ((dayData?.complete?.length ?? 0) > 0) {
      completeWidget = Container(
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: TileStyles.greenCheck,
              size: 30.0,
            ),
            Text(
              (dayData?.complete?.length ?? 0).toString(),
              style: TileStyles.daySummaryStyle,
            )
          ],
        ),
      );
    }
    if (completeWidget != null) {
      rowSymbolElements
          .add(Container(margin: iconMargin, child: completeWidget));
    }

    Widget? tardyWidget = isPending ? pendingShimmer : null;
    if ((dayData?.tardy?.length ?? 0) > 0) {
      tardyWidget = Container(
        child: Row(
          children: [
            Icon(
              Icons.car_crash_outlined,
              color: Colors.amberAccent,
              size: 30.0,
            ),
            Text(
              (dayData?.tardy?.length ?? 0).toString(),
              style: TileStyles.daySummaryStyle,
            )
          ],
        ),
      );
    }
    if (tardyWidget != null) {
      rowSymbolElements.add(Container(margin: iconMargin, child: tardyWidget));
    }

    Widget retValue = Container(
      margin: EdgeInsets.fromLTRB(0, 0, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: rowSymbolElements,
      ),
    );
    return retValue;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ScheduleSummaryBloc, ScheduleSummaryState>(
          listener: (context, state) {
            if (state is ScheduleDaySummaryLoaded && state.requestId == null) {
              if (state.dayData != null && dayData != null) {
                TimelineSummary? latestDayData = state.dayData!
                    .where((timelineSummary) =>
                        timelineSummary.dayIndex == dayData?.dayIndex)
                    .firstOrNull;
                setState(() {
                  dayData = latestDayData;
                  pendingFlag = false;
                });
              }
            }
            if (state is ScheduleDaySummaryLoading && state.requestId == null) {
              setState(() {
                pendingFlag = true;
              });
            }
          },
        ),
      ],
      child: BlocBuilder<ScheduleSummaryBloc, ScheduleSummaryState>(
        builder: (context, state) {
          if (state is ScheduleDaySummaryLoaded && state.requestId == null) {
            TimelineSummary? latestDayData = state.dayData!
                .where((timelineSummary) =>
                    timelineSummary.dayIndex == dayData?.dayIndex)
                .firstOrNull;
            if (latestDayData != null) {
              dayData = latestDayData;
            }
          }

          Widget dayDateText = Container(
            child: Text(
                Utility.getTimeFromIndex(dayData!.dayIndex!).humanDate(context),
                style: TextStyle(
                    fontSize: 30,
                    fontFamily: TileStyles.rubikFontName,
                    color: TileStyles.primaryColor,
                    fontWeight: FontWeight.w700)),
          );

          Widget buttonPress = GestureDetector(
            onTap: () {
              DateTime start = Utility.getTimeFromIndex(dayData!.dayIndex!);
              DateTime end =
                  Utility.getTimeFromIndex(dayData!.dayIndex!).endOfDay;
              Timeline timeline = Timeline(
                  start.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SummaryPage(
                            timeline: timeline,
                          )));
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [dayDateText, renderDayMetricInfo()],
                ),
              ],
            ),
          );

          Container retContainer = Container(
              padding: EdgeInsets.fromLTRB(10, 10, 20, 0),
              height: 120,
              child: buttonPress);

          return retContainer;
        },
      ),
    );
  }
}
