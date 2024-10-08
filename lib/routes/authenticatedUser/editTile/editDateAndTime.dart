import 'package:flutter/material.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editDate.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileTime.dart';
import 'package:tiler_app/styles.dart';

class EditDateAndTime extends StatelessWidget {
  DateTime time;
  EditTileTime? _tileTime;
  EditTileDate? _tileDate;
  Function? onInputChange;
  bool isReadOnly = false;
  EditDateAndTime(
      {required this.time, this.onInputChange, this.isReadOnly = false}) {
    _tileTime = EditTileTime(
      time: TimeOfDay.fromDateTime(time.toLocal()),
      onInputChange: onTimeChange,
      isReadOnly: this.isReadOnly,
    );
    _tileDate = EditTileDate(
      time: time.toLocal(),
      onInputChange: onDateChange,
      isReadOnly: this.isReadOnly,
    );
  }

  DateTime? get dateAndTime {
    if (_tileTime != null && _tileDate != null) {
      TimeOfDay? timeOfDayTime = _tileTime!.timeOfDay;
      DateTime? dateOfTile = _tileDate!.dateTime;
      if (dateOfTile != null && timeOfDayTime != null) {
        DateTime retValue = DateTime(dateOfTile.year, dateOfTile.month,
            dateOfTile.day, timeOfDayTime.hour, timeOfDayTime.minute);
        return retValue;
      }
    }
    return null;
  }

  onTimeChange(TimeOfDay timeOfDayUpdate) {
    if (this.isReadOnly) {
      return;
    }
    if (onInputChange != null) {
      onInputChange!();
    }
  }

  onDateChange(DateTime dateUpdate) {
    if (this.isReadOnly) {
      return;
    }
    if (onInputChange != null) {
      onInputChange!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color textBorderColor = TileStyles.primaryColorLightHSL.toColor();
    _tileTime = EditTileTime(
      time: TimeOfDay.fromDateTime(time.toLocal()),
      onInputChange: onTimeChange,
      isReadOnly: this.isReadOnly,
    );
    _tileDate = EditTileDate(
      time: time.toLocal(),
      onInputChange: onDateChange,
      isReadOnly: this.isReadOnly,
    );
    return Container(
      padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
      height: 60,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: TileStyles.primaryColorLightHSL.toColor(),
            width: 1,
          ),
        ),
        color: !this.isReadOnly
            ? Colors.transparent
            : TileStyles.disabledBackgroundColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [_tileTime!, _tileDate!],
      ),
    );
  }
}
