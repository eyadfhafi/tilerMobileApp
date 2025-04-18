import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Add this import
import 'package:tiler_app/components/TextInputWidget.dart';
import 'package:tiler_app/components/durationInputWidget.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/routes/authenticatedUser/contactInputField.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class NewTileSheetWidget extends StatefulWidget {
  final Function? onAddTile;
  final Function? onTileUpdate;
  final Function? onCancel;
  final NewTile? newTile;
  NewTileSheetWidget(
      {this.onAddTile, this.onCancel, this.newTile, this.onTileUpdate});
  @override
  NewTileSheetState createState() => NewTileSheetState();
}

class NewTileSheetState extends State<NewTileSheetWidget> {
  late final NewTile newTile;
  late ButtonStyle addButtonStyle;
  // late List<Contact> contacts = [];
  @override
  void initState() {
    super.initState();
    addButtonStyle = ButtonStyle(
      side:
          MaterialStateProperty.all(BorderSide(color: TileStyles.primaryColor)),
      shadowColor: MaterialStateProperty.resolveWith((states) {
        return Colors.transparent;
      }),
      elevation: MaterialStateProperty.resolveWith((states) {
        return 0;
      }),
      backgroundColor: MaterialStateProperty.resolveWith((states) {
        return Colors.transparent;
      }),
      foregroundColor: MaterialStateProperty.resolveWith((states) {
        return TileStyles.primaryColor;
      }),
      minimumSize: MaterialStateProperty.resolveWith((states) {
        return Size(MediaQuery.sizeOf(context).width - 20, 50);

        // Size.(MediaQuery.sizeOf(context).width);
      }),
    );
    this.newTile =
        NewTile.fromJson((this.widget.newTile ?? NewTile()).toJson());
    // if (this.newTile.contacts != null && this.newTile.contacts!.isNotEmpty) {
    //   contacts =
    //       this.newTile.contacts!.map<Contact>((e) => e.toContact()).toList();
    // }
  }

  Widget _renderOptionalFields() {
    return SizedBox.shrink();
  }

  void onTileNameChange(String? tileName) {
    newTile.Name = "";
    if (tileName != null && tileName.isNotEmpty) {
      newTile.Name = tileName;
      setState(() {});
    }
  }

  void onDurationChange(Duration? duration) {
    newTile.DurationDays = "";
    newTile.DurationHours = "";
    newTile.DurationMinute = "";
    setState(() {
      if (duration != null && duration.inMinutes > 0) {
        int totalMinutes = duration.inMinutes;
        int dayInMinutes = Duration.minutesPerDay;
        int hourInMinutes = Duration.minutesPerHour;
        int days = totalMinutes ~/ dayInMinutes;
        totalMinutes = totalMinutes % dayInMinutes;
        int hours = totalMinutes ~/ hourInMinutes;
        int minutes = totalMinutes % hourInMinutes;
        newTile.DurationDays = days.toString();
        newTile.DurationHours = hours.toString();
        newTile.DurationMinute = minutes.toString();
      }
    });
    if (this.widget.onTileUpdate != null) {
      this.widget.onTileUpdate!(this.newTile);
    }
  }

  Duration? _getDuration() {
    int dayInMinutes = Duration.minutesPerDay;
    int hourInMinutes = Duration.minutesPerHour;
    int? totalMinutes;
    if (newTile.DurationDays != null && newTile.DurationDays!.isNotEmpty) {
      int? days = int.tryParse(newTile.DurationDays!);
      if (days != null) {
        totalMinutes = (totalMinutes ?? 0) + dayInMinutes * days;
      }
    }

    if (newTile.DurationHours != null && newTile.DurationHours!.isNotEmpty) {
      int? hours = int.tryParse(newTile.DurationHours!);
      if (hours != null) {
        totalMinutes = (totalMinutes ?? 0) + hourInMinutes * hours;
      }
    }

    if (newTile.DurationMinute != null && newTile.DurationMinute!.isNotEmpty) {
      int? minutes = int.tryParse(newTile.DurationMinute!);
      if (minutes != null) {
        totalMinutes = (totalMinutes ?? 0) + minutes;
      }
    }

    if (totalMinutes != null) {
      return Duration(minutes: totalMinutes);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TileStyles.primaryContrastColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: TileStyles.appBarColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            padding: EdgeInsets.all(16),
            child: Text(
              AppLocalizations.of(context)!.addTile,
              style: TextStyle(
                color: TileStyles.appBarTextColor,
                fontFamily: TileStyles.rubikFontName,
                fontSize: TileStyles.inputFontSize,
              ),
            ),
            alignment: Alignment.centerLeft,
          ),
          const SizedBox.square(
            dimension: 5,
          ),
          Padding(
            padding: TileStyles.inpuPadding,
            child: TextInputWidget(
              placeHolder: AppLocalizations.of(context)!.tileName,
              value: newTile.Name,
              onTextChange: (value) {
                setState(() {
                  newTile.Name = value;
                });
              },
            ),
          ),
          const SizedBox.square(
            dimension: 5,
          ),
          Padding(
            padding: TileStyles.inpuPadding,
            child: DurationInputWidget(
              duration: _getDuration(),
              onDurationChange: onDurationChange,
            ),
          ),
          _renderOptionalFields(),
          // Padding(
          //   padding: TileStyles.inpuPadding,
          //   child: ContactInputFieldWidget(
          //       isReadOnly: false,
          //       contentHeight: this.contacts.isEmpty
          //           ? 0
          //           : this.contacts.length < 3
          //               ? 50
          //               : 100,
          //       contacts: this.contacts,
          //       onContactUpdate: (List<Contact> updatedContacts) {
          //         setState(() {
          //           this.contacts = updatedContacts;
          //         });
          //       }),
          // ),
          const SizedBox.square(
            dimension: 5,
          ),
          this.newTile.Name.isNot_NullEmptyOrWhiteSpace(minLength: 3) &&
                  this.newTile.getDuration() != null
              ? ElevatedButton.icon(
                  onPressed: () {
                    if (this.widget.onAddTile != null) {
                      // newTile.contacts =
                      //     this.contacts.map((e) => e.toContactModel()).toList();
                      this.widget.onAddTile!(newTile);
                    }
                  },
                  style: addButtonStyle,
                  icon: Icon(Icons.check),
                  label: Text(this.widget.newTile == null
                      ? AppLocalizations.of(context)!.add
                      : AppLocalizations.of(context)!.update))
              : SizedBox.shrink(),
          SizedBox.square(
            dimension: 50,
          )
        ],
      ),
    );
  }
}
