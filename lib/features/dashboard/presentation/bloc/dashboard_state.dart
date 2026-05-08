part of 'dashboard_bloc.dart';

sealed class DashboardState extends Equatable {
  const DashboardState();
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
  @override
  List<Object> get props => [];
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
  @override
  List<Object> get props => [];
}

class DashboardLoaded extends DashboardState {
  const DashboardLoaded(this.entity);
  final DashboardEntity entity;
  @override
  List<Object> get props => [entity];
}

class DashboardError extends DashboardState {
  const DashboardError(this.message);
  final String message;
  @override
  List<Object> get props => [message];
}
