import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/components/tileUI/tilerCheckBox.dart';
import 'package:tiler_app/data/restrictionDay.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

class _DayOfWeekRestriction {
  String weekDayText = '';
  int dayIndex = -1;
  TimeOfDay start = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay end = TimeOfDay(hour: 18, minute: 0);
  bool isSelected = false;
  _DayOfWeekRestriction({required this.weekDayText, required this.dayIndex});
  RestrictionDay toRestrictionDay() {
    Duration duration = Duration(
        milliseconds: (end.durationFromMidnight - start.durationFromMidnight));
    var retValue = RestrictionDay(
        restrictionTimeLine: RestrictionTimeLine(
            duration: duration, start: this.start, weekDay: this.dayIndex));
    retValue.weekday = this.dayIndex;
    return retValue;
  }
}

class CustomTimeRestrictionRoute extends StatefulWidget {
  Map? params;
  @override
  State<StatefulWidget> createState() => CustomTimeRestrictionRouteState();
}

class CustomTimeRestrictionRouteState
    extends State<CustomTimeRestrictionRoute> {
  final List<String> weekdays = [
    'sunday',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday'
  ];
  final NumberFormat doubleZeroFormatter = new NumberFormat('00');
  Map<String, _DayOfWeekRestriction> mapOfWeekDayToDayRestriction = {};
  Map paramArgs = {};
  RestrictionProfile? restrictionProfileParams;
  bool isMapOfDayRestrictionInitialized = false;
  static String routeName = '/CustomRestrictionsRoute';
  @override
  void initState() {
    super.initState();
  }

  Future<TimeOfDay?> _selectTime(
      BuildContext context, TimeOfDay selectedTime) async {
    final TimeOfDay? timeOfDay = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      initialEntryMode: TimePickerEntryMode.dial,
    );

    return timeOfDay;
  }

  _initializeDayRestrictions() {
    var localMapOfWeekDayToDayRestriction = mapOfWeekDayToDayRestriction;
    List checkBoxText = [
      AppLocalizations.of(this.context)!.sunday,
      AppLocalizations.of(this.context)!.monday,
      AppLocalizations.of(this.context)!.tuesday,
      AppLocalizations.of(this.context)!.wednesday,
      AppLocalizations.of(this.context)!.thursday,
      AppLocalizations.of(this.context)!.friday,
      AppLocalizations.of(this.context)!.saturday
    ];

    localMapOfWeekDayToDayRestriction['sunday'] = _DayOfWeekRestriction(
        weekDayText: AppLocalizations.of(this.context)!.sunday, dayIndex: 0);
    localMapOfWeekDayToDayRestriction['monday'] = _DayOfWeekRestriction(
        weekDayText: AppLocalizations.of(this.context)!.monday, dayIndex: 1);
    localMapOfWeekDayToDayRestriction['tuesday'] = _DayOfWeekRestriction(
        weekDayText: AppLocalizations.of(this.context)!.tuesday, dayIndex: 2);
    localMapOfWeekDayToDayRestriction['wednesday'] = _DayOfWeekRestriction(
        weekDayText: AppLocalizations.of(this.context)!.wednesday, dayIndex: 3);
    localMapOfWeekDayToDayRestriction['thursday'] = _DayOfWeekRestriction(
        weekDayText: AppLocalizations.of(this.context)!.thursday, dayIndex: 4);
    localMapOfWeekDayToDayRestriction['friday'] = _DayOfWeekRestriction(
        weekDayText: AppLocalizations.of(this.context)!.friday, dayIndex: 5);
    localMapOfWeekDayToDayRestriction['saturday'] = _DayOfWeekRestriction(
        weekDayText: AppLocalizations.of(this.context)!.saturday, dayIndex: 6);

    Map args = ModalRoute.of(context)?.settings.arguments as Map;
    this.widget.params = args;
    if (args.containsKey('restrictionProfile')) {
      RestrictionProfile? restrictionProfileParams = args['restrictionProfile'];
      this.restrictionProfileParams = restrictionProfileParams;
    }
    if (this.restrictionProfileParams != null) {
      for (int i = 0;
          i < this.restrictionProfileParams!.daySelection.length;
          i++) {
        var restrictionDay = this.restrictionProfileParams!.daySelection[i];
        if (restrictionDay != null) {
          var dayOfWeekRestriction = _DayOfWeekRestriction(
              weekDayText: checkBoxText[restrictionDay.weekday!],
              dayIndex: restrictionDay.weekday!);
          dayOfWeekRestriction.isSelected = true;
          localMapOfWeekDayToDayRestriction[weekdays[restrictionDay.weekday!]] =
              dayOfWeekRestriction;

          if (restrictionDay.restrictionTimeLine != null) {
            if (restrictionDay.restrictionTimeLine!.start != null &&
                restrictionDay.restrictionTimeLine!.duration != null) {
              dayOfWeekRestriction.start =
                  restrictionDay.restrictionTimeLine!.start!;
              DateTime startDateTime = DateTime(
                  2022,
                  1,
                  1,
                  dayOfWeekRestriction.start.hour,
                  dayOfWeekRestriction.start.minute);
              dayOfWeekRestriction.end = TimeOfDay.fromDateTime(startDateTime
                  .add(restrictionDay.restrictionTimeLine!.duration!));
            }
          }
        }
      }
    }

    setState(() {
      isMapOfDayRestrictionInitialized = true;
      mapOfWeekDayToDayRestriction = localMapOfWeekDayToDayRestriction;
      paramArgs = args;
    });
  }

  Widget generateEachDayWidget(_DayOfWeekRestriction dayOfWeekRestriction) {
    BoxDecoration timeBoxDecoration = BoxDecoration(
        border: Border(bottom: BorderSide(color: TileStyles.disabledColor)));
    if (dayOfWeekRestriction.isSelected) {
      timeBoxDecoration =
          BoxDecoration(color: HSLColor.fromAHSL(0.12, 198, 1, 0.33).toColor());
    }

    Widget retValue = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TilerCheckBox(
          text: dayOfWeekRestriction.weekDayText,
          isChecked: dayOfWeekRestriction.isSelected,
          onChange: (TilerCheckBoxState checkBoxState) {
            var mapOfWeekDays = this.mapOfWeekDayToDayRestriction;
            bool isSelected = checkBoxState.isChecked;
            dayOfWeekRestriction.isSelected = isSelected;
            mapOfWeekDays[this.weekdays[dayOfWeekRestriction.dayIndex]] =
                dayOfWeekRestriction;
            this.setState(() {
              mapOfWeekDayToDayRestriction = mapOfWeekDays;
            });
          },
        ),
        Container(
          width: 140,
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            GestureDetector(
                onTap: () async {
                  var mapOfWeekDays = this.mapOfWeekDayToDayRestriction;
                  if (dayOfWeekRestriction.isSelected) {
                    TimeOfDay? timeOfDay = await _selectTime(
                        this.context, dayOfWeekRestriction.start);
                    if (timeOfDay != null) {
                      dayOfWeekRestriction.start = timeOfDay;
                      mapOfWeekDays[
                              this.weekdays[dayOfWeekRestriction.dayIndex]] =
                          dayOfWeekRestriction;
                    }
                    this.setState(() {
                      mapOfWeekDayToDayRestriction = mapOfWeekDays;
                    });
                  }
                },
                child: Container(
                    width: 45,
                    height: 45,
                    decoration: timeBoxDecoration,
                    child: Center(
                      child: Text(
                          '${doubleZeroFormatter.format(dayOfWeekRestriction.start.hour)}:${doubleZeroFormatter.format(dayOfWeekRestriction.start.minute)}'),
                    ))),
            Center(child: Text('-')),
            GestureDetector(
              onTap: () async {
                var mapOfWeekDays = this.mapOfWeekDayToDayRestriction;
                if (dayOfWeekRestriction.isSelected) {
                  TimeOfDay? timeOfDay =
                      await _selectTime(this.context, dayOfWeekRestriction.end);
                  if (timeOfDay != null) {
                    dayOfWeekRestriction.end = timeOfDay;
                    mapOfWeekDays[
                            this.weekdays[dayOfWeekRestriction.dayIndex]] =
                        dayOfWeekRestriction;
                  }
                  this.setState(() {
                    mapOfWeekDayToDayRestriction = mapOfWeekDays;
                  });
                }
              },
              child: Container(
                  width: 45,
                  height: 45,
                  decoration: timeBoxDecoration,
                  child: Center(
                      child: Text(
                          '${doubleZeroFormatter.format(dayOfWeekRestriction.end.hour)}:${doubleZeroFormatter.format(dayOfWeekRestriction.end.minute)}'))),
            ),
          ]),
        )
      ],
    );
    return retValue;
  }

  @override
  Widget build(BuildContext context) {
    Map restrictionProfileParams =
        ModalRoute.of(context)?.settings.arguments as Map;
    this.widget.params = restrictionProfileParams;
    if (!isMapOfDayRestrictionInitialized) {
      _initializeDayRestrictions();
    }

    return CancelAndProceedTemplateWidget(
        onProceed: () {
          List<RestrictionDay?> daySelections = this
              .mapOfWeekDayToDayRestriction
              .values
              .map((dayRestriction) => dayRestriction.isSelected
                  ? dayRestriction.toRestrictionDay()
                  : null)
              .toList();
          RestrictionProfile restrictionProfile =
              RestrictionProfile(daySelection: daySelections);
          this.paramArgs['restrictionProfile'] = restrictionProfile;
          List<String> stackRouteHistory = [];
          if (this.widget.params != null) {
            this.widget.params!['restrictionProfile'] = restrictionProfile;
            if (this.widget.params!.containsKey('stackRouteHistory'))
              stackRouteHistory = this.widget.params!['stackRouteHistory'];
          }

          if (stackRouteHistory.length > 0) {
            Navigator.popUntil(
                context, (ModalRoute.withName(stackRouteHistory.first)));
          }
          ;
        },
        child: Scaffold(
          body: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                child: Column(children: [
                  Text(
                    AppLocalizations.of(context)!.customRestrictionTitle,
                  ),
                  Text(
                    AppLocalizations.of(context)!.setupCustomRestrictions,
                  ),
                  Text(
                    AppLocalizations.of(context)!
                        .customRestrictionHeaderDescription,
                  )
                ]),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(0, 70, 0, 70),
                child: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: this
                            .weekdays
                            .map((weekdayString) => generateEachDayWidget(this
                                .mapOfWeekDayToDayRestriction[weekdayString]!))
                            .toList())),
              )
            ],
          ),
        ));
  }
}