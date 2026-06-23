// lib/core/routing/onboarding_status.dart
/// Status gate onboarding. `profileCompleted` (preferences) + `onboardingCompleted`
/// (budget) menentukan rute. Lihat §9 spec.
enum OnboardingStatus { needsProfile, needsBudget, done }
