part of 'onboarding_bloc.dart';

sealed class OnboardingEvent extends Equatable {
  const OnboardingEvent();
}

/// #208: single submit event replaces the fragile Step1/2/3 burst pattern.
/// UI holds all form state; bloc receives it atomically.
class OnboardingSubmitted extends OnboardingEvent {
  const OnboardingSubmitted({
    required this.income,
    required this.paymentDate,
    required this.expenses,
    required this.emergencyFundPct,
  });
  final int income;
  final int paymentDate;
  final Map<String, int> expenses;
  final double emergencyFundPct;

  int get fixedExpenses => expenses.values.fold(0, (s, v) => s + v);

  @override
  List<Object> get props => [income, paymentDate, expenses, emergencyFundPct];
}
