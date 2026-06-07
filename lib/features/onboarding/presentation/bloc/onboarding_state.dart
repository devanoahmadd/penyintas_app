part of 'onboarding_bloc.dart';

sealed class OnboardingState extends Equatable {
  const OnboardingState();
}

class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
  @override
  List<Object> get props => [];
}

// #208: OnboardingStep1/2/3 removed — UI manages navigation state locally.
// BLoC only tracks: Initial → Calculating → Success|Error.

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
