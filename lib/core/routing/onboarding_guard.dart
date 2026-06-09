import 'package:penyintas_app/features/onboarding/data/datasources/onboarding_local_datasource.dart';

class OnboardingGuard {
  OnboardingGuard(this._datasource);

  final OnboardingLocalDataSource _datasource;
  bool? _cache;

  Future<bool> isOnboardingDone() async {
    _cache ??= await _datasource.isOnboardingCompleted();
    return _cache!;
  }

  void resetCache() => _cache = null;
}
