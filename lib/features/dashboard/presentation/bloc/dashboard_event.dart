part of 'dashboard_bloc.dart';

sealed class DashboardEvent extends Equatable {
  const DashboardEvent();
}

class LoadDashboard extends DashboardEvent {
  const LoadDashboard();
  @override
  List<Object> get props => [];
}

class DashboardRefreshed extends DashboardEvent {
  const DashboardRefreshed();
  @override
  List<Object> get props => [];
}
