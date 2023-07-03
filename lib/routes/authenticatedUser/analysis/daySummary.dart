import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/tileUI/summaryPage.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

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

  Widget renderDayMetricInfo() {
    List<Widget> rowSymbolElements = <Widget>[];
    const iconMargin = EdgeInsets.fromLTRB(5, 0, 5, 0);
    Widget pendingShimmer = Shimmer.fromColors(
        baseColor: TileStyles.accentColor.withAlpha(100),
        highlightColor: Colors.grey.withAlpha(100),
        child: Container(
          color: Colors.green,
          width: 30.0,
          height: 30.0,
        ));
    const textStyle = const TextStyle(
        fontSize: 30, color: const Color.fromRGBO(153, 153, 153, 1));
    Widget? completeWidget = pendingFlag ? pendingShimmer : null;
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
              style: textStyle,
            )
          ],
        ),
      );
    }
    if (completeWidget != null) {
      rowSymbolElements
          .add(Container(margin: iconMargin, child: completeWidget));
    }
    Widget? warnWidget = pendingFlag ? pendingShimmer : null;
    if ((dayData?.nonViable?.length ?? 0) > 0) {
      warnWidget = Container(
        child: Row(
          children: [
            Icon(
              Icons.warning_amber,
              color: TileStyles.warningAmber,
              size: 30.0,
            ),
            Text(
              (dayData?.nonViable?.length ?? 0).toString(),
              style: textStyle,
            )
          ],
        ),
      );
    }
    if (warnWidget != null) {
      rowSymbolElements.add(Container(margin: iconMargin, child: warnWidget));
    }
    Widget? sleepWidget = pendingFlag ? pendingShimmer : null;
    if ((dayData?.sleepDuration?.inHours ?? 0) > 0) {
      sleepWidget = Container(
        child: Row(
          children: [
            Icon(
              Icons.king_bed,
              size: 30.0,
            ),
            Text(
              (dayData?.sleepDuration?.inHours ?? 0).toString(),
              style: textStyle,
            )
          ],
        ),
      );
    }
    if (sleepWidget != null) {
      rowSymbolElements.add(Container(margin: iconMargin, child: sleepWidget));
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
              if (state is ScheduleDaySummaryLoaded) {
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
              if (state is ScheduleDaySummaryLoading) {
                setState(() {
                  pendingFlag = true;
                });
              }
            },
          ),
        ],
        child: BlocBuilder<ScheduleSummaryBloc, ScheduleSummaryState>(
          builder: (context, state) {
            if (state is ScheduleDaySummaryLoaded) {
              TimelineSummary? latestDayData = state.dayData!
                  .where((timelineSummary) =>
                      timelineSummary.dayIndex == dayData?.dayIndex)
                  .firstOrNull;
              if (latestDayData != null) {
                dayData = latestDayData;
              }
            }

            List<Widget> childElements = [renderDayMetricInfo()];
            Widget dayDateText = Container(
              child: Text(
                  Utility.getTimeFromIndex(dayData!.dayIndex!).humanDate,
                  style: TextStyle(
                      fontSize: 30,
                      fontFamily: TileStyles.rubikFontName,
                      color: TileStyles.primaryColorDarkHSL.toColor(),
                      fontWeight: FontWeight.w700)),
            );
            childElements.add(dayDateText);
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
                mainAxisAlignment: MainAxisAlignment.end,
                children: childElements,
              ),
            );

            Container retContainer = Container(
                padding: EdgeInsets.fromLTRB(10, 10, 20, 0),
                height: 120,
                child: buttonPress);

            return retContainer;
          },
        ));
  }
}