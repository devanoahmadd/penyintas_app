part of 'onboarding_bloc.dart';

sealed class OnboardingState extends Equatable {
  const OnboardingState();
}

class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
  @override
  List<Object> get props => [];
}

class OnboardingStep1 extends OnboardingState {
  const OnboardingStep1();
  @override
  List<Object> get props => [];
}

class OnboardingStep2 extends OnboardingState {
  const OnboardingStep2({required this.income, required this.paymentDate});
  final int income;
  final int paymentDate;
  @override
  List<Object> get props => [income, paymentDate];
}

class OnboardingStep3 extends OnboardingState {
  const OnboardingStep3({
    required this.income,
    required this.paymentDate,
    required this.fixedExpenses,
    required this.remainingDays,
  });
  final int income;
  final int paymentDate;
  final int fixedExpenses;
  final int remainingDays;
  @override
  List<Object> get props => [income, paymentDate, fixedExpenses, remainingDays];
}

class OnboardingCalculating extends OnboardingState {
  const OnboardingCalculating();
  @override
  List<Object> get props => [];
}

class OnboardingSuccess extends OnboardingState {
  const OnboardingSuccess({required this.dailyBudget});
  final int dailyBudget;
  @override
  List<Object> get props => [dailyBudget];
}

class OnboardingError extends OnboardingState {
  const OnboardingError({required this.message});
  final String message;
  @override
  List<Object> get props => [message];
}
