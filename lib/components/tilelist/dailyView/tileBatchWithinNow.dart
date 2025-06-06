import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/tileUI/emptyDayTile.dart';
import 'package:tiler_app/routes/authenticatedUser/analysis/daySummary.dart';
import 'package:tiler_app/components/listModel.dart';
import 'package:tiler_app/components/tileUI/sleepTile.dart';
import 'package:tiler_app/components/tileUI/tile.dart';
import 'package:tiler_app/components/tilelist/dailyView/tileBatch.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/constants.dart';

class WithinNowBatch extends TileBatch {
  TileWidget? _currentWidget;
  WithinNowBatchState? _state;
  TimelineSummary? dayData;

  WithinNowBatch({List<TilerEvent>? tiles, TimelineSummary? dayData, Key? key})
      : super(
            key: key,
            tiles: tiles,
            dayData: dayData,
            dayIndex: Utility.currentTime().universalDayIndex);

  @override
  WithinNowBatchState createState() {
    _state = WithinNowBatchState();
    return _state!;
  }

  Future<TileBatchState> get state async {
    if (this._state != null && this._state!.mounted) {
      return this._state!;
    } else {
      Future<TileBatchState> retValue = new Future.delayed(
          const Duration(milliseconds: stateRetrievalRetry), () {
        return this.state;
      });

      return retValue;
    }
  }
}

enum _AnimatedListType { preceeding, current, upcoming }

class WithinNowBatchState extends TileBatchState {
  final String upcomingAdHocTileId = 'upcoming-tile-section-header-id';
  final GlobalKey<AnimatedListState> _preceedingListKey =
      GlobalKey<AnimatedListState>(debugLabel: 'preceedinglistKey');
  final GlobalKey<AnimatedListState> _upcomingListKey =
      GlobalKey<AnimatedListState>(debugLabel: 'upcomingListKey');
  late ListModel<TilerEvent>? _preceedingList;
  ScrollController preceedingAnimatedListScrollController =
      new ScrollController();
  ScrollController fullUiController = new ScrollController();
  AnimatedList? preceedingAnimatedList;
  Map<String, Tuple3<TilerEvent, int?, int?>>? preceedingOrderedTiles;

  double _emptyDayOpacity = 0;
  double heightMargin = 262;
  double heightOfTimeBanner = 245;
  bool _pendingRendering = false;
  bool _isEmptydayTile = false;
  @override
  void initState() {
    super.initState();
    _preceedingList = ListModel(
        listKey: _preceedingListKey, removedItemBuilder: _buildRemovedItem);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        snapToUpComingTiles();
      }
    });
  }

  void snapToUpComingTiles() {
    RenderBox? renderObject =
        _upcomingListKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderObject != null) {
      var offset = renderObject.localToGlobal(Offset.zero);

      bool isInterferringWithNow = false;
      bool precedingTileExist = false;
      int currentTimeInMs = Utility.currentTime().millisecondsSinceEpoch;
      if (this.widget.tiles != null) {
        for (var eachTile in this.widget.tiles!) {
          SubCalendarEvent? eachSubEvent = eachTile as SubCalendarEvent?;
          if (eachSubEvent != null) {
            if (eachSubEvent.end != null &&
                eachSubEvent.end! < currentTimeInMs) {
              precedingTileExist = true;
            }
            if (eachSubEvent.start != null &&
                eachSubEvent.start! <= currentTimeInMs &&
                eachSubEvent.end != null &&
                eachSubEvent.end! > currentTimeInMs) {
              isInterferringWithNow = true;
            }
            if (precedingTileExist && isInterferringWithNow) {
              break;
            }
          }
        }
      }
      double interferringWithNowOffSet = 0;

      if (precedingTileExist) {
        if (isInterferringWithNow) {
          interferringWithNowOffSet = TileStyles.tileHeight;
        }
        print(
            'interferringWithNowOffSet: $interferringWithNowOffSet, offset: ${offset.distance}');
        double offSetUpdate =
            offset.distance - heightOfTimeBanner - interferringWithNowOffSet;
        if (offSetUpdate > 0) {
          fullUiController.jumpTo(offSetUpdate);
        }
      }
    }
  }

  Widget _buildRemovedItem(
      TilerEvent item, BuildContext context, Animation<double> animation) {
    var tile = item;
    if (isTileAdHocUpcoming(tile)) {
      return FadeTransition(
        key: _upcomingListKey,
        opacity: animation,
        child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: EdgeInsets.fromLTRB(30, 20, 0, 40),
              alignment: Alignment.centerLeft,
              child: Text(AppLocalizations.of(context)!.upcoming,
                  style: TileBatch.dayHeaderTextStyle),
            )),
      );
    }

    return SizeTransition(
      sizeFactor: animation,
      child: Align(alignment: Alignment.topCenter, child: TileWidget(item)),
    );
  }

  Widget _preceedingBuildItem(
      BuildContext context, int index, Animation<double> animation) {
    var tile = _preceedingList![index];
    if (isTileAdHocUpcoming(tile)) {
      return FadeTransition(
        key: _upcomingListKey,
        opacity: animation,
        child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: EdgeInsets.fromLTRB(30, 20, 0, 20),
              alignment: Alignment.centerLeft,
              child: Text(AppLocalizations.of(context)!.upcoming,
                  style: TileBatch.dayHeaderTextStyle),
            )),
      );
    }

    return SizeTransition(
      sizeFactor: animation,
      child: Align(alignment: Alignment.topCenter, child: TileWidget(tile)),
    );
  }

  bool isTileAdHocUpcoming(TilerEvent tilerEvent) {
    return tilerEvent.id == upcomingAdHocTileId;
  }

  evaluatePopulatedTileDelta(
      _AnimatedListType _animatedListType, Iterable<TilerEvent>? tiles) {
    Map<String, Tuple3<TilerEvent, int?, int?>>? timeSectionTiles;
    if (this.preceedingOrderedTiles == null) {
      this.preceedingOrderedTiles = {};
    }
    timeSectionTiles = this.preceedingOrderedTiles;

    if (tiles == null) {
      tiles = <TilerEvent>[];
    }
    List<TilerEvent> orderedByTimeTiles = tiles.toList();
    orderedByTimeTiles
        .sort((tileA, tileB) => tileA.start!.compareTo(tileB.start!));

    Map<String, TilerEvent> allFoundTiles = {};

    for (var eachTile in timeSectionTiles!.values) {
      allFoundTiles[eachTile.item1.uniqueId] = eachTile.item1;
    }

    for (int i = 0; i < orderedByTimeTiles.length; i++) {
      TilerEvent eachTile = orderedByTimeTiles[i];
      int? currentIndexPosition;
      if (timeSectionTiles.containsKey(eachTile.uniqueId)) {
        currentIndexPosition = timeSectionTiles[eachTile.uniqueId]!.item2;
      }
      timeSectionTiles[eachTile.uniqueId] =
          Tuple3(eachTile, currentIndexPosition, i);
      allFoundTiles.remove(eachTile.uniqueId);
    }

    for (TilerEvent eachTile in allFoundTiles.values) {
      timeSectionTiles[eachTile.uniqueId] =
          Tuple3(eachTile, timeSectionTiles[eachTile.uniqueId]!.item2, null);
    }
  }

  processPopulatedAnimatedList(
      _AnimatedListType _animatedListType, List<TilerEvent> collection) {
    evaluatePopulatedTileDelta(_AnimatedListType.preceeding, collection);
    if (this.preceedingAnimatedList == null ||
        this.pendingRenderedTiles == null) {
      bool onlyNewEntriesPopulated =
          isAllNewEntries(this.preceedingOrderedTiles!);
      var initialItems = this.preceedingOrderedTiles!.values.where((element) {
        if (onlyNewEntriesPopulated) {
          return element.item3 != null;
        }
        return element.item2 != null;
      }).toList();

      initialItems.sort((tupleA, tupleB) {
        if (tupleA.item1.start == tupleB.item1.start) {
          if (tupleA.item1.end == tupleB.item1.end!) {
            return tupleA.item1.uniqueId.compareTo(tupleB.item1.uniqueId);
          }
          return tupleA.item1.end!.compareTo(tupleB.item1.end!);
        }
        return tupleA.item1.start!.compareTo(tupleB.item1.start!);
      });

      this._preceedingList = ListModel<TilerEvent>(
        listKey: this._preceedingListKey,
        initialItems: initialItems.map<TilerEvent>((e) => e.item1),
        removedItemBuilder: _buildRemovedItem,
      );
      this.preceedingAnimatedList = AnimatedList(
        shrinkWrap: true,
        controller: preceedingAnimatedListScrollController,
        itemBuilder: _preceedingBuildItem,
        key: this._preceedingListKey,
        physics: const NeverScrollableScrollPhysics(),
        initialItemCount: initialItems.length,
      );
    }
  }

  processAnimatedList(
      _AnimatedListType _animatedListType, List<TilerEvent> collection) {
    processPopulatedAnimatedList(_animatedListType, collection);
  }

  renderEmptyDayTile() {
    _isEmptydayTile = true;
    if (_emptyDayOpacity == 0) {
      Timer(Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _emptyDayOpacity = 1;
          });
        }
      });
    }
    if (this.widget.dayIndex != null) {
      return Flex(
        direction: Axis.vertical,
        children: [
          AnimatedOpacity(
            opacity: _emptyDayOpacity,
            duration: const Duration(milliseconds: 500),
            child: Container(
                height: MediaQuery.of(context).size.height - heightMargin,
                child: EmptyDayTile(
                  deadline:
                      Utility.getTimeFromIndex(this.widget.dayIndex!).endOfDay,
                  dayIndex: this.widget.dayIndex!,
                )),
          )
        ],
      );
    }
    return SizedBox.shrink();
  }

  bool internalBreak = false;
  @override
  Widget build(BuildContext context) {
    latestBuildTiles = {};
    renderedTiles = this.pendingRenderedTiles ?? {};
    SubCalendarEvent? upcomingTile = SubCalendarEvent();
    upcomingTile.id = upcomingAdHocTileId;
    int currentTimeinMs = Utility.currentTime().millisecondsSinceEpoch;
    upcomingTile.start = currentTimeinMs;
    upcomingTile.end = Utility.todayTimeline().end;
    if (upcomingTile.end! < upcomingTile.start!) {
      upcomingTile.start = upcomingTile.end;
    }
    if (widget.tiles != null) {
      widget.tiles!.forEach((eachTile) {
        if (eachTile.id != null &&
            (((eachTile) as SubCalendarEvent?)?.isViable ?? true)) {
          latestBuildTiles[eachTile.uniqueId] = eachTile;
        }
        if (((eachTile as SubCalendarEvent?)?.isViable ?? true) &&
            eachTile.start! >= currentTimeinMs &&
            upcomingTile != null) {
          latestBuildTiles[upcomingTile!.uniqueId] = upcomingTile!;
          upcomingTile = null;
        }
      });
    }

    if (pendingRenderedTiles == null) {
      renderedTiles = latestBuildTiles;
    }

    List<Widget> children = [];
    if (dayData != null && this.widget.tiles != null) {
      this.dayData!.nonViable = this
          .widget
          .tiles!
          .where(
              (eachTile) => !((eachTile as SubCalendarEvent).isViable ?? true))
          .toList();
      childrenColumnWidgets.add(Container(
          margin: EdgeInsets.fromLTRB(0, 0, 0, 61),
          child: DaySummary(dayTimelineSummary: this.dayData!)));
    }

    children.add(Container(
        child:
            DaySummary(dayTimelineSummary: this.dayData ?? TimelineSummary())));
    List<TilerEvent> precedingTiles = [];
    List<Widget> precedingTileWidgets = [];

    if (this.widget.sleepTimeline != null) {
      Timeline sleepTimeline = this.widget.sleepTimeline!;
      Widget sleepWidget = SleepTileWidget(sleepTimeline);
      children.add(sleepWidget);
    }

    if (renderedTiles.length > 0) {
      var orderedRenderedTiles =
          Utility.orderTiles(renderedTiles.values.toList());
      orderedRenderedTiles.forEach((eachTile) {
        precedingTiles.add(eachTile);
      });
    } else {
      precedingTileWidgets.add(renderEmptyDayTile());
    }
    processAnimatedList(_AnimatedListType.preceeding, precedingTiles);

    if (this.preceedingAnimatedList != null) {
      precedingTileWidgets.add(this.preceedingAnimatedList!);
    }
    Widget scrollableItems = RefreshIndicator(
      onRefresh: () async {
        final currentState = this.context.read<ScheduleBloc>().state;

        if (currentState is ScheduleEvaluationState) {
          this.context.read<ScheduleBloc>().add(GetScheduleEvent(
              isAlreadyLoaded: true,
              previousSubEvents: currentState.subEvents,
              scheduleTimeline: currentState.lookupTimeline,
              previousTimeline: currentState.lookupTimeline,
              forceRefresh: true));
          refreshScheduleSummary(lookupTimeline: currentState.lookupTimeline);
        }

        if (currentState is ScheduleLoadedState) {
          this.context.read<ScheduleBloc>().add(GetScheduleEvent(
              isAlreadyLoaded: true,
              previousSubEvents: currentState.subEvents,
              scheduleTimeline: currentState.lookupTimeline,
              previousTimeline: currentState.lookupTimeline,
              forceRefresh: true));
          refreshScheduleSummary(lookupTimeline: currentState.lookupTimeline);
        }

        if (currentState is ScheduleLoadingState) {
          this.context.read<ScheduleBloc>().add(GetScheduleEvent(
              isAlreadyLoaded: true,
              previousSubEvents: currentState.subEvents,
              scheduleTimeline: currentState.previousLookupTimeline,
              previousTimeline: currentState.previousLookupTimeline,
              forceRefresh: true));
          refreshScheduleSummary(
              lookupTimeline: currentState.previousLookupTimeline);
        }
      },
      child: Container(
        margin: EdgeInsets.fromLTRB(0, 65, 0, 0),
        height: MediaQuery.of(context).size.height - heightOfTimeBanner,
        width: MediaQuery.of(context).size.width,
        child: ListView(
          shrinkWrap: true,
          controller: fullUiController,
          physics: _isEmptydayTile ? NeverScrollableScrollPhysics() : null,
          children: [
            ...precedingTileWidgets,
            // this is needed to ensure there is spacing between animated list and the bottom of the screen
            MediaQuery.of(context).orientation == Orientation.landscape
                ? TileStyles.bottomLandScapePaddingForTileBatchListOfTiles
                : TileStyles.bottomPortraitPaddingForTileBatchListOfTiles
          ],
        ),
      ),
    );

    children.add(scrollableItems);
    bool beforeProcessingPendingRenderingFlag = this._pendingRendering;
    if (this.pendingRenderedTiles == null) {
      handleAddOrRemovalOfTimeSectionTiles(this.preceedingOrderedTiles,
          this._preceedingList, beforeProcessingPendingRenderingFlag);
      if (!beforeProcessingPendingRenderingFlag && this._pendingRendering) {
        this.pendingRenderedTiles = Map.from(this.renderedTiles);
      }
    }

    if (!this._pendingRendering && this.pendingRenderedTiles != null) {
      Timer(Duration(milliseconds: 1000), () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              this.pendingRenderedTiles = null;
            });
          }
        });
      });
    }

    return Column(
      children: children,
    );
  }

  void refreshScheduleSummary({Timeline? lookupTimeline}) {
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

  bool isAllNewEntries(
      Map<String, Tuple3<TilerEvent, int?, int?>> timeSectionTiles) {
    return !timeSectionTiles.values.any((element) => element.item2 != null);
  }

  handleAddOrRemovalOfTimeSectionTiles(
      Map<String, Tuple3<TilerEvent, int?, int?>>? timeSectionTiles,
      ListModel<TilerEvent>? _timeSectionListModel,
      bool pendingRendering) {
    if (timeSectionTiles != null && !pendingRendering) {
      List<Tuple3<TilerEvent, int?, int?>> changeInTilerEventOrdering =
          timeSectionTiles.values
              .where((element) => element.item2 != element.item3)
              .toList();
      bool allNewEntries = isAllNewEntries(timeSectionTiles);
      if (allNewEntries) {
        List finalOrederedTileValues = timeSectionTiles.values.toList();
        for (var eachTileTupleData in finalOrederedTileValues) {
          timeSectionTiles[eachTileTupleData.item1.uniqueId] = Tuple3(
              eachTileTupleData.item1,
              eachTileTupleData.item3,
              eachTileTupleData.item3);
        }
        return;
      }

      List<Tuple3<TilerEvent, int?, int?>> removedTiles = [];
      List<Tuple3<TilerEvent, int?, int?>> reorderedTiles = [];
      List<Tuple3<TilerEvent, int?, int?>> insertedTiles = [];
      for (var eachTileTuple in changeInTilerEventOrdering) {
        if (eachTileTuple.item3 == null && eachTileTuple.item2 != null) {
          removedTiles.add(eachTileTuple);
          continue;
        }

        if (eachTileTuple.item2 != null) {
          reorderedTiles.add(eachTileTuple);
        } else {
          insertedTiles.add(eachTileTuple);
        }
      }

      List<String> listIds = _timeSectionListModel!
          .toList()
          .map<String>((e) => e.uniqueId)
          .toList();
      for (var removedTile in removedTiles) {
        listIds = _timeSectionListModel
            .toList()
            .map<String>((e) => e.uniqueId)
            .toList();
        int toBeRemovedIndex = listIds.indexOf(removedTile.item1.uniqueId);
        if (toBeRemovedIndex != removedTile.item3) {
          if (toBeRemovedIndex >= 0) {
            _timeSectionListModel.removeAt(toBeRemovedIndex);
          }
        }
      }

      for (var removedTile in removedTiles) {
        timeSectionTiles.remove(removedTile.item1.uniqueId);
      }

      if (insertedTiles.isNotEmpty || reorderedTiles.isNotEmpty) {
        this._pendingRendering = true;
        Timer(Duration(milliseconds: 500), () {
          for (var insertedTile in insertedTiles) {
            _timeSectionListModel.insert(
              insertedTile.item3!,
              insertedTile.item1,
            );
          }

          for (var reorderedTile in reorderedTiles) {
            listIds = _timeSectionListModel
                .toList()
                .map<String>((e) => e.uniqueId)
                .toList();
            int toMovedIndex = listIds.indexOf(reorderedTile.item1.uniqueId);
            if (toMovedIndex != -1) {
              _timeSectionListModel.removeAndUpdate(
                  toMovedIndex, reorderedTile.item3!, reorderedTile.item1,
                  animate: toMovedIndex != reorderedTile.item3);
            }
          }
          if (mounted) {
            setState(() {
              this._pendingRendering = false;
            });
          }
        });
      }
    }
    if (timeSectionTiles != null) {
      List finalOrederedTileValues = timeSectionTiles.values.toList();
      for (var eachTileTupleData in finalOrederedTileValues) {
        timeSectionTiles[eachTileTupleData.item1.uniqueId] = Tuple3(
            eachTileTupleData.item1,
            eachTileTupleData.item3,
            eachTileTupleData.item3);
      }
    }
  }
}
