// test/core/routing/onboarding_guard_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/routing/onboarding_guard.dart';
import 'package:penyintas_app/core/routing/onboarding_status.dart';
import 'package:penyintas_app/features/onboarding/data/datasources/onboarding_local_datasource.dart';
import 'package:penyintas_app/features/preferences/domain/entities/preferences_entity.dart';
import 'package:penyintas_app/features/preferences/domain/repositories/preferences_repository.dart';

class _MockOnbDs extends Mock implements OnboardingLocalDataSource {}
class _MockPrefsRepo extends Mock implements PreferencesRepository {}

void main() {
  late _MockOnbDs onbDs;
  late _MockPrefsRepo prefsRepo;
  late OnboardingGuard guard;

  setUp(() {
    onbDs = _MockOnbDs();
    prefsRepo = _MockPrefsRepo();
    guard = OnboardingGuard(onboardingDs: onbDs, prefsRepo: prefsRepo);
  });

  PreferencesEntity prefs({required bool profile}) =>
      PreferencesEntity.defaults.copyWith(profileCompleted: profile);

  test('profil belum → needsProfile (tak peduli budget)', () async {
    when(() => prefsRepo.read()).thenAnswer((_) async => prefs(profile: false));
    when(() => onbDs.isOnboardingCompleted()).thenAnswer((_) async => true);
    expect(await guard.status(), OnboardingStatus.needsProfile);
  });

  test('profil ok + budget belum → needsBudget', () async {
    when(() => prefsRepo.read()).thenAnswer((_) async => prefs(profile: true));
    when(() => onbDs.isOnboardingCompleted()).thenAnswer((_) async => false);
    expect(await guard.status(), OnboardingStatus.needsBudget);
  });

  test('profil ok + budget ok → done', () async {
    when(() => prefsRepo.read()).thenAnswer((_) async => prefs(profile: true));
    when(() => onbDs.isOnboardingCompleted()).thenAnswer((_) async => true);
    expect(await guard.status(), OnboardingStatus.done);
  });

  test('read error → fail-safe needsProfile (A8)', () async {
    when(() => prefsRepo.read()).thenThrow(Exception('boom'));
    expect(await guard.status(), OnboardingStatus.needsProfile);
  });

  test('cache: read kedua tak query ulang', () async {
    when(() => prefsRepo.read()).thenAnswer((_) async => prefs(profile: true));
    when(() => onbDs.isOnboardingCompleted()).thenAnswer((_) async => true);
    await guard.status();
    await guard.status();
    verify(() => prefsRepo.read()).called(1);
  });

  test('resetCache → query ulang', () async {
    when(() => prefsRepo.read()).thenAnswer((_) async => prefs(profile: true));
    when(() => onbDs.isOnboardingCompleted()).thenAnswer((_) async => true);
    await guard.status();
    guard.resetCache();
    await guard.status();
    verify(() => prefsRepo.read()).called(2);
  });
}
