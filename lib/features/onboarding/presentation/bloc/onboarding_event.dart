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
  const Step2Submitted({required this.fixedExpenses});
  final int fixedExpenses;
  @override
  List<Object> get props => [fixedExpenses];
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
