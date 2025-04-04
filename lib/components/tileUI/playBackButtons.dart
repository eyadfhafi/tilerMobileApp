import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/forecast/tileProcrastinate.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/util.dart';

enum PlaybackOptions { PlayPause, Now, Procrastinate, Delete, Complete }

class PlayBack extends StatefulWidget {
  SubCalendarEvent subEvent;
  List<PlaybackOptions>? forcedOption;
  Function? callBack;
  bool isWeeklyView;
  PlayBack(this.subEvent, {this.forcedOption, this.callBack,this.isWeeklyView=false});
  @override
  PlayBackState createState() => PlayBackState();
}

class PlayBackState extends State<PlayBack> {
  late SubCalendarEventApi _subCalendarEventApi;
  SubCalendarEvent? _subEvent;

  @override
  void initState() {
    super.initState();
    _subCalendarEventApi =
        new SubCalendarEventApi(getContextCallBack: () => context);
  }

  void showMessage(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.SNACKBAR,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black45,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  void showErrorMessage(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.SNACKBAR,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black45,
        textColor: Colors.red,
        fontSize: 16.0);
  }

  pauseTile() async {
    showMessage(AppLocalizations.of(context)!.pausing);
    final scheduleState = this.context.read<ScheduleBloc>().state;
    if (scheduleState is ScheduleEvaluationState) {
      DateTime timeOutTime = Utility.currentTime().subtract(Utility.oneMin);
      if (scheduleState.evaluationTime.isAfter(timeOutTime)) {
        return;
      }
    }

    List<SubCalendarEvent> renderedSubEvents = [];
    List<Timeline> timeLines = [];
    Timeline lookupTimeline = Utility.todayTimeline();
    ScheduleStatus scheduleStatus = new ScheduleStatus();

    if (scheduleState is ScheduleLoadedState) {
      renderedSubEvents = scheduleState.subEvents;
      timeLines = scheduleState.timelines;
      lookupTimeline = scheduleState.lookupTimeline;
      scheduleStatus = scheduleState.scheduleStatus;
    }

    if (scheduleState is ScheduleEvaluationState) {
      renderedSubEvents = scheduleState.subEvents;
      timeLines = scheduleState.timelines;
      lookupTimeline = scheduleState.lookupTimeline;
      scheduleStatus = scheduleState.scheduleStatus;
    }

    if (scheduleState is ScheduleLoadingState) {
      renderedSubEvents = scheduleState.subEvents;
      timeLines = scheduleState.timelines;
      lookupTimeline = scheduleState.previousLookupTimeline;
      scheduleStatus = scheduleState.scheduleStatus;
    }
    var request =
        _subCalendarEventApi.pauseTile((_subEvent ?? this.widget.subEvent).id!);

    if (this.widget.callBack != null) {
      this.widget.callBack!(PlaybackOptions.PlayPause, request);
    }
    context.read<ScheduleBloc>().add(EvaluateSchedule(
        renderedSubEvents: renderedSubEvents,
        renderedTimelines: timeLines,
        renderedScheduleTimeline: lookupTimeline,
        scheduleStatus: scheduleStatus,
        isAlreadyLoaded: true,
        callBack: request));
    if(widget.isWeeklyView) Navigator.pop(context);
  }

  resumeTile() async {
    showMessage(AppLocalizations.of(context)!.resuming);
    final scheduleState = this.context.read<ScheduleBloc>().state;
    if (scheduleState is ScheduleEvaluationState) {
      DateTime timeOutTime = Utility.currentTime().subtract(Utility.oneMin);
      if (scheduleState.evaluationTime.isAfter(timeOutTime)) {
        return;
      }
    }

    List<SubCalendarEvent> renderedSubEvents = [];
    List<Timeline> timeLines = [];
    Timeline lookupTimeline = Utility.todayTimeline();
    ScheduleStatus scheduleStatus = new ScheduleStatus();

    if (scheduleState is ScheduleLoadedState) {
      renderedSubEvents = scheduleState.subEvents;
      timeLines = scheduleState.timelines;
      lookupTimeline = scheduleState.lookupTimeline;
      scheduleStatus = scheduleState.scheduleStatus;
    }

    if (scheduleState is ScheduleEvaluationState) {
      renderedSubEvents = scheduleState.subEvents;
      timeLines = scheduleState.timelines;
      lookupTimeline = scheduleState.lookupTimeline;
      scheduleStatus = scheduleState.scheduleStatus;
    }

    if (scheduleState is ScheduleLoadingState) {
      renderedSubEvents = scheduleState.subEvents;
      timeLines = scheduleState.timelines;
      lookupTimeline = scheduleState.previousLookupTimeline;
      scheduleStatus = scheduleState.scheduleStatus;
    }

    var request =
        _subCalendarEventApi.resumeTile((_subEvent ?? this.widget.subEvent));

    if (this.widget.callBack != null) {
      this.widget.callBack!(PlaybackOptions.PlayPause, request);
    }

    context.read<ScheduleBloc>().add(EvaluateSchedule(
        renderedSubEvents: renderedSubEvents,
        renderedTimelines: timeLines,
        renderedScheduleTimeline: lookupTimeline,
        isAlreadyLoaded: true,
        scheduleStatus: scheduleStatus,
        callBack: request));
    if(widget.isWeeklyView) Navigator.pop(context);
  }

  setAsNowTile() async {
    showMessage(AppLocalizations.of(context)!.movingUp);
    SubCalendarEvent subTile = _subEvent ?? this.widget.subEvent;
    final scheduleState = this.context.read<ScheduleBloc>().state;
    if (scheduleState is ScheduleEvaluationState) {
      DateTime timeOutTime = Utility.currentTime().subtract(Utility.oneMin);
      if (scheduleState.evaluationTime.isAfter(timeOutTime)) {
        return;
      }
    }

    List<SubCalendarEvent> renderedSubEvents = [];
    List<Timeline> timeLines = [];
    Timeline lookupTimeline = Utility.todayTimeline();
    ScheduleStatus scheduleStatus = ScheduleStatus();

    if (scheduleState is ScheduleLoadedState) {
      renderedSubEvents = scheduleState.subEvents;
      timeLines = scheduleState.timelines;
      lookupTimeline = scheduleState.lookupTimeline;
      scheduleStatus = scheduleState.scheduleStatus;
    }

    if (scheduleState is ScheduleEvaluationState) {
      renderedSubEvents = scheduleState.subEvents;
      timeLines = scheduleState.timelines;
      lookupTimeline = scheduleState.lookupTimeline;
      scheduleStatus = scheduleState.scheduleStatus;
    }

    if (scheduleState is ScheduleLoadingState) {
      renderedSubEvents = scheduleState.subEvents;
      timeLines = scheduleState.timelines;
      lookupTimeline = scheduleState.previousLookupTimeline;
      scheduleStatus = scheduleState.scheduleStatus;
    }

    var requestFuture = _subCalendarEventApi.setAsNow((subTile));

    if (this.widget.callBack != null) {
      this.widget.callBack!(PlaybackOptions.Now, requestFuture);
    }

    context.read<ScheduleBloc>().add(EvaluateSchedule(
        renderedSubEvents: renderedSubEvents,
        renderedTimelines: timeLines,
        renderedScheduleTimeline: lookupTimeline,
        isAlreadyLoaded: true,
        scheduleStatus: scheduleStatus,
        callBack: requestFuture));
    if(widget.isWeeklyView) Navigator.pop(context);
  }

  completeTile() async {
    showMessage(AppLocalizations.of(context)!.completing);
    SubCalendarEvent subTile = _subEvent ?? this.widget.subEvent;
    final scheduleState = this.context.read<ScheduleBloc>().state;
    if (scheduleState is ScheduleEvaluationState) {
      DateTime timeOutTime = Utility.currentTime().subtract(Utility.oneMin);
      if (scheduleState.evaluationTime.isAfter(timeOutTime)) {
        return;
      }
    }

    List<SubCalendarEvent> renderedSubEvents = [];
    List<Timeline> timeLines = [];
    Timeline lookupTimeline = Utility.todayTimeline();
    ScheduleStatus scheduleStatus = ScheduleStatus();

    if (scheduleState is ScheduleLoadedState) {
      renderedSubEvents = scheduleState.subEvents;
      timeLines = scheduleState.timelines;
      lookupTimeline = scheduleState.lookupTimeline;
      scheduleStatus = scheduleState.scheduleStatus;
    }

    if (scheduleState is ScheduleEvaluationState) {
      renderedSubEvents = scheduleState.subEvents;
      timeLines = scheduleState.timelines;
      lookupTimeline = scheduleState.lookupTimeline;
      scheduleStatus = scheduleState.scheduleStatus;
    }

    if (scheduleState is ScheduleLoadingState) {
      renderedSubEvents = scheduleState.subEvents;
      timeLines = scheduleState.timelines;
      lookupTimeline = scheduleState.previousLookupTimeline;
      scheduleStatus = scheduleState.scheduleStatus;
    }

    var requestFuture = _subCalendarEventApi.complete((subTile));
    if (this.widget.callBack != null) {
      this.widget.callBack!(PlaybackOptions.Complete, requestFuture);
    }

    context.read<ScheduleBloc>().add(EvaluateSchedule(
        renderedSubEvents: renderedSubEvents,
        renderedTimelines: timeLines,
        renderedScheduleTimeline: lookupTimeline,
        scheduleStatus: scheduleStatus,
        isAlreadyLoaded: true,
        callBack: requestFuture));
    if(widget.isWeeklyView) Navigator.pop(context);
  }

  deleteTile() async {
    showMessage(AppLocalizations.of(context)!.deleting);
    SubCalendarEvent subTile = _subEvent ?? this.widget.subEvent;
    final scheduleState = this.context.read<ScheduleBloc>().state;
    if (scheduleState is ScheduleEvaluationState) {
      DateTime timeOutTime = Utility.currentTime().subtract(Utility.oneMin);
      if (scheduleState.evaluationTime.isAfter(timeOutTime)) {
        return;
      }
    }

    List<SubCalendarEvent> renderedSubEvents = [];
    List<Timeline> timeLines = [];
    Timeline lookupTimeline = Utility.todayTimeline();
    ScheduleStatus scheduleStatus = ScheduleStatus();

    if (scheduleState is ScheduleLoadedState) {
      renderedSubEvents = scheduleState.subEvents;
      timeLines = scheduleState.timelines;
      lookupTimeline = scheduleState.lookupTimeline;
      scheduleStatus = scheduleState.scheduleStatus;
    }

    if (scheduleState is ScheduleEvaluationState) {
      renderedSubEvents = scheduleState.subEvents;
      timeLines = scheduleState.timelines;
      lookupTimeline = scheduleState.lookupTimeline;
      scheduleStatus = scheduleState.scheduleStatus;
    }

    if (scheduleState is ScheduleLoadingState) {
      renderedSubEvents = scheduleState.subEvents;
      timeLines = scheduleState.timelines;
      lookupTimeline = scheduleState.previousLookupTimeline;
      scheduleStatus = scheduleState.scheduleStatus;
    }

    var requestFuture = _subCalendarEventApi.delete(
        subTile.id!,
        subTile.thirdpartyId,
        subTile.thirdPartyUserId,
        subTile.thirdpartyType?.name.toString().toLowerCase() ?? "");

    context.read<ScheduleBloc>().add(EvaluateSchedule(
        renderedSubEvents: renderedSubEvents,
        renderedTimelines: timeLines,
        renderedScheduleTimeline: lookupTimeline,
        isAlreadyLoaded: true,
        scheduleStatus: ScheduleStatus(),
        callBack: requestFuture));
    if (this.widget.callBack != null) {
      this.widget.callBack!(PlaybackOptions.Delete, requestFuture);
    }
    if(widget.isWeeklyView) Navigator.pop(context);
  }

  procrastinate() async {
    SubCalendarEvent subTile = _subEvent ?? this.widget.subEvent;
    if (subTile.id != null && subTile.id!.isNotEmpty) {
      if(widget.isWeeklyView) Navigator.pop(context);
        Navigator.of(context).push(
           MaterialPageRoute(
               builder: (context) =>
                   TileProcrastinateRoute(
                     tileId: subTile.id!,
                     callBack: this.widget.callBack,
                   )));
    }
  }

  @override
  Widget build(BuildContext context) {
    Set<PlaybackOptions> alreadyAddedButton = Set<PlaybackOptions>();
    Widget? playPauseButton;
    Widget? deleteButton;
    Widget? setAsNowButton;
    Widget? procrastinateButton;
    Widget? completeButton;
    var playBackElements = <Widget>[];
    if ((widget.subEvent.isFromTiler)) {
      completeButton = GestureDetector(
          onTap: completeTile,
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                child: Icon(Icons.check),
                decoration: BoxDecoration(
                    color: Color.fromRGBO(31, 31, 31, .1),
                    borderRadius: BorderRadius.circular(25)),
              ),
              Text(AppLocalizations.of(context)!.complete,
                  style: TextStyle(fontSize: 12))
            ],
          ));
      playBackElements.add(completeButton);
    }
    alreadyAddedButton.add(PlaybackOptions.Complete);

    deleteButton = Column(
      children: [
        GestureDetector(
            onTap: deleteTile,
            child: Container(
              width: 50,
              height: 50,
              margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
              child: Icon(
                Icons.close,
                size: 35,
              ),
              decoration: BoxDecoration(
                  color: Color.fromRGBO(31, 31, 31, .1),
                  borderRadius: BorderRadius.circular(25)),
            )),
        Text(AppLocalizations.of(context)!.delete,
            style: TextStyle(fontSize: 12))
      ],
    );

    setAsNowButton = Column(
      children: [
        GestureDetector(
            onTap: setAsNowTile,
            child: Container(
              width: 50,
              height: 50,
              margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
              child: Transform.rotate(
                angle: -pi / 2,
                child: Icon(
                  Icons.chevron_right,
                  size: 35,
                ),
              ),
              decoration: BoxDecoration(
                  color: Color.fromRGBO(31, 31, 31, .1),
                  borderRadius: BorderRadius.circular(25)),
            )),
        Text(AppLocalizations.of(context)!.now, style: TextStyle(fontSize: 12))
      ],
    );

    if (((widget.subEvent.isFromTiler)) &&
        (!(widget.subEvent.isProcrastinate ?? false)) &&
        (!(widget.subEvent.isCurrent ||
            (widget.subEvent.isPaused != null && widget.subEvent.isPaused!)))) {
      playBackElements.add(setAsNowButton);
      alreadyAddedButton.add(PlaybackOptions.Now);
    }
    procrastinateButton = Column(
      children: [
        GestureDetector(
            onTap: procrastinate,
            child: Container(
              width: 50,
              height: 50,
              margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
              child: Transform.rotate(
                angle: 0,
                child: Icon(
                  Icons.chevron_right,
                  size: 35,
                ),
              ),
              decoration: BoxDecoration(
                  color: Color.fromRGBO(31, 31, 31, .1),
                  borderRadius: BorderRadius.circular(25)),
            )),
        Text(AppLocalizations.of(context)!.defer,
            style: TextStyle(fontSize: 12))
      ],
    );

    if (widget.subEvent.isRigid == null ||
        (widget.subEvent.isRigid != null && !widget.subEvent.isRigid!)) {
      playBackElements.add(procrastinateButton);
      alreadyAddedButton.add(PlaybackOptions.Procrastinate);
    }

    if ((widget.subEvent.isRigid != null && !widget.subEvent.isRigid!) &&
        (widget.subEvent.isCurrent ||
            (widget.subEvent.isPaused != null && widget.subEvent.isPaused!))) {
      playPauseButton = Column(
        children: [
          GestureDetector(
            onTap: pauseTile,
            child: Container(
              width: 50,
              height: 50,
              margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
              child: Icon(Icons.pause_rounded),
              decoration: BoxDecoration(
                  color: Color.fromRGBO(31, 31, 31, .1),
                  borderRadius: BorderRadius.circular(25)),
            ),
          ),
          Text(AppLocalizations.of(context)!.pause,
              style: TextStyle(fontSize: 12))
        ],
      );

      if (widget.subEvent.isPaused != null && widget.subEvent.isPaused!) {
        playPauseButton = Column(
          children: [
            GestureDetector(
              onTap: resumeTile,
              child: Container(
                width: 50,
                height: 50,
                margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                child: Icon(Icons.play_arrow_rounded),
                decoration: BoxDecoration(
                    color: Color.fromRGBO(31, 31, 31, .1),
                    borderRadius: BorderRadius.circular(25)),
              ),
            ),
            Text(AppLocalizations.of(context)!.resume,
                style: TextStyle(fontSize: 12))
          ],
        );
      }
      if (playBackElements.isNotEmpty) {
        playBackElements.insert(1, playPauseButton as Column);
      } else {
        playBackElements.add(playPauseButton as Column);
      }
      alreadyAddedButton.add(PlaybackOptions.PlayPause);
    }

    if (this.widget.forcedOption != null) {
      for (PlaybackOptions playbackOptions in this.widget.forcedOption!) {
        if (!alreadyAddedButton.contains(playbackOptions)) {
          switch (playbackOptions) {
            case PlaybackOptions.PlayPause:
              if (playPauseButton != null) {
                playBackElements.add(playPauseButton);
              }
              break;
            case PlaybackOptions.Now:
              if (setAsNowButton != null) {
                playBackElements.add(setAsNowButton);
              }
              break;
            case PlaybackOptions.Procrastinate:
              if (procrastinateButton != null) {
                playBackElements.add(procrastinateButton);
              }
              break;
            case PlaybackOptions.Delete:
              if (deleteButton != null) {
                playBackElements.add(deleteButton);
              }
              break;
            case PlaybackOptions.Complete:
              if (completeButton != null) {
                playBackElements.add(completeButton);
              }
              break;

            default:
          }
        }
      }
    }

    const maxButtonPerRow = 3;
    List<Widget> playBackRows = <Widget>[];
    for (int i = 0; i < playBackElements.length;) {
      List<Widget> rowElements = <Widget>[];
      for (int j = 0;
          j < maxButtonPerRow && i < playBackElements.length;
          j++, i++) {
        rowElements.add(playBackElements[i]);
      }
      if (rowElements.isNotEmpty) {
        playBackRows.add(Container(
          margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: rowElements,
          ),
        ));
      }
    }
    Widget playBackColumn = Column(
      children: playBackRows,
    );

    return Container(child: playBackColumn);
  }
}
