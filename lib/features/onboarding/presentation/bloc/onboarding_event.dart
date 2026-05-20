part of 'onboarding_bloc.dart';

sealed class OnboardingEvent extends Equatable {
  const OnboardingEvent();
}

class OnboardingStarted extends OnboardingEvent {
  const OnboardingStarted();
  @override
  List<Object> get props => [];
}

class OnboardingBackPressed extends OnboardingEvent {
  const OnboardingBackPressed();
  @override
  List<Object> get props => [];
}

class Step1Submitted extends OnboardingEvent {
  const Step1Submitted({required this.income, required this.paymentDate});
  final int income;
  final int paymentDate;
  @override
  List<Object> get props => [income, paymentDate];
}

class Step2Submitted extends OnboardingEvent {
  const Step2Submitted({
    this.rentExpense = 0,
    this.utilitiesExpense = 0,
    this.internetExpense = 0,
    this.phoneExpense = 0,
    this.otherFixedExpense = 0,
  });
  final int rentExpense;
  final int utilitiesExpense;
  final int internetExpense;
  final int phoneExpense;
  final int otherFixedExpense;

  int get fixedExpenses =>
      rentExpense + utilitiesExpense + internetExpense + phoneExpense + otherFixedExpense;

  @override
  List<Object> get props => [
        rentExpense,
        utilitiesExpense,
        internetExpense,
        phoneExpense,
        otherFixedExpense,
      ];
}

class Step3Submitted extends OnboardingEvent {
  const Step3Submitted({required this.emergencyFundPct});
  final double emergencyFundPct;
  @override
  List<Object> get props => [emergencyFundPct];
}

class OnboardingRetryRequested extends OnboardingEvent {
  const OnboardingRetryRequested();
  @override
  List<Object> get props => [];
}
