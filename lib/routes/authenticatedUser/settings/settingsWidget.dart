import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/bloc/calendarTiles/calendar_tile_bloc.dart';
import 'package:tiler_app/bloc/deviceSetting/device_setting_bloc.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/bloc/monthlyUiDateManager/monthly_ui_date_manager_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/bloc/tilelistCarousel/tile_list_carousel_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/bloc/weeklyUiDateManager/weekly_ui_date_manager_bloc.dart';
import 'package:tiler_app/components/notification_overlay.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/themerHelper.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class Settings extends StatelessWidget {
  static final String routeName = '/Setting';
  final String _requestId = Utility.getUuid;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final textColor =
        brightness == Brightness.dark ? Colors.white : Colors.black;
    return BlocListener<DeviceSettingBloc, DeviceSettingState>(
      listener: (context, state) {
        NotificationOverlayMessage notificationOverlayMessage =
            NotificationOverlayMessage();
        if (state is DeviceSettingInitial && state.shouldLogout) {
          print("reset started");
          context.read<ScheduleBloc>().add(LogOutScheduleEvent(() => context));
          context
              .read<SubCalendarTileBloc>()
              .add(LogOutSubCalendarTileBlocEvent());
          context.read<UiDateManagerBloc>().add(LogOutUiDateManagerEvent());
          context
              .read<WeeklyUiDateManagerBloc>()
              .add(LogOutWeeklyUiDateManagerEvent());
          context
              .read<MonthlyUiDateManagerBloc>()
              .add(LogOutMonthlyUiDateManagerEvent());
          context.read<CalendarTileBloc>().add(LogOutCalendarTileEvent());
          context
              .read<TileListCarouselBloc>()
              .add(EnableCarouselScrollEvent(isImmediate: true));
          context
              .read<ScheduleSummaryBloc>()
              .add(LogOutScheduleDaySummaryEvent());
          Navigator.pushNamedAndRemoveUntil(
              context, '/LoggedOut', (route) => false);
        }
        if (state is DeviceSettingError) {
          final errorMessage = state.error is TilerError
              ? (state.error as TilerError).Message
              : state.error.toString();
          notificationOverlayMessage.showToast(
            context,
            errorMessage!,
            NotificationOverlayMessageType.error,
          );
        }
      },
      child: CancelAndProceedTemplateWidget(
        routeName: Settings.routeName,
        appBar: TileStyles.CancelAndProceedAppBar(
            AppLocalizations.of(context)!.settings),
        child: Column(
          children: [
            _buildListTile(
              icon: 'assets/icons/settings/AccountInfo.svg',
              title: AppLocalizations.of(context)!.accountInfo,
              color: textColor,
              onTap: () => Navigator.pushNamed(context, '/accountInfo'),
            ),
            _buildListTile(
              icon: 'assets/icons/settings/TilePreferences.svg',
              title: AppLocalizations.of(context)!.tilePreferences,
              color: textColor,
              onTap: () => Navigator.pushNamed(context, '/tilePreferences'),
            ),
            _buildListTile(
              icon: 'assets/icons/settings/NotificationsPreferences.svg',
              title: AppLocalizations.of(context)!.notificationsPreferences,
              color: textColor,
              onTap: () =>
                  Navigator.pushNamed(context, '/notificationsPreferences'),
            ),
            _buildDivider(),
            // _buildListTile(
            //   icon: 'assets/icons/settings/Security.svg',
            //   title: AppLocalizations.of(context)!.security,
            //   color: textColor,
            //   onTap: () => Navigator.pushNamed(context, '/security'),
            // ),
            _buildListTile(
              icon: 'assets/icons/settings/Connections.svg',
              title: AppLocalizations.of(context)!.connections,
              color: textColor,
              onTap: () => Navigator.pushNamed(context, '/Connections'),
            ),
            // _buildListTile(
            //   icon: 'assets/icons/settings/MyLocations.svg',
            //   title: AppLocalizations.of(context)!.myLocations,
            //   color: textColor,
            //   onTap: () => Navigator.pushNamed(context, '/myLocations'),
            // ),
            _buildDivider(),
            // _buildListTile(
            //   icon: 'assets/icons/settings/AboutTiler.svg',
            //   title: AppLocalizations.of(context)!.aboutTiler,
            //   color: textColor,
            //   onTap: () => Navigator.pushNamed(context, '/aboutTiler'),
            // ),
            _buildListTile(
              icon: 'assets/icons/settings/Logout.svg',
              title: AppLocalizations.of(context)!.logout,
              color: TileStyles.primaryColor,
              onTap: () {
                // context
                //     .read<DeviceSettingBloc>()
                //     .add(LogOutMainSettingDeviceSettingEvent(id: _requestId));

                AnalysticsSignal.send('SETTINGS_LOG_OUT_USER');
                OneSignal.logout().then((value) {
                  print("successful logged out of onesignal");
                }).catchError((onError) {
                  print("Failed to logout of onesignal");
                  print(onError);
                });

                context.read<DeviceSettingBloc>().add(
                    LogOutMainSettingDeviceSettingEvent(
                        id: _requestId, context: context));
              },
            ),
            // _buildListTile(
            //   icon: 'assets/icons/settings/DeleteAccount.svg',
            //   title: AppLocalizations.of(context)!.deleteAccount,
            //   color: TileStyles.primaryColor,
            //   onTap: () => context.read<DeviceSettingBloc>().add(
            //       DeleteAccountMainSettingDeviceSettingEvent(id: _requestId)),
            // ),
            // _buildDivider(),
            // Center(child: _buildDarkModeSwitch()),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.grey.shade300,
      margin: EdgeInsets.only(left: 50, right: 40),
    );
  }

  Widget _buildListTile(
      {required String icon,
      required String title,
      required Color color,
      Function()? onTap}) {
    return ListTile(
        leading: SvgPicture.asset(
          icon,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
        title: Text(title, style: TextStyle(color: color)),
        onTap: onTap);
  }

  Widget _buildDarkModeSwitch() {
    return BlocBuilder<DeviceSettingBloc, DeviceSettingState>(
      builder: (context, state) {
        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppLocalizations.of(context)!.darkMode,
                    style: TextStyle(fontSize: 16)),
                Switch(
                  value: state.isDarkMode,
                  onChanged: (value) {
                    ThemeManager.setThemeMode(value).then((_) {
                      context.read<DeviceSettingBloc>().add(
                          UpdateDarkModeMainSettingDeviceSettingEvent(
                              isDarkMode: value, id: _requestId));
                    });
                  },
                  activeColor: Colors.black,
                  inactiveTrackColor: Colors.grey.shade300,
                  activeTrackColor: Colors.black,
                  thumbColor: WidgetStateProperty.all(Colors.white),
                  thumbIcon: WidgetStateProperty.resolveWith((states) {
                    return Icon(
                      state.isDarkMode
                          ? Icons.nightlight_round
                          : Icons.wb_sunny,
                      color: Colors.grey.shade600,
                      size: 18,
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
