import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/core/utils/analytics_service.dart';
import 'package:penyintas_app/features/auth/domain/usecases/push_user_settings_usecase.dart';
import 'package:penyintas_app/core/utils/date_helper.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';
import 'package:penyintas_app/features/onboarding/domain/usecases/calculate_daily_budget_usecase.dart';
import 'package:penyintas_app/features/budget/domain/usecases/save_budget_settings_usecase.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

/// #208: simplified BLoC.
/// State machine: Initial → Calculating → Success | Error
/// Navigation between onboarding steps is handled locally by OnboardingPage.
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc({
    required SaveBudgetSettingsUseCase saveBudgetSettings,
    required CalculateDailyBudgetUseCase calculateDailyBudget,
    required AnalyticsService analyticsService,
    required PushUserSettingsUseCase pushUserSettings,
  }) : _saveBudgetSettings = saveBudgetSettings,
       _calculateDailyBudget = calculateDailyBudget,
       _analyticsService = analyticsService,
       _pushUserSettings = pushUserSettings,
       super(const OnboardingInitial()) {
    on<OnboardingSubmitted>(_onSubmitted);
  }

  final SaveBudgetSettingsUseCase _saveBudgetSettings;
  final CalculateDailyBudgetUseCase _calculateDailyBudget;
  final AnalyticsService _analyticsService;
  final PushUserSettingsUseCase _pushUserSettings;

  /// #208: single handler that receives all form data and runs the full pipeline.
  /// Safe to call multiple times (retry-friendly) — state is reset to Calculating first.
  Future<void> _onSubmitted(
    OnboardingSubmitted event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(const OnboardingCalculating());

    final days = () {
      final d = remainingDaysInCycle(event.paymentDate);
      return d > 0 ? d : daysInCycle(event.paymentDate);
    }();

    final calcResult = await _calculateDailyBudget(
      CalcParams(
        income: event.income,
        fixedExpenses: event.fixedExpenses,
        emergencyPct: event.emergencyFundPct,
        remainingDays: days,
      ),
    );

    // #251: jika kalkulasi gagal (mis. income <= 0), JANGAN tulis app_settings.
    // budget_local_datasource menulis onboardingCompleted=true unconditional —
    // tanpa guard ini user bisa ter-mark "done" dengan income=0 (terjebak).
    final String? calcError = calcResult.fold((f) => f.message, (_) => null);
    if (calcError != null) {
      emit(OnboardingError(message: calcError));
      return;
    }

    final settings = BudgetSettingsEntity(
      monthlyIncome: event.income,
      paymentDate: event.paymentDate,
      rentExpense: event.expenses['kos'] ?? 0,
      utilitiesExpense: event.expenses['listrik'] ?? 0,
      internetExpense: event.expenses['internet'] ?? 0,
      phoneExpense: event.expenses['pulsa'] ?? 0,
      otherFixedExpense: event.expenses['lain'] ?? 0,
      emergencyFundPct: event.emergencyFundPct,
      createdAt: DateTime.now(),
    );

    final saveResult = await _saveBudgetSettings(settings);

    await saveResult.fold<Future<void>>(
      (failure) async => emit(OnboardingError(message: failure.message)),
      (_) async => calcResult.fold(
        (failure) => emit(OnboardingError(message: failure.message)),
        (result) async {
          _analyticsService.logOnboardingCompleted();
          // #211: await remote flag; failure is non-fatal (local data is source of truth)
          await _pushUserSettings(
            const NoParams(),
          ).then((res) => res.fold((_) {}, (_) {})).catchError((_) {});
          emit(OnboardingSuccess(dailyBudget: result.dailyBudget));
        },
      ),
    );
  }
}
