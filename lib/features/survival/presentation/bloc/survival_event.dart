part of 'survival_bloc.dart';

abstract class SurvivalEvent extends Equatable {
  const SurvivalEvent();
}

class LoadSurvivalMode extends SurvivalEvent {
  const LoadSurvivalMode(this.dashboard);
  final DashboardEntity dashboard;

  @override
  List<Object> get props => [dashboard];
}

class FetchSurvivalTips extends SurvivalEvent {
  const FetchSurvivalTips({required this.language});
  final String language;

  @override
  List<Object> get props => [language];
}
