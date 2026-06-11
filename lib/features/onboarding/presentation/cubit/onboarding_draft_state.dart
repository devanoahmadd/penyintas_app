part of 'onboarding_draft_cubit.dart';

sealed class OnboardingDraftState extends Equatable {
  const OnboardingDraftState();
  @override
  List<Object?> get props => [];
}

class OnboardingDraftInitial extends OnboardingDraftState {
  const OnboardingDraftInitial();
}

/// [partial] null = tak ada draft tersimpan.
class OnboardingDraftLoaded extends OnboardingDraftState {
  const OnboardingDraftLoaded(this.partial);
  final PartialOnboardingState? partial;
  @override
  List<Object?> get props => [partial];
}
