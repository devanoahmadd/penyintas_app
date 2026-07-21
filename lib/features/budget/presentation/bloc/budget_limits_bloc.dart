import 'dart:async';

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
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/get_limitable_categories_usecase.dart';

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
    required GetLimitableCategoriesUseCase getLimitableCategories,
  }) : _getSettings = getBudgetSettings,
       _getLimits = getBudgetLimits,
       _save = saveBudgetLimit,
       _delete = deleteBudgetLimit,
       _getOverview = getBudgetOverview,
       _txRepo = transactionRepository,
       _getLimitableCategories = getLimitableCategories,
       super(const BudgetLimitsInitial()) {
    on<LoadBudgetLimits>(_onLoad, transformer: droppable());
    on<SaveBudgetLimit>(_onSave, transformer: sequential());
    on<DeleteBudgetLimit>(_onDelete, transformer: sequential());
    on<ToggleBudgetLimit>(_onToggle, transformer: sequential());
    // restartable: ledakan perubahan (mis. markSynced saat sync awal)
    // dikoalesi — event baru membatalkan recompute yang masih in-flight.
    on<_TransactionsChanged>(_onTxChanged, transformer: restartable());

    // Reaktif: setiap perubahan transaksi (tambah/edit/hapus) dari mana pun
    // memicu recompute overview agar `spent` per kategori tidak basi.
    _txChangeSub = _txRepo.watchTransactionChanges().listen(
      (_) => add(const _TransactionsChanged()),
    );
  }

  StreamSubscription<void>? _txChangeSub;

  final GetBudgetSettingsUseCase _getSettings;
  final GetBudgetLimitsUseCase _getLimits;
  final SaveBudgetLimitUseCase _save;
  final DeleteBudgetLimitUseCase _delete;
  final GetBudgetOverviewUseCase _getOverview;
  final TransactionRepository _txRepo;
  final GetLimitableCategoriesUseCase _getLimitableCategories;

  Future<void> _onLoad(
    LoadBudgetLimits event,
    Emitter<BudgetLimitsState> emit,
  ) async {
    final alreadyLoaded = state is BudgetLimitsLoaded;
    // Mount ganda (dashboard↔budget pada singleton): skip jika sudah loaded.
    if (alreadyLoaded && !event.force) return;
    // Refresh eksplisit (force): recompute tanpa emit Loading → tak ada
    // skeleton flash. Pakai jalur mutasi yang sudah teruji.
    if (alreadyLoaded && event.force) {
      await _reloadAfterMutation(emit);
      return;
    }
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
      (_) async => _reloadAfterMutation(emit),
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
    await result.fold((f) async => emit(BudgetLimitsError(f.message)), (
      _,
    ) async {
      final updatedLimits = current.limits
          .where((l) => l.id != event.id)
          .toList();
      await _reloadAfterMutation(emit, updatedLimits: updatedLimits);
    });
  }

  Future<void> _onToggle(
    ToggleBudgetLimit event,
    Emitter<BudgetLimitsState> emit,
  ) async {
    final current = state;
    if (current is! BudgetLimitsLoaded) return;

    final target = current.limits.where((l) => l.id == event.id).firstOrNull;
    if (target == null) return; // id tidak ditemukan — event stale, skip aman

    final updated = target.copyWith(
      isEnabled: event.isEnabled,
      updatedAt: DateTime.now(),
    );

    // Inline save (avoids calling add() which can deadlock with sequential transformer)
    final result = await _save(updated);
    await result.fold(
      (f) async => emit(BudgetLimitsError(f.message)),
      (_) async => _reloadAfterMutation(emit),
    );
  }

  /// Reaktif: transaksi berubah → recompute overview tanpa skeleton flash.
  /// No-op jika belum pernah Loaded — first load ditangani LoadBudgetLimits.
  Future<void> _onTxChanged(
    _TransactionsChanged event,
    Emitter<BudgetLimitsState> emit,
  ) async {
    if (state is! BudgetLimitsLoaded) return;
    await _reloadAfterMutation(emit);
  }

  /// Reload state setelah mutasi (save/toggle/delete) — fix #8.
  /// Jika [updatedLimits] diberikan (misal setelah delete), pakai langsung.
  /// Jika null, re-fetch limits dari DB.
  Future<void> _reloadAfterMutation(
    Emitter<BudgetLimitsState> emit, {
    List<BudgetLimitEntity>? updatedLimits,
  }) async {
    final List<BudgetLimitEntity> limits;
    if (updatedLimits != null) {
      limits = updatedLimits;
    } else {
      final limitsResult = await _getLimits(const NoParams());
      // Emit f.message (konsisten dengan _onLoad) dan return jika gagal.
      List<BudgetLimitEntity>? fetchedLimits;
      limitsResult.fold(
        (f) => emit(BudgetLimitsError(f.message)),
        (l) => fetchedLimits = l,
      );
      if (fetchedLimits == null) return;
      limits = fetchedLimits!;
    }
    final settingsResult = await _getSettings(const NoParams());
    await settingsResult.fold((f) async => emit(BudgetLimitsError(f.message)), (
      settings,
    ) async {
      final overview = await _computeOverview(settings, limits);
      emit(BudgetLimitsLoaded(limits: limits, overview: overview));
    });
  }

  Future<BudgetOverviewEntity> _computeOverview(
    BudgetSettingsEntity settings,
    List<BudgetLimitEntity> limits,
  ) async {
    // Satu `now` untuk semua pemanggilan date-helper — hindari divergence
    // jika eksekusi melintas tengah malam (fix finding #4).
    final now = DateTime.now();
    final start = cycleStart(settings.paymentDate, now: now);
    final txResult = await _txRepo.getTransactions(from: start, to: now);
    final txns = txResult.fold((_) => <TransactionEntity>[], (list) => list);
    final remaining = remainingDaysInCycle(settings.paymentDate, now: now);
    // cycleStart() sudah return midnight — tidak perlu re-extract (fix F1-8)
    final daysElapsed = now.difference(start).inDays.clamp(1, 366);

    // Fetch limitable categories dari DB (#Fase3B — bridge mapping dihapus)
    final categoriesResult = await _getLimitableCategories(const NoParams());
    final limitableCategories = categoriesResult.fold(
      (_) => <CategoryEntity>[],
      (cats) => cats,
    );

    return _getOverview(
      OverviewParams(
        settings: settings,
        limits: limits,
        currentPeriodTransactions: txns,
        remainingDays: remaining,
        daysElapsed: daysElapsed,
        limitableCategories: limitableCategories,
      ),
    );
  }

  @override
  Future<void> close() {
    _txChangeSub?.cancel();
    return super.close();
  }
}
