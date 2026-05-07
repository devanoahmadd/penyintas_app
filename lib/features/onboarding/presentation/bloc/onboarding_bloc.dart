import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/utils/analytics_service.dart';
import 'package:penyintas_app/core/utils/date_helper.dart';
import 'package:penyintas_app/features/onboarding/domain/entities/budget_settings_entity.dart';
import 'package:penyintas_app/features/onboarding/domain/usecases/calculate_daily_budget_usecase.dart';
import 'package:penyintas_app/features/onboarding/domain/usecases/save_budget_settings_usecase.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc({
    required SaveBudgetSettingsUseCase saveBudgetSettings,
    required CalculateDailyBudgetUseCase calculateDailyBudget,
    required AnalyticsService analyticsService,
  })  : _saveBudgetSettings = saveBudgetSettings,
        _calculateDailyBudget = calculateDailyBudget,
        _analyticsService = analyticsService,
        super(const OnboardingInitial()) {
    on<OnboardingStarted>(_onStarted);
    on<OnboardingBackPressed>(_onBack);
    on<Step1Submitted>(_onStep1);
    on<Step2Submitted>(_onStep2);
    on<Step3Submitted>(_onStep3);
  }

  final SaveBudgetSettingsUseCase _saveBudgetSettings;
  final CalculateDailyBudgetUseCase _calculateDailyBudget;
  final AnalyticsService _analyticsService;

  void _onStarted(OnboardingStarted event, Emitter<OnboardingState> emit) {
    emit(const OnboardingStep1());
  }

  void _onBack(OnboardingBackPressed event, Emitter<OnboardingState> emit) {
    if (state is OnboardingStep2) {
      emit(const OnboardingStep1());
    } else if (state is OnboardingStep3) {
      final s = state as OnboardingStep3;
      emit(OnboardingStep2(income: s.income, paymentDate: s.paymentDate));
    }
  }

  void _onStep1(Step1Submitted event, Emitter<OnboardingState> emit) {
    emit(OnboardingStep2(income: event.income, paymentDate: event.paymentDate));
  }

  void _onStep2(Step2Submitted event, Emitter<OnboardingState> emit) {
    final s = state as OnboardingStep2;
    final days = remainingDaysInCycle(s.paymentDate);
    emit(OnboardingStep3(
      income: s.income,
      paymentDate: s.paymentDate,
      fixedExpenses: event.fixedExpenses,
      remainingDays: days > 0 ? days : 30,
    ));
  }

  Future<void> _onStep3(
    Step3Submitted event,
    Emitter<OnboardingState> emit,
  ) async {
    final s = state as OnboardingStep3;
    emit(const OnboardingCalculating());

    final calcResult = await _calculateDailyBudget(CalcParams(
      income: s.income,
      fixedExpenses: s.fixedExpenses,
      emergencyPct: event.emergencyFundPct,
      remainingDays: s.remainingDays,
    ));

    final settings = BudgetSettingsEntity(
      monthlyIncome: s.income,
      paymentDate: s.paymentDate,
      fixedExpenses: s.fixedExpenses,
      emergencyFundPct: event.emergencyFundPct,
      createdAt: DateTime.now(),
    );

    final saveResult = await _saveBudgetSettings(settings);

    saveResult.fold(
      (failure) => emit(OnboardingError(message: failure.message)),
      (_) => calcResult.fold(
        (failure) => emit(OnboardingError(message: failure.message)),
        (result) {
          _analyticsService.logOnboardingCompleted();
          emit(OnboardingSuccess(dailyBudget: result.dailyBudget));
        },
      ),
    );
  }
}
