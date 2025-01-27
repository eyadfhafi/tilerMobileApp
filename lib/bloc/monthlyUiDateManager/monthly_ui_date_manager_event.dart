part of 'monthly_ui_date_manager_bloc.dart';

abstract class MonthlyUiDateManagerEvent extends Equatable {
  const MonthlyUiDateManagerEvent();

  @override
  List<Object> get props => [];
}

class UpdateSelectedMonthOnPicking extends MonthlyUiDateManagerEvent {

  const UpdateSelectedMonthOnPicking();

  @override
  List<Object> get props => [];
}
class UpdateSelectedMonthOnSwiping extends MonthlyUiDateManagerEvent {
  DateTime selectedTime;
   UpdateSelectedMonthOnSwiping({required this.selectedTime});

  @override
  List<Object> get props => [selectedTime];
}
class ChangeYear extends MonthlyUiDateManagerEvent {
  final int year;

  const ChangeYear({required this.year});

  @override
  List<Object> get props => [year];
}

class ChangeMonth extends MonthlyUiDateManagerEvent {
  final int month;

  const ChangeMonth({required this.month});

  @override
  List<Object> get props => [month];
}
class ResetTempEvent extends MonthlyUiDateManagerEvent {}

class LogOutMonthlyUiDateManagerEvent extends MonthlyUiDateManagerEvent {
  const LogOutMonthlyUiDateManagerEvent();

  @override
  List<Object> get props => [];
}
