import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_widget/home_widget.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/core/utils/currency_config.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:penyintas_app/features/dashboard/domain/usecases/get_dashboard_usecase.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

// Android home widget key names — must match reads in PenyintasWidgetProvider.kt
const _kWidgetDaysToLive = 'days_to_live';
const _kWidgetBudgetFormatted = 'budget_today_formatted';
const _kWidgetBudgetStatus = 'budget_status';
const _kAndroidWidgetProvider = 'PenyintasWidgetProvider';

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

  // Tracks last values pushed to the widget to skip redundant platform-channel round-trips.
  (int, int, BudgetStatus)? _lastWidgetData;

  Future<void> _onLoad(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    await _streamDashboard(emit);
  }

  Future<void> _onRefresh(
    DashboardRefreshed event,
    Emitter<DashboardState> emit,
  ) async {
    await _streamDashboard(emit);
  }

  Future<void> _streamDashboard(Emitter<DashboardState> emit) => emit.forEach(
    _getDashboard(const NoParams()),
    onData: (result) =>
        result.fold((failure) => DashboardError(failure.message), (entity) {
          _pushToWidget(entity);
          return DashboardLoaded(entity);
        }),
    onError: (e, s) {
      try {
        FirebaseCrashlytics.instance.recordError(e, s);
      } catch (_) {}
      return const DashboardError('Terjadi kesalahan.');
    },
  );

  void _pushToWidget(DashboardEntity entity) {
    final key = (entity.daysToLive, entity.dailyBudget, entity.status);
    if (_lastWidgetData == key) return;
    final formatted = formatCurrency(entity.dailyBudget, CurrencyConfig.idr);
    // Parallel saves, then updateWidget; commit guard only after full success.
    // best-effort: failures must not propagate into the BLoC event handler.
    Future.wait([
          HomeWidget.saveWidgetData<int>(_kWidgetDaysToLive, entity.daysToLive),
          HomeWidget.saveWidgetData<String>(_kWidgetBudgetFormatted, formatted),
          HomeWidget.saveWidgetData<String>(
            _kWidgetBudgetStatus,
            entity.status.name,
          ),
        ])
        .then<void>(
          (_) => HomeWidget.updateWidget(androidName: _kAndroidWidgetProvider),
        )
        .then<void>((_) {
          _lastWidgetData = key;
        })
        .catchError((_) {});
  }
}
