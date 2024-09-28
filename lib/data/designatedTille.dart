import 'package:tiler_app/data/tileTemplate.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/tilerUserProfile.dart';
import 'package:tiler_app/util.dart';

enum InvitationStatus { accepted, declined, none }

class DesignatedTile {
  String? id;
  String? name;
  int? startInMs;
  int? endInMs;
  String? invitationStatus = InvitationStatus.none.toString();
  bool? isViable;
  String? displayedIdentifier;
  TileTemplate? tileTemplate;
  TilerUserProfile? user;
  TilerEvent? tilerEvent;

  DesignatedTile.fromJson(Map<String, dynamic> json) {
    id = '';
    Utility.debugPrint("DesignatedTile json");
    Utility.debugPrint(json.toString());
    if (json.containsKey('id')) {
      id = json['id'];
    }

    if (json.containsKey('name')) {
      name = json['name'];
    }

    if (json.containsKey('template') && json['template'] != null) {
      tileTemplate = TileTemplate.fromJson(json['template']);
    }

    if (json.containsKey('displayedIdentifier')) {
      displayedIdentifier = json['displayedIdentifier'];
    }

    if (json.containsKey('isViable')) {
      isViable = json['isViable'];
    }

    if (json.containsKey('invitationStatus')) {
      invitationStatus = json['invitationStatus'];
    }

    if (json.containsKey('user') && json['user'] != null) {
      user = TilerUserProfile.fromJson(json['user']);
    }

    if (json.containsKey('tilerEvent') && json['tilerEvent'] != null) {
      tilerEvent = TilerEvent.fromJson(json['tilerEvent']);
    }
  }

  DateTime? get startTime {
    if (startInMs != null) {
      return DateTime.fromMillisecondsSinceEpoch(startInMs!);
    }
    if (tileTemplate != null && tileTemplate!.start != null) {
      return DateTime.fromMillisecondsSinceEpoch(tileTemplate!.start!);
    }
  }

  DateTime? get endTime {
    if (endInMs != null) {
      return DateTime.fromMillisecondsSinceEpoch(endInMs!);
    }
    if (tileTemplate != null && tileTemplate!.end != null) {
      return DateTime.fromMillisecondsSinceEpoch(tileTemplate!.end!);
    }
  }
}