import 'package:flutter/material.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/util.dart';

mixin TimeRange {
  int? start = 0;
  int? end = 0;

  bool isInterfering(TimeRange timeRange) {
    bool retValue = false;
    if (this.start != null &&
        this.end != null &&
        timeRange.start != null &&
        timeRange.end != null) {
      retValue = this.end! > timeRange.start! && timeRange.end! > this.start!;
    }

    return retValue;
  }

  TimeRange? interferingTimeRange(TimeRange timeRange) {
    if (this.isInterfering(timeRange)) {
      int start =
          this.start! > timeRange.start! ? this.start! : timeRange.start!;
      int end = this.end! < timeRange.end! ? this.end! : timeRange.end!;
      return Timeline.fromDateTime(DateTime.fromMillisecondsSinceEpoch(start),
          DateTime.fromMillisecondsSinceEpoch(end));
    }
    return null;
  }

  bool isDateTimeWithin(DateTime time) {
    int currentTime = time.millisecondsSinceEpoch;
    return this.start! <= currentTime && this.end! > currentTime;
  }

  bool get isCurrentTimeWithin {
    int currentTime =
        Utility.currentTime(minuteLimitAccuracy: false).millisecondsSinceEpoch;
    return this.start! <= currentTime && this.end! > currentTime;
  }

  bool get hasElapsed {
    return this.end! <
        Utility.currentTime(minuteLimitAccuracy: false)
            .millisecondsSinceEpoch
            .toDouble();
  }

  DateTime get startTime {
    return Utility.localDateTimeFromMs(this.start ?? 0.toInt());
  }

  DateTime get endTime {
    return Utility.localDateTimeFromMs(this.end ?? 0.toInt());
  }

  Duration get duration {
    if (this.start != null && this.end != null) {
      return Duration(milliseconds: (this.end!.toInt() - this.start!.toInt()));
    }
    throw ErrorDescription("Invalid timerange provided");
  }

  bool isStartAndEndEqual(TimeRange timeRange) {
    return this.start == timeRange.start && this.end == timeRange.end;
  }

  Duration get durationTillStart {
    if (this.start != null) {
      return Duration(
          milliseconds: (this.start!.toInt() - Utility.msCurrentTime).toInt());
    }
    throw ErrorDescription("Invalid timerange provided");
  }

  Duration get durationTillEnd {
    if (this.start != null) {
      return Duration(
          milliseconds: (this.end!.toInt() - Utility.msCurrentTime).toInt());
    }
    throw ErrorDescription("Invalid timerange provided");
  }
}
