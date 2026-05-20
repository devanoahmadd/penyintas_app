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
    required this.remainingDays,
    this.rentExpense = 0,
    this.utilitiesExpense = 0,
    this.internetExpense = 0,
    this.phoneExpense = 0,
    this.otherFixedExpense = 0,
    this.emergencyFundPct = 0.10,
  });
  final int income;
  final int paymentDate;
  final int rentExpense;
  final int utilitiesExpense;
  final int internetExpense;
  final int phoneExpense;
  final int otherFixedExpense;
  final int remainingDays;
  final double emergencyFundPct;

  int get fixedExpenses =>
      rentExpense + utilitiesExpense + internetExpense + phoneExpense + otherFixedExpense;

  @override
  List<Object> get props => [
        income,
        paymentDate,
        rentExpense,
        utilitiesExpense,
        internetExpense,
        phoneExpense,
        otherFixedExpense,
        remainingDays,
        emergencyFundPct,
      ];
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
