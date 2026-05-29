import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/core/utils/date_helper.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_limit_entity.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_overview_entity.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';
import 'package:penyintas_app/features/budget/domain/usecases/delete_budget_limit_usecase.dart';
import 'package:penyintas_app/features/budget/domain/usecases/get_budget_limits_usecase.dart';
import 'package:penyintas_app/features/budget/domain/usecases/get_budget_overview_usecase.dart';
import 'package:penyintas_app/features/budget/domain/usecases/get_budget_settings_usecase.dart';
import 'package:penyintas_app/features/budget/domain/usecases/save_budget_limit_usecase.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/domain/repositories/transaction_repository.dart';

part 'budget_limits_event.dart';
part 'budget_limits_state.dart';

class BudgetLimitsBloc extends Bloc<BudgetLimitsEvent, BudgetLimitsState> {
  BudgetLimitsBloc({
    required GetBudgetSettingsUseCase getBudgetSettings,
    required GetBudgetLimitsUseCase getBudgetLimits,
    required SaveBudgetLimitUseCase saveBudgetLimit,
    required DeleteBudgetLimitUseCase deleteBudgetLimit,
    required GetBudgetOverviewUseCase getBudgetOverview,
    required TransactionRepository transactionRepository,
  })  : _getSettings = getBudgetSettings,
        _getLimits = getBudgetLimits,
        _save = saveBudgetLimit,
        _delete = deleteBudgetLimit,
        _getOverview = getBudgetOverview,
        _txRepo = transactionRepository,
        super(const BudgetLimitsInitial()) {
    on<LoadBudgetLimits>(_onLoad, transformer: droppable());
    on<SaveBudgetLimit>(_onSave, transformer: sequential());
    on<DeleteBudgetLimit>(_onDelete, transformer: sequential());
    on<ToggleBudgetLimit>(_onToggle, transformer: sequential());
  }

  final GetBudgetSettingsUseCase _getSettings;
  final GetBudgetLimitsUseCase _getLimits;
  final SaveBudgetLimitUseCase _save;
  final DeleteBudgetLimitUseCase _delete;
  final GetBudgetOverviewUseCase _getOverview;
  final TransactionRepository _txRepo;

  Future<void> _onLoad(
    LoadBudgetLimits event,
    Emitter<BudgetLimitsState> emit,
  ) async {
    emit(const BudgetLimitsLoading());

    final settingsResult = await _getSettings(const NoParams());
    BudgetSettingsEntity? settings;
    settingsResult.fold(
      (f) => emit(BudgetLimitsError(f.message)),
      (s) => settings = s,
    );
    if (settings == null) return;

    final limitsResult = await _getLimits(const NoParams());
    List<BudgetLimitEntity>? limits;
    limitsResult.fold(
      (f) => emit(BudgetLimitsError(f.message)),
      (l) => limits = l,
    );
    if (limits == null) return;

    final overview = await _computeOverview(settings!, limits!);
    emit(BudgetLimitsLoaded(limits: limits!, overview: overview));
  }

  Future<void> _onSave(
    SaveBudgetLimit event,
    Emitter<BudgetLimitsState> emit,
  ) async {
    final result = await _save(event.limit);
    await result.fold(
      (f) async => emit(BudgetLimitsError(f.message)),
      (_) async {
        final limitsResult = await _getLimits(const NoParams());
        await limitsResult.fold(
          (f) async => emit(BudgetLimitsError(f.message)),
          (limits) async {
            final settingsResult = await _getSettings(const NoParams());
            await settingsResult.fold(
              (f) async => emit(BudgetLimitsError(f.message)),
              (settings) async {
                final overview = await _computeOverview(settings, limits);
                emit(BudgetLimitsLoaded(limits: limits, overview: overview));
              },
            );
          },
        );
      },
    );
  }

  Future<void> _onDelete(
    DeleteBudgetLimit event,
    Emitter<BudgetLimitsState> emit,
  ) async {
    final current = state;
    if (current is! BudgetLimitsLoaded) return;

    final result = await _delete(
      DeleteLimitParams(id: event.id, categoryName: event.categoryName),
    );
    result.fold(
      (f) => emit(BudgetLimitsError(f.message)),
      (_) {
        final updatedLimits =
            current.limits.where((l) => l.id != event.id).toList();
        emit(BudgetLimitsLoaded(
          limits: updatedLimits,
          overview: current.overview,
        ));
      },
    );
  }

  Future<void> _onToggle(
    ToggleBudgetLimit event,
    Emitter<BudgetLimitsState> emit,
  ) async {
    final current = state;
    if (current is! BudgetLimitsLoaded) return;

    final target = current.limits.firstWhere(
      (l) => l.id == event.id,
      orElse: () => current.limits.first,
    );
    final updated = target.copyWith(
      isEnabled: event.isEnabled,
      updatedAt: DateTime.now(),
    );

    // Inline save logic (avoids calling add() which can deadlock with sequential transformer)
    final result = await _save(updated);
    await result.fold(
      (f) async => emit(BudgetLimitsError(f.message)),
      (_) async {
        final limitsResult = await _getLimits(const NoParams());
        await limitsResult.fold(
          (f) async => emit(BudgetLimitsError(f.message)),
          (limits) async {
            final settingsResult = await _getSettings(const NoParams());
            await settingsResult.fold(
              (f) async => emit(BudgetLimitsError(f.message)),
              (settings) async {
                final overview = await _computeOverview(settings, limits);
                emit(BudgetLimitsLoaded(limits: limits, overview: overview));
              },
            );
          },
        );
      },
    );
  }

  Future<BudgetOverviewEntity> _computeOverview(
    BudgetSettingsEntity settings,
    List<BudgetLimitEntity> limits,
  ) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final txResult = await _txRepo.getTransactions(from: monthStart, to: now);
    final txns = txResult.fold(
      (_) => <TransactionEntity>[],
      (list) => list,
    );
    final remaining = remainingDaysInCycle(settings.paymentDate);
    return _getOverview(OverviewParams(
      settings: settings,
      limits: limits,
      currentPeriodTransactions: txns,
      remainingDays: remaining,
    ));
  }
}
