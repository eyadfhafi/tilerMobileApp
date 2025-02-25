import 'package:flutter/material.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/designatedUser.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class DesignatedUserCircle extends StatefulWidget {
  final BoxDecoration? decoration;
  final Color? color;
  final DesignatedUser designatedUser;
  DesignatedUserCircle(
      {required this.designatedUser, this.decoration, this.color});
  @override
  State<StatefulWidget> createState() => _DesignatedUserCircleState();
}

class _DesignatedUserCircleState extends State<DesignatedUserCircle> {
  late Contact e;
  @override
  void initState() {
    super.initState();
    e = this.widget.designatedUser.userProfile != null
        ? Contact.fromUserProfile(this.widget.designatedUser.userProfile!)
        : Contact();
  }

  Widget _subScriptWidget() {
    const double top = 22.4;
    const double left = 22.4;

    if (this.widget.designatedUser.completionPercentage != null &&
        this.widget.designatedUser.completionPercentage != 0) {
      double pct = this.widget.designatedUser.completionPercentage!;
      return Positioned(
        top: 22.4,
        left: 25,
        child: Container(
          padding: EdgeInsets.all(2),
          alignment: Alignment.center,
          height: 14,
          width: 25,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 1),
            borderRadius: BorderRadius.circular(5),
            color: pct > 66.66
                ? Colors.green
                : pct > 33.33
                    ? Colors.orange
                    : TileStyles.primaryColor,
          ),
          child: Text(
            "${pct.round()}%",
            style: TextStyle(
                fontSize: 7,
                fontFamily: TileStyles.rubikFontName,
                color: Colors.white),
          ),
        ),
      );
    }

    if (this.widget.designatedUser.rsvpStatus == InvitationStatus.accepted)
      return Positioned(
        top: top,
        left: left,
        child: Container(
          padding: EdgeInsets.all(2),
          alignment: Alignment.center,
          height: 15.36,
          width: 15.36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.lightGreen,
          ),
          child: Icon(
            Icons.check,
            color: Colors.white,
            size: 12.8,
            weight: 32,
          ),
        ),
      );
    else if (this.widget.designatedUser.rsvpStatus == InvitationStatus.declined)
      return Positioned(
        top: top,
        left: left,
        child: Container(
          padding: EdgeInsets.all(2),
          alignment: Alignment.center,
          height: 15.36,
          width: 15.36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.redAccent,
          ),
          child: Icon(
            Icons.dnd_forwardslash_outlined,
            color: Colors.white,
            size: 12.8,
            weight: 32,
          ),
        ),
      );
    else
      return SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    BoxDecoration inActiveDecoration = BoxDecoration(
        shape: BoxShape.circle,
        color: this.widget.color ?? Colors.white,
        border: Border.all(
          color: Colors.transparent,
          width: 5,
        ));
    return Stack(children: [
      Container(
          margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
          alignment: Alignment.center,
          width: 40,
          height: 38,
          decoration: this.widget.decoration ?? inActiveDecoration,
          child: Text(
              e.displayedIdentifier.isNot_NullEmptyOrWhiteSpace(minLength: 1)
                  ? e.displayedIdentifier!.capitalize()[0]
                  : "",
              style: TextStyle(
                  fontSize: 16,
                  fontFamily: TileStyles.rubikFontName,
                  color: Colors.white))),
      _subScriptWidget()
    ]);
  }
}
