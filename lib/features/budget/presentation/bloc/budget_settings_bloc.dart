import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';
import 'package:penyintas_app/features/budget/domain/usecases/get_budget_settings_usecase.dart';
import 'package:penyintas_app/features/budget/domain/usecases/save_budget_settings_usecase.dart';
import 'package:penyintas_app/features/dashboard/domain/repositories/dashboard_repository.dart';

part 'budget_settings_event.dart';
part 'budget_settings_state.dart';

class BudgetSettingsBloc
    extends Bloc<BudgetSettingsEvent, BudgetSettingsState> {
  BudgetSettingsBloc({
    required GetBudgetSettingsUseCase getBudgetSettings,
    required SaveBudgetSettingsUseCase saveBudgetSettings,
    required DashboardRepository dashboardRepository,
  }) : _get = getBudgetSettings,
       _save = saveBudgetSettings,
       _dashboard = dashboardRepository,
       super(const BudgetSettingsInitial()) {
    on<LoadBudgetSettings>(_onLoad, transformer: droppable());
    on<SaveBudgetSettings>(_onSave, transformer: sequential());
  }

  final GetBudgetSettingsUseCase _get;
  final SaveBudgetSettingsUseCase _save;
  final DashboardRepository _dashboard;

  Future<void> _onLoad(
    LoadBudgetSettings event,
    Emitter<BudgetSettingsState> emit,
  ) async {
    emit(const BudgetSettingsLoading());
    final result = await _get(const NoParams());
    result.fold(
      (failure) => emit(BudgetSettingsError(failure.message)),
      (settings) => emit(BudgetSettingsLoaded(settings)),
    );
  }

  Future<void> _onSave(
    SaveBudgetSettings event,
    Emitter<BudgetSettingsState> emit,
  ) async {
    emit(const BudgetSettingsSaving());
    final result = await _save(event.settings);
    result.fold((failure) => emit(BudgetSettingsError(failure.message)), (_) {
      emit(const BudgetSettingsSaved());
      // B4/§5.2: settings baru tersimpan → cache dashboard basi (mis. pivot
      // M1 fixedExpenses) HARUS dibuang & stream aktif disegarkan sekarang.
      _dashboard.invalidateSettingsCache();
    });
  }
}
