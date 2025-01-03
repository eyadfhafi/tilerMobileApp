import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/tileShareClusterApi.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class DesignatedTileWidget extends StatefulWidget {
  final DesignatedTile designatedTile;
  DesignatedTileWidget(this.designatedTile);

  @override
  State<StatefulWidget> createState() => _DesignatedWidgetState();
}

class _DesignatedWidgetState extends State<DesignatedTileWidget> {
  bool _isLoading = false;
  final TileShareClusterApi tileClusterApi = TileShareClusterApi();
  final ScheduleApi scheduleApi = ScheduleApi();
  String _responseMessage = '';
  late DesignatedTile designatedTile;
  @override
  void initState() {
    super.initState();
    this.designatedTile = this.widget.designatedTile;
  }

  // Function to handle API calls with status updates
  Future<void> _statusUpdate(InvitationStatus status) async {
    setState(() {
      _isLoading = true;
      _responseMessage = '';
    });

    try {
      if (this.designatedTile.id != null) {
        DesignatedTile? updatedDesignatedTile =
            await tileClusterApi.statusUpdate(this.designatedTile.id!, status);
        if (updatedDesignatedTile != null) {
          setState(() {
            this.designatedTile = updatedDesignatedTile;
          });
        }
      }
    } catch (e) {
      setState(() {
        _responseMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Handlers for each button
  Future<void> _handleAccept() async {
    await _statusUpdate(InvitationStatus.accepted);
    tileClusterApi.analyzeSchedule().then((value) {
      return scheduleApi.buzzSchedule();
    });
  }

  Future<void> _handleDecline() async =>
      _statusUpdate(InvitationStatus.declined);
  Future<void> _handlePreview() async {
    setState(() {});
  }

  final double lrPadding = 12;
  ButtonStyle generateButtonStyle(bool isSelected, Color defaultColor) {
    ButtonStyle retValue = ElevatedButton.styleFrom(
        padding: EdgeInsets.fromLTRB(lrPadding, 5, lrPadding, 5),
        foregroundColor: defaultColor);
    if (isSelected) {
      retValue = ElevatedButton.styleFrom(
          padding: EdgeInsets.fromLTRB(lrPadding, 5, lrPadding, 5),
          backgroundColor: defaultColor,
          foregroundColor: Colors.white);
    }
    return retValue;
  }

  Widget renderButtons() {
    if (_isLoading)
      return CircularProgressIndicator();
    else
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ElevatedButton.icon(
                onPressed: _handleAccept,
                icon: Icon(Icons.check),
                label: Text(AppLocalizations.of(context)!.accept),
                style: generateButtonStyle(
                    this.designatedTile.invitationStatus ==
                        InvitationStatus.accepted.name.toString(),
                    Colors.green)),
            ElevatedButton.icon(
                onPressed: _handleDecline,
                icon: Icon(Icons.close),
                label: Text(AppLocalizations.of(context)!.decline),
                style: generateButtonStyle(
                    this.designatedTile.invitationStatus ==
                        InvitationStatus.declined.name.toString(),
                    TileStyles.primaryColor)),
          ],
        ),
      );
  }

  Widget designatedTileDetails() {
    const spaceDivider = SizedBox(height: 10);
    const supplementalTextStyle =
        TextStyle(fontSize: 12, fontFamily: TileStyles.rubikFontName);
    String? designatedUsename = designatedTile.user?.username;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            designatedTile.name ?? "",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                fontFamily: TileStyles.rubikFontName),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          spaceDivider,
          designatedTile.endTime != null
              ? Text(
                  AppLocalizations.of(context)!.deadlineTime(
                      DateFormat('d MMM').format(designatedTile.endTime!)),
                  style: supplementalTextStyle,
                )
              : SizedBox.shrink(),
          spaceDivider,
          designatedUsename.isNot_NullEmptyOrWhiteSpace()
              ? Row(
                  children: [
                    Text((designatedUsename!.contains('@') ? '' : '@') +
                        "$designatedUsename"),
                    designatedTile.invitationStatus
                                .isNot_NullEmptyOrWhiteSpace() &&
                            designatedTile.invitationStatus!.toLowerCase() !=
                                InvitationStatus.none.name
                                    .toString()
                                    .toLowerCase() &&
                            designatedTile.isTilable == false
                        ? Container(
                            margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                  TileStyles.borderRadius),
                            ),
                            child: Text(
                              designatedTile.invitationStatus!.capitalize(),
                              style: TextStyle(
                                  fontSize: 15,
                                  fontFamily: TileStyles.rubikFontName,
                                  color: designatedTile.invitationStatus!
                                              .toLowerCase() ==
                                          InvitationStatus.accepted.name
                                              .toString()
                                              .toLowerCase()
                                      ? Colors.green
                                      : Colors.red),
                            ),
                          )
                        : SizedBox.shrink()
                  ],
                )
              : SizedBox.shrink(),
          spaceDivider,
          if (_responseMessage.isEmpty)
            SizedBox.shrink()
          else
            Text(
              _responseMessage,
              style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontFamily: TileStyles.rubikFontName),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 5,
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            designatedTileDetails(),
            SizedBox.square(
              dimension: 8,
            ),
            if (this.designatedTile.isTilable == false)
              SizedBox.shrink()
            else
              renderButtons()
          ],
        ),
      ),
    );
  }
}
