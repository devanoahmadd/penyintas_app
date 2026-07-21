import 'package:penyintas_app/core/routing/onboarding_status.dart';
import 'package:penyintas_app/features/onboarding/data/datasources/onboarding_local_datasource.dart';
import 'package:penyintas_app/features/preferences/domain/repositories/preferences_repository.dart';

class OnboardingGuard {
  OnboardingGuard({
    required OnboardingLocalDataSource onboardingDs,
    required PreferencesRepository prefsRepo,
  }) : _onboardingDs = onboardingDs,
       _prefsRepo = prefsRepo;

  final OnboardingLocalDataSource _onboardingDs;
  final PreferencesRepository _prefsRepo;
  OnboardingStatus? _cache;

  Future<OnboardingStatus> status() async {
    if (_cache != null) return _cache!;
    OnboardingStatus computed;
    try {
      final prefs = await _prefsRepo.read();
      if (!prefs.profileCompleted) {
        // Pure mapping. CATATAN (A2/§9): akun lama (budget done, profil belum)
        // di-smart-default oleh Phase D syncOnLaunch SEBELUM guard dipanggil,
        // jadi kombinasi itu tak pernah sampai sini sebagai !profileCompleted.
        computed = OnboardingStatus.needsProfile;
      } else {
        final budgetDone = await _onboardingDs.isOnboardingCompleted();
        computed = budgetDone
            ? OnboardingStatus.done
            : OnboardingStatus.needsBudget;
      }
    } catch (_) {
      computed = OnboardingStatus.needsProfile; // fail-safe (A8)
    }
    _cache = computed;
    return computed;
  }

  void resetCache() => _cache = null;
}
