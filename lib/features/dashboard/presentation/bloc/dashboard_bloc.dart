import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:penyintas_app/features/dashboard/domain/usecases/get_dashboard_usecase.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({required GetDashboardUseCase getDashboard})
      : _getDashboard = getDashboard,
        super(const DashboardInitial()) {
    on<LoadDashboard>(_onLoad);
    on<DashboardRefreshed>(_onRefresh);
  }

  final GetDashboardUseCase _getDashboard;

  Future<void> _onLoad(
      LoadDashboard event, Emitter<DashboardState> emit) async {
    emit(const DashboardLoading());
    await emit.forEach(
      _getDashboard(const NoParams()),
      onData: (result) => result.fold(
        (failure) => DashboardError(failure.message),
        (entity) => DashboardLoaded(entity),
      ),
      onError: (e, s) => const DashboardError('Terjadi kesalahan.'),
    );
  }

  Future<void> _onRefresh(
      DashboardRefreshed event, Emitter<DashboardState> emit) async {
    await emit.forEach(
      _getDashboard(const NoParams()),
      onData: (result) => result.fold(
        (failure) => DashboardError(failure.message),
        (entity) => DashboardLoaded(entity),
      ),
      onError: (e, s) => const DashboardError('Terjadi kesalahan.'),
    );
  }
}
