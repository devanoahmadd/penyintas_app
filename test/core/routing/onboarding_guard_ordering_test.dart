// test/core/routing/onboarding_guard_ordering_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/routing/onboarding_guard.dart';
import 'package:penyintas_app/core/routing/onboarding_status.dart';
import 'package:penyintas_app/features/onboarding/data/datasources/onboarding_local_datasource.dart';
import 'package:penyintas_app/features/preferences/data/datasources/preferences_local_datasource.dart';
import 'package:penyintas_app/features/preferences/data/datasources/preferences_remote_datasource.dart';
import 'package:penyintas_app/features/preferences/data/models/preferences_model.dart';
import 'package:penyintas_app/features/preferences/data/repositories/preferences_repository_impl.dart';
import 'package:penyintas_app/features/preferences/domain/entities/preferences_entity.dart';

class _MockOnbDs extends Mock implements OnboardingLocalDataSource {}

class _MockRemote extends Mock implements PreferencesRemoteDatasource {}

void main() {
  late AppDatabase
  db; // Drift fresh = simulasi reinstall (profileCompleted=false)
  late PreferencesLocalDatasourceImpl local;
  late _MockRemote remote;
  late _MockOnbDs onbDs;

  setUpAll(() {
    registerFallbackValue(PreferencesEntity.defaults);
  });
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    local = PreferencesLocalDatasourceImpl(db);
    remote = _MockRemote();
    onbDs = _MockOnbDs();
  });
  tearDown(() => db.close());

  test(
    'A2: reinstall + remote profileCompleted=true → bootstrap dulu → guard TIDAK needsProfile',
    () async {
      when(() => remote.fetch()).thenAnswer(
        (_) async => PreferencesModel.fromEntity(
          PreferencesEntity.defaults.copyWith(
            timezone: 'Europe/Moscow',
            profileCompleted: true,
          ),
        ),
      );
      when(() => remote.mirror(any())).thenAnswer((_) async {});
      when(() => onbDs.isOnboardingCompleted()).thenAnswer((_) async => true);

      final repo = PreferencesRepositoryImpl(local: local, remote: remote);
      final guard = OnboardingGuard(onboardingDs: onbDs, prefsRepo: repo);

      // Urutan splash: bootstrap SELESAI dulu, baru guard memutuskan.
      await repo.syncOnLaunch(budgetOnboardingCompleted: false);
      guard.resetCache();
      final status = await guard.status();

      expect(
        status,
        isNot(OnboardingStatus.needsProfile),
        reason:
            'profil dipulihkan dari cloud, jangan ulang (kelas bug d4de2f2)',
      );
      expect(status, OnboardingStatus.done); // profil ok + budget ok
    },
  );

  test(
    'A2: bootstrap timeout → local tetap default → guard fail-safe needsProfile',
    () async {
      when(() => remote.fetch()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(seconds: 1));
        return null;
      });
      when(() => remote.mirror(any())).thenAnswer((_) async {});
      when(() => onbDs.isOnboardingCompleted()).thenAnswer((_) async => true);

      final repo = PreferencesRepositoryImpl(
        local: local,
        remote: remote,
        syncTimeout: const Duration(milliseconds: 10),
      );
      final guard = OnboardingGuard(onboardingDs: onbDs, prefsRepo: repo);

      await repo.syncOnLaunch(budgetOnboardingCompleted: false);
      guard.resetCache();
      expect(await guard.status(), OnboardingStatus.needsProfile);
    },
  );
}
