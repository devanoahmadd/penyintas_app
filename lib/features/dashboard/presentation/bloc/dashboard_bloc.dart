import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
    // restartable: event LoadDashboard baru batalkan stream lama
    on<LoadDashboard>(_onLoad, transformer: restartable());
    // droppable: abaikan DashboardRefreshed saat stream masih aktif
    on<DashboardRefreshed>(_onRefresh, transformer: droppable());
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
      onError: (e, s) {
        try {
          FirebaseCrashlytics.instance.recordError(e, s);
        } catch (_) {}
        return const DashboardError('Terjadi kesalahan.');
      },
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
      onError: (e, s) {
        try {
          FirebaseCrashlytics.instance.recordError(e, s);
        } catch (_) {}
        return const DashboardError('Terjadi kesalahan.');
      },
    );
  }
}
