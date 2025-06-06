import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/components/tileUI/configUpdateButton.dart';
import 'package:tiler_app/data/adHoc/autoTile.dart';
import 'package:tiler_app/data/adHoc/preTile.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeRangeMix.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/singleChoice.dart';

import 'package:tiler_app/routes/authenticatedUser/startEndDurationTimeline.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/api/locationApi.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/settingsApi.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tuple/tuple.dart';
import '../../../bloc/schedule/schedule_bloc.dart';
import '../../../constants.dart' as Constants;

class AddTile extends StatefulWidget {
  final Function? onAddTileClose;
  final Function? onAddingATile;
  final PreTile? preTile;
  final DateTime? autoDeadline;
  static final String routeName = '/AddTile';
  Map? newTileParams;

  AddTile(
      {this.preTile,
      this.autoDeadline,
      this.onAddTileClose,
      this.onAddingATile,
      Key? key})
      : super(key: key);
  @override
  AddTileState createState() => AddTileState();
}

class AddTileState extends State<AddTile> {
  Key switchUpKey = Key(Utility.getUuid);
  late AutoTile? autoTile;
  bool isAppointment = false;
  final Color textBackgroundColor = TileStyles.textBackgroundColor;
  final Color textBorderColor = TileStyles.textBorderColor;
  final Color inputFieldIconColor = Color(0xFFEF3054); // Changed to #EF3054
  final Color iconColor = Color(0xFFEF3054);
  // final Color inputFieldIconColor = TileStyles.primaryColorDarkHSL.toColor();
  // final Color iconColor = TileStyles.primaryColorDarkHSL.toColor();
  final Color populatedTextColor = Colors.white;
  final CarouselSliderController tilerCarouselController =
      CarouselSliderController();
  String tileNameText = '';
  String splitCountText = '';

  Location? _homeLocation;
  Location? _workLocation;
  final BoxDecoration boxDecoration = TileStyles.configUpdate_notSelected;
  final BoxDecoration populatedDecoration = TileStyles.configUpdate_Selected;
  TextEditingController tileNameController = TextEditingController();
  TextEditingController tileDeadline = TextEditingController();
  TextEditingController splitCountController = TextEditingController();
  Duration? _duration = Duration(hours: 0, minutes: 0);
  bool _isDurationManuallySet = false;
  Location? _location = Location.fromDefault();
  RepetitionData? _repetitionData;
  Color? _color;
  bool _isLocationManuallySet = false;
  DateTime? _startTime = Utility.currentTime();
  DateTime? _endTime;
  bool _isAutoRevisable = true;

  Function? onProceed;

  String? _restrictionProfileName;
  RestrictionProfile? _restrictionProfile;
  bool _isRestictionProfileManuallySet = false;
  late ScheduleApi scheduleApi;
  late SettingsApi settingsApi;
  late final LocationApi locationApi;
  StreamSubscription? pendingSendTextRequest;
  List<Tuple2<String, RestrictionProfile>>? _listedRestrictionProfile;
  Tuple2<String, RestrictionProfile>? _workRestrictionProfile;
  Tuple2<String, RestrictionProfile>? _personalRestrictionProfile;
  TilePriority priority = TilePriority.medium;
  static final String addTileCancelAndProceedRouteName =
      "addTileCancelAndProceedRouteName";

  final EdgeInsets configUpdateIconPadding =
      const EdgeInsets.fromLTRB(5, 2, 5, 5);
  final EdgeInsets configUpdatePadding =
      const EdgeInsets.fromLTRB(5, 10, 10, 7);
  bool isPendingAutoResult = false;
  final inputBorderRadius = TileStyles.inputFieldRadius;

  @override
  void initState() {
    scheduleApi = ScheduleApi(getContextCallBack: () => context);
    settingsApi = SettingsApi(getContextCallBack: () => context);
    locationApi = LocationApi(getContextCallBack: () => context);
    if (this.widget.autoDeadline != null) {
      _endTime = this.widget.autoDeadline!;
    }
    if (this.widget.preTile != null) {
      _location = this.widget.preTile!.location;
      print("location in preTile: ${_location}");
      tileNameController =
          TextEditingController(text: this.widget.preTile!.description);
      _duration = this.widget.preTile!.duration;
      _startTime = this.widget.preTile!.startTime ?? Utility.currentTime();
      if (_duration != null) {
        _isDurationManuallySet = true;
      }
      if (_location == null) {
        var future = new Future.delayed(
            const Duration(milliseconds: Constants.onTextChangeDelayInMs));
        // ignore: cancel_subscriptions
        StreamSubscription streamSubScription =
            future.asStream().listen((event) {
          if (this
              .widget
              .preTile!
              .description
              .isNot_NullEmptyOrWhiteSpace(minLength: 3)) {
            setState(() {
              isPendingAutoResult = true;
            });
            this
                .scheduleApi
                .getAutoResult(this.widget.preTile!.description!)
                .then((remoteTileResponse) {
              setState(() {
                isPendingAutoResult = false;
              });
              Location? _locationResponse;
              if (remoteTileResponse.item2.isNotEmpty) {
                _locationResponse = remoteTileResponse.item2.last;
              }
              if (mounted) {
                setState(() {
                  if (!_isLocationManuallySet) {
                    updateLocation(_locationResponse);
                  }
                });
                isSubmissionReady();
              }
            }).whenComplete(() {
              if (mounted) {
                setState(() {
                  isPendingAutoResult = false;
                });
              }
            });
          }
        });

        setState(() {
          pendingSendTextRequest = streamSubScription;
        });
      }
    }

    splitCountController.addListener(() {
      if (splitCountText != splitCountController.text) {
        setState(() {
          splitCountText = splitCountController.text;
        });
        isSubmissionReady();
      }
    });
    tileNameController.addListener(onTileNameInput);
    if (tileNameController.text.isNotEmpty) {
      onTileNameInput();
    }

    locationApi
        .getSpecificLocationByNickName(Location.homeLocationNickName)
        .then((homeLocation) {
      locationApi
          .getSpecificLocationByNickName(Location.workLocationNickName)
          .then((workLocation) {
        setState(() {
          _homeLocation = homeLocation;
          _workLocation = workLocation;
        });
      });
    });

    settingsApi.getUserRestrictionProfile().then((response) {
      if (response.length > 0) {
        setState(() {
          _listedRestrictionProfile = response.entries
              .map<Tuple2<String, RestrictionProfile>>(
                  (e) => Tuple2<String, RestrictionProfile>(e.key, e.value))
              .toList();
          if (_listedRestrictionProfile != null) {
            _workRestrictionProfile = _listedRestrictionProfile!
                .where((element) =>
                    element.item1.toLowerCase() ==
                    Constants.workProfileNickName)
                .firstOrNull;
            _personalRestrictionProfile = _listedRestrictionProfile!
                .where((element) =>
                    element.item1.toLowerCase() ==
                    Constants.homeProfileNickName)
                .firstOrNull;
          }
        });
        return response;
      }
      setState(() {
        _listedRestrictionProfile = null;
      });
      return response;
    });

    super.initState();
  }

  void _onProceedTap() {
    return this.onSubmitButtonTap();
  }

  void onTileNameInput() {
    if (tileNameText != tileNameController.text) {
      if (tileNameController.text.length >
          Constants.autoCompleteTriggerCharacterCount) {
        Function callAutoResult = generateSuggestionCallToServer();
        callAutoResult();
      }
      setState(() {
        tileNameText = tileNameController.text;
      });
      isSubmissionReady();
    }
  }

  void updateLocation(Location? location) {
    print("in updateLocation");
    setState(() {
      _location = location;
      if (location != null) {
        _location!.isDefault = false;
        _location!.isNull = false;
        if (!_isRestictionProfileManuallySet &&
            _location != null &&
            _listedRestrictionProfile != null &&
            _listedRestrictionProfile!.isNotEmpty) {
          if (_location!.description != null &&
              _location!.description!.toLowerCase() ==
                  Constants.workLocationNickName &&
              _workRestrictionProfile != null) {
            _restrictionProfile = _workRestrictionProfile!.item2;
            _restrictionProfileName =
                AppLocalizations.of(context)!.workProfileHours;
          }
          if (_location!.description != null &&
              _location!.description!.toLowerCase() ==
                  Constants.homeLocationNickName &&
              _personalRestrictionProfile != null) {
            _restrictionProfile = _personalRestrictionProfile!.item2;
            _restrictionProfileName =
                AppLocalizations.of(context)!.personalHours;
          }
        }
      }
    });
  }

  isSubmissionReady() {
    bool isDurationReady = false;
    bool isNameReady = false;
    bool isCountReady = false;
    if (_duration != null &&
        _duration!.inMilliseconds > Utility.oneMin.inMilliseconds) {
      isDurationReady = true;
    }

    if (tileNameController.text.trim().isNotEmpty) {
      isNameReady = true;
    }

    int? count = int.tryParse(getSplitCount());
    if (count != null && count > 0) {
      isCountReady = true;
    }
    if (isAppointment) {
      isCountReady = true;
    }

    if (isNameReady && isDurationReady && isCountReady && isRepetitionValid()) {
      setState(() {
        onProceed = _onProceedTap;
      });
    } else {
      setState(() {
        onProceed = null;
      });
    }
  }

  String? getTimeOfDaySectionString(List<String>? timeOfDayString) {
    const String morning = "morning";
    const String afternoon = "afternoon";
    const String evening = "evening";
    const String night = "night";

    if (timeOfDayString == null || timeOfDayString.isEmpty) {
      return null;
    }

    if (timeOfDayString.length == 1) {
      switch (timeOfDayString[0].toLowerCase()) {
        case morning:
          return AppLocalizations.of(context)!.morning;
        case afternoon:
          return AppLocalizations.of(context)!.afternoon;
        case evening:
          return AppLocalizations.of(context)!.evening;
        case night:
          return AppLocalizations.of(context)!.night;
        default:
          return null;
      }
    }
    if (timeOfDayString.length == 2) {
      if (timeOfDayString
              .where((element) =>
                  element.toLowerCase() == morning ||
                  element.toLowerCase() == afternoon)
              .length ==
          2) {
        return AppLocalizations.of(context)!.morningAndAfternoon;
      }
      if (timeOfDayString
              .where((element) =>
                  element.toLowerCase() == afternoon ||
                  element.toLowerCase() == evening)
              .length ==
          2) {
        return AppLocalizations.of(context)!.afternoonAndEvening;
      }

      if (timeOfDayString
              .where((element) =>
                  element.toLowerCase() == morning ||
                  element.toLowerCase() == evening)
              .length ==
          2) {
        return AppLocalizations.of(context)!.night;
      }

      if (timeOfDayString
              .where((element) =>
                  element.toLowerCase() == night ||
                  element.toLowerCase() == evening)
              .length ==
          2) {
        return AppLocalizations.of(context)!.night;
      }
    }

    return null;
  }

  Function generateSuggestionCallToServer() {
    if (pendingSendTextRequest != null) {
      pendingSendTextRequest!.cancel();
    }

    Function retValue = () async {
      if (_isDurationManuallySet && _isLocationManuallySet ||
          (this.widget.preTile != null &&
              this.widget.preTile!.duration != null &&
              this.widget.preTile!.location != null)) {
        return;
      }
      var future = new Future.delayed(
          const Duration(milliseconds: Constants.onTextChangeDelayInMs));
      // ignore: cancel_subscriptions
      StreamSubscription streamSubScription = future.asStream().listen((event) {
        setState(() {
          isPendingAutoResult = true;
        });
        this
            .scheduleApi
            .getAutoResult(tileNameController.text)
            .then((remoteTileResponse) {
          Duration? _durationResponse;
          Location? _locationResponse;
          RestrictionProfile? _restrictionProfileResponse;
          if (remoteTileResponse.item1.isNotEmpty) {
            _durationResponse = remoteTileResponse.item1.last;
          }
          if (remoteTileResponse.item2.isNotEmpty) {
            _locationResponse = remoteTileResponse.item2.last;
          }
          if (remoteTileResponse.item3.isEnabled) {
            _restrictionProfileResponse = remoteTileResponse.item3;
          }
          if (mounted) {
            setState(() {
              if (!_isDurationManuallySet) {
                _duration = _durationResponse;
              }
              if (!_isRestictionProfileManuallySet) {
                _restrictionProfile = _restrictionProfileResponse;
                _restrictionProfileName =
                    getTimeOfDaySectionString(remoteTileResponse.item4);
              }
              if (!_isLocationManuallySet) {
                Location? location = _locationResponse;
                if (_locationResponse != null &&
                    _locationResponse.address != null &&
                    _locationResponse.description != null) {
                  String address = _locationResponse.address!.toLowerCase();
                  String description =
                      _locationResponse.description!.toLowerCase();
                  bool resetLocation = Constants.invalidLocationNames.any(
                      (element) =>
                          element == address || element == description);
                  if (resetLocation) {
                    location = null;
                  }
                }
                updateLocation(location);
              }
            });
            isSubmissionReady();
          }
        }).whenComplete(() {
          if (mounted) {
            setState(() {
              isPendingAutoResult = false;
            });
          }
        });
      });
      if (mounted) {
        setState(() {
          pendingSendTextRequest = streamSubScription;
        });
      }
    };

    return retValue;
  }

  String getSplitCount() {
    return this.splitCountController.value.text.isNotEmpty
        ? this.splitCountController.value.text
        : 1.toString();
  }

  Widget getTileNameWidget() {
    Widget tileNameContainer = FractionallySizedBox(
        widthFactor: TileStyles.widthRatio,
        child: Container(
            width: 380,
            margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
            child: TextField(
              controller: tileNameController,
              style: TextStyle(
                color: TileStyles.black,
                fontSize: 20,
                fontFamily: TileStyles.rubikFontName,
              ),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.tileNameStar,
                hintStyle: TextStyle(color: TileStyles.inactiveTextColor
                    // TileStyles.primaryColorDarkHSL.toColor()
                    ),
                filled: true,
                isDense: true,
                contentPadding: TileStyles.inputFieldPadding,
                fillColor: TileStyles.primaryContrastColor,
                border: OutlineInputBorder(
                  borderRadius: TileStyles.inputFieldBorderRadius,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: TileStyles.inputFieldBorderRadius,
                  borderSide: BorderSide(color: textBorderColor, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: TileStyles.inputFieldBorderRadius,
                  borderSide: BorderSide(
                    color: textBorderColor,
                    width: 1.5,
                  ),
                ),
              ),
            )));
    return tileNameContainer;
  }

  Widget getSplitCountWidget() {
    Widget splitCountContainer = FractionallySizedBox(
      widthFactor: TileStyles.widthRatio,
      child: Container(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppLocalizations.of(context)!.howManyTimes,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            SizedBox(
                width: 60,
                child: TextField(
                  controller: splitCountController,
                  keyboardType: TextInputType.numberWithOptions(
                      signed: true, decimal: true),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.once,
                    hintStyle: TextStyle(color: TileStyles.primaryColor),
                    filled: true,
                    isDense: true,
                    contentPadding: EdgeInsets.all(10),
                    fillColor: textBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(
                        const Radius.circular(50.0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        inputBorderRadius,
                      ),
                      borderSide: BorderSide(color: Colors.white, width: 0.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(inputBorderRadius),
                      borderSide:
                          BorderSide(color: textBorderColor, width: 0.5),
                    ),
                  ),
                ))
          ],
        ),
      ),
    );
    return splitCountContainer;
  }

  Widget generateDurationPicker() {
    final void Function()? setDuration = () async {
      Map<String, dynamic> durationParams = {'duration': _duration};
      Navigator.pushNamed(context, '/DurationDial', arguments: durationParams)
          .whenComplete(() {
        AnalysticsSignal.send('ADD_TILE_NEWTILE_MANUAL_DURATION_ADDED');
        print('done with pop');
        print(durationParams['duration']);
        Duration? populatedDuration = durationParams['duration'] as Duration?;
        setState(() {
          if (populatedDuration != null) {
            _duration = populatedDuration;
            _isDurationManuallySet = true;
          }
        });
        isSubmissionReady();
      });
    };
    String textButtonString = AppLocalizations.of(context)!.durationStar;
    if (_duration != null && _duration!.inMinutes > 1) {
      textButtonString = "";
      int hour = _duration!.inHours.floor();
      int minute = _duration!.inMinutes.remainder(60);
      if (hour > 0) {
        textButtonString = '${hour}h';
        if (minute > 0) {
          textButtonString = '${textButtonString} : ${minute}m';
        }
      } else {
        if (minute > 0) {
          textButtonString = '${minute}m';
        }
      }
    }
    Widget retValue = new GestureDetector(
      onTap: setDuration,
      child: FractionallySizedBox(
        widthFactor: TileStyles.widthRatio,
        child: Container(
          margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
          padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
          decoration: BoxDecoration(
              color: TileStyles.primaryContrastColor,
              borderRadius: BorderRadius.all(
                inputBorderRadius,
              ),
              border: Border.all(
                color: textBorderColor,
                width: 1.5,
              )),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.timelapse_outlined, color: inputFieldIconColor),
              Container(
                padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: TextButton(
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  onPressed: setDuration,
                  child: Text(
                    textButtonString,
                    style: textButtonString ==
                            AppLocalizations.of(context)!.durationStar
                        ? TextStyle(
                            fontFamily: TileStyles.rubikFontName,
                            color: TileStyles.inactiveTextColor)
                        : TextStyle(
                            fontFamily: TileStyles.rubikFontName,
                            color: TileStyles.black),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
    return retValue;
  }

  Widget generateExtraConfigSelection() {
    String locationName = AppLocalizations.of(context)!.location;
    bool isLocationConfigSet = false;
    bool isRepetitionSet = false;
    bool isColorConfigSet = false;
    bool isTimeRestrictionConfigSet = false;
    if (_location != null) {
      if (_location!.isNotNullAndNotDefault) {
        if (_location!.description != null &&
            _location!.description!.isNotEmpty) {
          locationName = _location!.description!;
          isLocationConfigSet = true;
        } else {
          if (_location!.address != null && _location!.address!.isNotEmpty) {
            locationName = _location!.address!;
            isLocationConfigSet = true;
          }
        }
      }
    }

    if (_restrictionProfile != null &&
        _restrictionProfile!.isEnabled &&
        _restrictionProfile!.daySelection
                .where((eachRestrictionDay) => eachRestrictionDay != null)
                .length >
            0) {
      isTimeRestrictionConfigSet = true;
    }

    if (_color != null) {
      isColorConfigSet = true;
    }

    if (_repetitionData != null) {
      isRepetitionSet = _repetitionData!.isEnabled;
    }

    Widget locationConfigButton = ConfigUpdateButton(
      text: locationName,
      iconPadding: configUpdateIconPadding,
      padding: configUpdatePadding,
      prefixIcon: Icon(
        Icons.location_pin,
        color: isLocationConfigSet ? populatedTextColor : iconColor,
      ),
      decoration: isLocationConfigSet ? populatedDecoration : boxDecoration,
      textColor: isLocationConfigSet ? populatedTextColor : iconColor,
      onPress: () {
        Location locationHolder = _location ?? Location.fromDefault();
        Map<String, dynamic> locationParams = {
          'location': locationHolder,
        };
        List<Location> defaultLocations = [];

        if (_homeLocation != null && _homeLocation!.isNotNullAndNotDefault) {
          defaultLocations.add(_homeLocation!);
        }
        if (_workLocation != null && _workLocation!.isNotNullAndNotDefault) {
          defaultLocations.add(_workLocation!);
        }
        if (defaultLocations.isNotEmpty) {
          locationParams['defaults'] = defaultLocations;
        }

        Navigator.pushNamed(context, '/LocationRoute',
                arguments: locationParams)
            .whenComplete(() {
          Location? populatedLocation = locationParams['location'] as Location?;
          AnalysticsSignal.send('ADD_TILE_NEWTILE_MANUAL_LOCATION_NAVIGATION');
          setState(() {
            if (populatedLocation != null &&
                populatedLocation.isNotNullAndNotDefault != null) {
              _location = populatedLocation;
              _isLocationManuallySet = true;
              updateLocation(_location);
            }
          });
        });
      },
    );

    Widget repetitionConfigButton = ConfigUpdateButton(
        text: AppLocalizations.of(context)!.repetition,
        iconPadding: configUpdateIconPadding,
        padding: configUpdatePadding,
        prefixIcon: Icon(
          TileStyles.repetitionIcon,
          color: isRepetitionSet ? populatedTextColor : iconColor,
        ),
        decoration: isRepetitionSet
            ? (isRepetitionValid()
                ? populatedDecoration
                : TileStyles.invalidBoxDecoration)
            : boxDecoration,
        textColor: isRepetitionSet ? populatedTextColor : iconColor,
        onPress: () {
          Timeline tileTimeline = Utility.todayTimeline();
          RepetitionData? repetitionData = _repetitionData?.clone();
          DateTime deadline = DateTime(tileTimeline.startTime.year,
              tileTimeline.startTime.month, tileTimeline.startTime.day, 23, 59);
          tileTimeline =
              Timeline.fromDateTime(tileTimeline.startTime, deadline);
          if (this._endTime != null) {
            tileTimeline =
                Timeline.fromDateTime(tileTimeline.startTime, this._endTime!);
          }

          Map<String, dynamic> repetitionParams = {
            'repetitionData': repetitionData,
            'tileTimeline': tileTimeline,
          };
          AnalysticsSignal.send('ADD_TILE_NEWTILE_REPETITION_OPEN');
          Navigator.pushNamed(context, '/RepetitionRoute',
                  arguments: repetitionParams)
              .whenComplete(() {
            RepetitionData? updatedRepetitionData =
                repetitionParams['updatedRepetition'] as RepetitionData?;
            bool isRepetitionEndValid = true;
            if (repetitionParams.containsKey('isRepetitionEndValid')) {
              isRepetitionEndValid =
                  repetitionParams['isRepetitionEndValid'] ?? false;
            }

            repetitionParams['updatedRepetition'] as RepetitionData?;
            if (updatedRepetitionData != null &&
                updatedRepetitionData.isEnabled) {
              setState(() {
                _repetitionData =
                    isRepetitionEndValid ? updatedRepetitionData : null;
              });
            }
            if (!isRepetitionEndValid) {
              setState(() {
                _repetitionData = null;
              });
            }
            isSubmissionReady();
          });
        });

    Widget reminderConfigButton = ConfigUpdateButton(
        text: AppLocalizations.of(context)!.reminder,
        iconPadding: configUpdateIconPadding,
        padding: configUpdatePadding,
        prefixIcon: Icon(
          Icons.doorbell_outlined,
          color: iconColor,
        ),
        decoration: BoxDecoration(
            color: Color.fromRGBO(31, 31, 31, 0.05),
            borderRadius: BorderRadius.all(
              const Radius.circular(10.0),
            )),
        textColor: iconColor,
        onPress: () {
          final scaffold = ScaffoldMessenger.of(context);
          scaffold.showSnackBar(
            SnackBar(
              content: const Text('Reminders are disabled for now :('),
              action: SnackBarAction(
                  label: AppLocalizations.of(context)!.close,
                  onPressed: scaffold.hideCurrentSnackBar),
            ),
          );
        });

    Widget timeRestrictionsConfigButton = ConfigUpdateButton(
      iconPadding: configUpdateIconPadding,
      padding: configUpdatePadding,
      text: isTimeRestrictionConfigSet
          ? _restrictionProfileName ?? AppLocalizations.of(context)!.restriction
          : _restrictionProfileName ?? AppLocalizations.of(context)!.anytime,
      prefixIcon: Icon(
        Icons.switch_left,
        color: isTimeRestrictionConfigSet ? populatedTextColor : iconColor,
      ),
      decoration:
          isTimeRestrictionConfigSet ? populatedDecoration : boxDecoration,
      textColor: isTimeRestrictionConfigSet ? populatedTextColor : iconColor,
      onPress: () {
        Map<String, dynamic> restrictionParams = {
          'routeRestrictionProfile': _restrictionProfile,
          'stackRouteHistory': [AddTile.routeName]
        };
        if (_listedRestrictionProfile != null) {
          restrictionParams['namedRestrictionProfiles'] =
              _listedRestrictionProfile;
        }

        Navigator.pushNamed(context, '/TimeRestrictionRoute',
                arguments: restrictionParams)
            .whenComplete(() {
          RestrictionProfile? populatedRestrictionProfile;
          _isRestictionProfileManuallySet = true;
          if (restrictionParams.containsKey('routeRestrictionProfile')) {
            populatedRestrictionProfile =
                restrictionParams['routeRestrictionProfile']
                    as RestrictionProfile?;
            restrictionParams.remove('routeRestrictionProfile');
            setState(() {
              _restrictionProfile = populatedRestrictionProfile;
              _restrictionProfileName = null;
              if (_workRestrictionProfile != null &&
                  _workRestrictionProfile!.item2 == _restrictionProfile) {
                _restrictionProfileName =
                    AppLocalizations.of(context)!.workProfileHours;
              }

              if (_personalRestrictionProfile != null &&
                  _personalRestrictionProfile!.item2 == _restrictionProfile) {
                _restrictionProfileName =
                    AppLocalizations.of(context)!.personalHours;
              }
            });
          }
        });
      },
    );

    BoxDecoration colorConfigUpdateDecoration = boxDecoration;
    Color selectedColor =
        (isColorConfigSet ? (_color ?? populatedTextColor) : iconColor);
    Color inverseColor = Color.fromRGBO(255 - selectedColor.red,
        255 - selectedColor.green, 255 - selectedColor.blue, 1);
    if (isColorConfigSet) {
      colorConfigUpdateDecoration = BoxDecoration(
        borderRadius: BorderRadius.all(
          const Radius.circular(10.0),
        ),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            selectedColor.withLightness(0.5),
            selectedColor.withLightness(0.8)
          ],
        ),
      );
    }

    Widget colorPickerConfigButton = ConfigUpdateButton(
      iconPadding: configUpdateIconPadding,
      padding: configUpdatePadding,
      text: AppLocalizations.of(context)!.color,
      prefixIcon: Icon(
        Icons.contrast,
        color: isColorConfigSet ? (inverseColor) : iconColor,
      ),
      decoration: colorConfigUpdateDecoration,
      textColor: isColorConfigSet ? populatedTextColor : iconColor,
      onPress: () {
        Color? colorHolder = _color;
        Map<String, dynamic> colorParams = {'color': colorHolder};

        Navigator.pushNamed(context, '/PickColor', arguments: colorParams)
            .whenComplete(() {
          Color? populatedColor = colorParams['color'] as Color?;
          setState(() {
            isColorConfigSet = false;
            if (populatedColor != null) {
              _color = populatedColor;
              isColorConfigSet = true;
            }
          });
        });
      },
    );

    Widget softDeadlineWidget = ConfigUpdateButton(
      iconPadding: configUpdateIconPadding,
      padding: configUpdatePadding,
      decoration: _isAutoRevisable ? populatedDecoration : boxDecoration,
      textColor: _isAutoRevisable ? populatedTextColor : iconColor,
      prefixIcon: Icon(
        Icons.check,
        color: _isAutoRevisable ? populatedTextColor : iconColor,
      ),
      text: AppLocalizations.of(context)!.softDeadline,
      onPress: () {
        setState(() {
          _isAutoRevisable = !_isAutoRevisable;
        });
      },
    );

    Widget priorityButton = SingleChoice(
      onChanged: (TilePriority updatedPriotrity) {
        setState(() {
          priority = updatedPriotrity;
        });
      },
      priority: priority,
    );

    List<Widget> wrapWidgets = [
      locationConfigButton,
      colorPickerConfigButton,
      repetitionConfigButton,
    ];

    if (!this.isAppointment) {
      wrapWidgets.insert(1, timeRestrictionsConfigButton);
      wrapWidgets.add(priorityButton);
      wrapWidgets.add(softDeadlineWidget);
    }
    if (isRepetitionSet) {
      wrapWidgets.remove(softDeadlineWidget);
    }

    Widget retValue = Container(
      margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
      width: MediaQuery.of(context).size.width * TileStyles.widthRatio,
      child: Wrap(
        direction: Axis.horizontal,
        alignment: WrapAlignment.spaceAround,
        spacing: 10.0,
        runSpacing: 20.0,
        children: wrapWidgets,
      ),
    );
    return retValue;
  }

  void onEndTimeTap() async {
    DateTime _endTime = this._endTime == null
        ? Utility.todayTimeline().endTime.add(Utility.oneDay)
        : this._endTime!;
    TimeOfDay _endTimeOfDay = TimeOfDay.fromDateTime(_endTime);
    final TimeOfDay? revisedEndTime =
        await showTimePicker(context: context, initialTime: _endTimeOfDay);
    if (revisedEndTime != null) {
      DateTime updatedEndTime = new DateTime(_endTime.year, _endTime.month,
          _endTime.day, revisedEndTime.hour, revisedEndTime.minute);
      setState(() => _endTime = updatedEndTime);
    }
  }

  void onEndDateTap() async {
    DateTime _endDate =
        this._endTime ?? Utility.todayTimeline().endTime.add(Utility.oneDay);
    if (this._endTime == null) {
      _endDate = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59);
    }
    DateTime firstDate = _endDate.add(Duration(days: -180));
    DateTime lastDate = _endDate.add(Duration(days: 180));
    final DateTime? revisedEndDate = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: AppLocalizations.of(context)!.selectADeadline,
    );
    if (revisedEndDate != null) {
      DateTime updatedEndTime = new DateTime(
          revisedEndDate.year,
          revisedEndDate.month,
          revisedEndDate.day,
          _endDate.hour,
          _endDate.minute);
      setState(() => _endTime = updatedEndTime);
    }
  }

  bool isRepetitionValid() {
    bool retValue = true;
    if (_repetitionData != null) {
      if (this._endTime != null) {
        retValue = Utility.utcEpochMillisecondsFromDateTime(
                _repetitionData!.repetitionEnd!) >
            Utility.utcEpochMillisecondsFromDateTime(this._endTime!);
      }
    }

    return retValue;
  }

  void onSubmitButtonTap() async {
    AnalysticsSignal.send('ADD_TILE_NEWTILE_INITIATED');
    DateTime? _endTime = this._endTime;
    bool isAutoRevisable = false;
    if (this._isAutoRevisable) {
      isAutoRevisable = this._isAutoRevisable;
    }
    NewTile tile = new NewTile();
    tile.Name = this.tileNameController.value.text;
    if (this._duration != null) {
      tile.DurationMinute = this._duration!.inMinutes.toString();
    }

    if (_repetitionData != null) {
      tile.RepeatFrequency = _repetitionData!.frequency.name;
      if (_repetitionData!.repetitionEnd != null) {
        tile.RepeatEndYear = _repetitionData!.repetitionEnd!.year.toString();
        tile.RepeatEndMonth = _repetitionData!.repetitionEnd!.month.toString();
        tile.RepeatEndDay = _repetitionData!.repetitionEnd!.day.toString();
        _endTime = _repetitionData!.repetitionEnd;
        isAutoRevisable = false;
      }

      if (_repetitionData!.weeklyRepetition != null &&
          _repetitionData!.weeklyRepetition!.length > 0) {
        tile.RepeatWeeklyData = _repetitionData!.weeklyRepetition!
            .map((dayIndex) => dayIndex % 7)
            .join(',');
      }
      tile.RepeatData = _repetitionData!.isForever.toString();
      tile.RepeatType = _repetitionData!.frequency.name;
    }

    DateTime startTime = Utility.currentTime();
    startTime = DateTime(startTime.year, startTime.month, startTime.day, 0, 0);

    if (this.isAppointment) {
      tile.Rigid = true.toString();
      if (this._startTime != null) {
        startTime = this._startTime!;
        if (this._duration != null) {
          _endTime = this._startTime!.add(this._duration!);
        }
      }
    }

    tile.EndYear = _endTime?.year.toString();
    tile.EndMonth = _endTime?.month.toString();
    tile.EndDay = _endTime?.day.toString();
    tile.EndHour = _endTime?.hour.toString();
    tile.EndMinute = _endTime?.minute.toString();

    tile.StartYear = startTime.year.toString();
    tile.StartMonth = startTime.month.toString();
    tile.StartDay = startTime.day.toString();
    tile.StartHour = startTime.hour.toString();
    tile.StartMinute = startTime.minute.toString();
    tile.isEveryDay = false.toString();
    tile.isRestricted = false.toString();
    tile.isWorkWeek = false.toString();
    tile.AutoReviseDeadline = isAutoRevisable.toString();
    tile.Priority = priority.name.toString().toLowerCase();

    var randomColor = _color ??
        HSLColor.fromAHSL(
                1,
                (Utility.randomizer.nextDouble() * 360),
                Utility.randomizer.nextDouble(),
                (1 - (Utility.randomizer.nextDouble() * 0.45)))
            .toColor();

    double colorConst = 255;
    tile.BColor = (randomColor.b * colorConst).toInt().toString();
    tile.GColor = (randomColor.g * colorConst).toInt().toString();
    tile.RColor = (randomColor.r * colorConst).toInt().toString();

    tile.ColorSelection = (-1).toString();

    if (_location != null) {
      tile.LocationAddress = _location!.address;
      tile.LocationTag = _location!.description;
      tile.LocationId = _location!.id;
      tile.LocationSource = _location!.source;
      tile.LocationIsVerified = _location!.isVerified.toString();
    }

    if (this._restrictionProfile != null &&
        this._restrictionProfile!.isAnyDayNotNull &&
        this._restrictionProfile!.isEnabled) {
      tile.RestrictiveWeek =
          this._restrictionProfile!.toRestrictionWeekConfig();
      tile.isRestricted = true.toString();
      tile.RestrictionProfileId = this._restrictionProfile!.id;
    }

    tile.Count = getSplitCount();

    debugPrint(tile.toJson().toString());

    Utility.determineDevicePosition().catchError((onError) async {
      final scaffold = ScaffoldMessenger.of(context);
      scaffold.showSnackBar(
        SnackBar(
          duration: Duration(seconds: 20),
          content: Text(AppLocalizations.of(context)!.enableLocations),
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.settings,
            onPressed: () async {
              await Geolocator.openAppSettings();
              await Geolocator.openLocationSettings();
            },
            textColor: Colors.redAccent,
          ),
        ),
      );
      return Utility.getDefaultPosition();
    });

    final currentState = this.context.read<ScheduleBloc>().state;
    if (currentState is ScheduleLoadedState) {
      this.context.read<ScheduleBloc>().add(EvaluateSchedule(
          isAlreadyLoaded: true,
          scheduleStatus: currentState.scheduleStatus,
          renderedScheduleTimeline: currentState.lookupTimeline,
          renderedSubEvents: currentState.subEvents,
          renderedTimelines: currentState.timelines));
    }
    Future retValue = this.scheduleApi.addNewTile(tile);
    retValue.then((newlyAddedTile) {
      if (newlyAddedTile.item1 != null) {
        SubCalendarEvent subEvent = newlyAddedTile.item1;
        print(subEvent.name);
      }
      if (this.widget.newTileParams != null) {
        this.widget.newTileParams!['newTile'] = newlyAddedTile.item1;
      }
      AnalysticsSignal.send('ADD_TILE_NEWTILE_ADD_SUCCESS_RESPONSE');
      this
          .context
          .read<SubCalendarTileBloc>()
          .add(NewSubCalendarTileBlocEvent(subEvent: newlyAddedTile.item1));

      final currentState = this.context.read<ScheduleBloc>().state;
      if (currentState is ScheduleEvaluationState) {
        this.context.read<ScheduleBloc>().add(GetScheduleEvent(
              isAlreadyLoaded: true,
              previousSubEvents: currentState.subEvents,
              scheduleTimeline: currentState.lookupTimeline,
              previousTimeline: currentState.lookupTimeline,
            ));
        refreshScheduleSummary(currentState.lookupTimeline);
      }
    }).onError((error, stackTrace) {
      AnalysticsSignal.send('ADD_TILE_NEWTILE_ADD_ERROR_RESPONSE');
      if (error != null) {
        String message = error.toString();
        if (error is FormatException) {
          FormatException exception = error;
          message = exception.message;
        }

        debugPrint(message);
        final scaffold = ScaffoldMessenger.of(context);
        scaffold.showSnackBar(
          SnackBar(
            content: Text(message),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.close,
              onPressed: scaffold.hideCurrentSnackBar,
              textColor: Colors.redAccent,
            ),
          ),
        );
      }
      final currentState = this.context.read<ScheduleBloc>().state;
      if (currentState is ScheduleEvaluationState) {
        this.context.read<ScheduleBloc>().add(GetScheduleEvent(
              isAlreadyLoaded: true,
              previousSubEvents: currentState.subEvents,
              scheduleTimeline: currentState.lookupTimeline,
              previousTimeline: currentState.lookupTimeline,
            ));
        refreshScheduleSummary(currentState.lookupTimeline);
      }
    });

    return retValue;
  }

  void refreshScheduleSummary(Timeline? lookupTimeline) {
    final currentScheduleSummaryState =
        this.context.read<ScheduleSummaryBloc>().state;

    if (currentScheduleSummaryState is ScheduleSummaryInitial ||
        currentScheduleSummaryState is ScheduleDaySummaryLoaded ||
        currentScheduleSummaryState is ScheduleDaySummaryLoading) {
      this.context.read<ScheduleSummaryBloc>().add(
            GetScheduleDaySummaryEvent(timeline: lookupTimeline),
          );
    }
  }

  Widget generateDeadline() {
    String textButtonString = this._endTime == null
        ? AppLocalizations.of(context)!.deadline_anytime
        : DateFormat.yMMMd().format(this._endTime!);
    Widget deadlineContainer = new GestureDetector(
      onTap: this.onEndDateTap,
      child: FractionallySizedBox(
        widthFactor: TileStyles.widthRatio,
        child: Container(
          margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
          padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
          decoration: BoxDecoration(
            color: TileStyles.primaryContrastColor,
            borderRadius: BorderRadius.all(
              inputBorderRadius,
            ),
            border: Border.all(
              color: textBorderColor,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.calendar_month, color: inputFieldIconColor),
              Container(
                padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: TextButton(
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  onPressed: onEndDateTap,
                  // TODO: work on this
                  child: Text(
                    textButtonString,
                    style: this._endTime == null
                        ? TextStyle(
                            fontFamily: TileStyles.rubikFontName,
                            color: TileStyles.inactiveTextColor)
                        : TextStyle(
                            fontFamily: TileStyles.rubikFontName,
                            color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return deadlineContainer;
  }

  setAsAppointment() {
    tilerCarouselController.animateToPage(1);
    setState(() {
      isAppointment = true;
      switchUpKey = Key(Utility.getUuid);
    });
  }

  setAsTile() {
    tilerCarouselController.animateToPage(0);
    setState(() {
      isAppointment = false;
      switchUpKey = Key(Utility.getUuid);
    });
  }

  onTabTypeChange(value) {
    onTileTypeChange();
  }

  onTileTypeChange() {
    if (this.isAppointment) {
      setAsTile();
    } else {
      setAsAppointment();
    }
  }

  onCarouselPageChange() {}

  Widget generateNewTileWidget(List<Widget> tileWidgets) {
    Widget retValue = Container(
      child: Column(children: tileWidgets),
    );
    return retValue;
  }

  Widget generateAppointmentWidget(List<Widget> tileWidgets) {
    Widget retValue = Container(
      child: Column(children: tileWidgets),
    );
    return retValue;
  }

  Widget toggleAppointmentWidget(List<Widget> tileWidgets) {
    Widget retValue = Container(
      child: Column(children: tileWidgets),
    );
    return retValue;
  }

  onTimeLineChange(TimeRange updatedTimeLine) {
    pendingSendTextRequest?.cancel();
    setState(() {
      _startTime = updatedTimeLine.startTime;
      _duration = updatedTimeLine.duration;
      _endTime = updatedTimeLine.endTime;
      _isDurationManuallySet = true;
    });
    isSubmissionReady();
  }

  @override
  Widget build(BuildContext context) {
    Map? newTileParams = ModalRoute.of(context)?.settings.arguments as Map?;
    this.widget.newTileParams = newTileParams;
    List<Widget> childrenWidgets = [];
    List<Widget> appointmentWidgets = [];
    List<Widget> tileWidgets = [];
    Widget tileNameWidget = this.getTileNameWidget();
    Widget durationPicker = this.generateDurationPicker();
    Widget deadlinePicker = this.generateDeadline();
    Widget splitCountWidget = this.getSplitCountWidget();

    StartEndDurationTimeline startAndEndTime = StartEndDurationTimeline(
      start: this._startTime ?? Utility.currentTime(),
      duration: this._duration ?? Duration(),
      onChange: onTimeLineChange,
    );
    Widget extraConfigCollection = this.generateExtraConfigSelection();
    tileWidgets.add(tileNameWidget);
    tileWidgets.add(durationPicker);
    tileWidgets.add(deadlinePicker);
    if (this._repetitionData != null) {
      tileWidgets.remove(deadlinePicker);
    }
    tileWidgets.add(splitCountWidget);

    appointmentWidgets.add(tileNameWidget);
    appointmentWidgets.add(FractionallySizedBox(
        widthFactor: TileStyles.widthRatio,
        child: Container(child: startAndEndTime)));

    Widget tileWidgetWrapper = generateNewTileWidget(tileWidgets);
    Widget appointmentWidget = generateAppointmentWidget(appointmentWidgets);

    List<Widget> carouselItems = [tileWidgetWrapper, appointmentWidget];
    List<String> tabButtons = [
      AppLocalizations.of(context)!.tile,
      AppLocalizations.of(context)!.appointment
    ];

    Widget switchUp = Container(
      child: ToggleSwitch(
        // key: switchUpKey,
        initialLabelIndex: !isAppointment ? 0 : 1,
        totalSwitches: 2,
        animate: true,

        labels: tabButtons,
        onToggle: onTabTypeChange,
        activeFgColor: TileStyles.primaryContrastColor,
        activeBgColor: [TileStyles.primaryColor],
        inactiveBgColor: TileStyles.inactiveTextColor,
        inactiveFgColor: TileStyles.primaryContrastColor,
      ),
    );

    Widget tileTypeCarousel = CarouselSlider(
      carouselController: tilerCarouselController,
      items: carouselItems,
      options: CarouselOptions(
        height:
            isAppointment ? 340 : (this._repetitionData != null ? 220 : 300),
        aspectRatio: 16 / 9,
        viewportFraction: 1,
        initialPage: 0,
        enableInfiniteScroll: false,
        reverse: false,
        onPageChanged: (pageNumber, carouselData) {
          if (carouselData == CarouselPageChangedReason.manual) {
            if (pageNumber == 0) {
              setAsTile();
            } else {
              setAsAppointment();
            }
          }
        },
        scrollDirection: Axis.horizontal,
      ),
    );

    childrenWidgets.add(tileTypeCarousel);
    childrenWidgets.add(switchUp);
    childrenWidgets.add(extraConfigCollection);

    CancelAndProceedTemplateWidget retValue = CancelAndProceedTemplateWidget(
      routeName: addTileCancelAndProceedRouteName,
      appBar: AppBar(
        backgroundColor: TileStyles.appBarColor,
        title: Text(
          AppLocalizations.of(context)!.addTile,
          style: TextStyle(
              color: TileStyles.appBarTextColor,
              fontWeight: FontWeight.w800,
              fontSize: 22),
        ),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      child: Container(
        margin: TileStyles.topMargin,
        alignment: Alignment.topCenter,
        child: Stack(
          children: [
            isPendingAutoResult
                ? TileStyles.getShimmerPending(context)
                : SizedBox.shrink(),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: childrenWidgets,
            ),
          ],
        ),
      ),
      onProceed: this.onProceed,
      bottomWidget: this.onProceed == null
          ? Container(
              alignment: Alignment.bottomCenter,
              margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
              child: Text(
                AppLocalizations.of(context)!.starAreRequired,
                style: TextStyle(color: TileStyles.disabledTextColor),
              ),
            )
          : null,
    );

    return retValue;
  }

  @override
  void dispose() {
    tileNameController.dispose();
    tileDeadline.dispose();
    splitCountController.dispose();
    super.dispose();
  }
}
