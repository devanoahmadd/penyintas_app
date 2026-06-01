import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/auth/data/datasources/user_settings_remote_datasource.dart';
import 'package:penyintas_app/features/auth/data/models/user_settings_model.dart';
import 'package:penyintas_app/features/auth/data/repositories/user_settings_repository_impl.dart';

class MockRemote extends Mock implements UserSettingsRemoteDatasource {}

class FakeUserSettingsModel extends Fake implements UserSettingsModel {}

AppDatabase _openTestDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late MockRemote remote;
  late UserSettingsRepositoryImpl repo;

  setUpAll(() => registerFallbackValue(FakeUserSettingsModel()));

  setUp(() {
    db = _openTestDb();
    remote = MockRemote();
    repo = UserSettingsRepositoryImpl(
      db: db,
      remote: remote,
      syncTimeout: const Duration(milliseconds: 200),
    );
  });

  tearDown(() => db.close());

  Future<void> seedLocal({required bool completed, int rent = 0}) async {
    await db.into(db.appSettings).insertOnConflictUpdate(AppSettingsCompanion(
          id: const Value(1),
          onboardingCompleted: Value(completed),
          rentExpense: Value(rent),
        ));
  }

  group('wipeLocalData', () {
    test('mengosongkan tabel dan return Right(unit)', () async {
      await seedLocal(completed: true, rent: 500000);

      final result = await repo.wipeLocalData();

      expect(result, const Right(unit));
      expect(await db.select(db.appSettings).get(), isEmpty);
    });
  });

  group('syncFromRemote', () {
    test('remote ada → tulis ke lokal, return Right(unit)', () async {
      when(() => remote.fetchUserSettings()).thenAnswer((_) async =>
          const UserSettingsModel(
            onboardingCompleted: true,
            rentExpense: 800000,
            utilitiesExpense: 0,
            internetExpense: 0,
            phoneExpense: 0,
            otherFixedExpense: 0,
          ));

      final result = await repo.syncFromRemote();

      expect(result, const Right(unit));
      final row = await (db.select(db.appSettings)
            ..where((t) => t.id.equals(1)))
          .getSingleOrNull();
      expect(row!.onboardingCompleted, true);
      expect(row.rentExpense, 800000);
      verifyNever(() => remote.saveUserSettings(any()));
    });

    test('remote null + lokal completed → push lokal (self-heal)', () async {
      await seedLocal(completed: true, rent: 300000);
      when(() => remote.fetchUserSettings()).thenAnswer((_) async => null);
      when(() => remote.saveUserSettings(any())).thenAnswer((_) async {});

      final result = await repo.syncFromRemote();

      expect(result, const Right(unit));
      final captured = verify(() => remote.saveUserSettings(captureAny()))
          .captured
          .single as UserSettingsModel;
      expect(captured.onboardingCompleted, true);
      expect(captured.rentExpense, 300000);
    });

    test('remote null + lokal belum completed → no-op', () async {
      await seedLocal(completed: false);
      when(() => remote.fetchUserSettings()).thenAnswer((_) async => null);

      final result = await repo.syncFromRemote();

      expect(result, const Right(unit));
      verifyNever(() => remote.saveUserSettings(any()));
    });

    test('remote timeout → Right(unit) (non-blocking)', () async {
      when(() => remote.fetchUserSettings()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(seconds: 2));
        return null;
      });

      final result = await repo.syncFromRemote();

      expect(result, const Right(unit));
    });

    test('remote throw → Right(unit) (non-blocking)', () async {
      when(() => remote.fetchUserSettings()).thenThrow(Exception('boom'));

      final result = await repo.syncFromRemote();

      expect(result, const Right(unit));
    });
  });

  group('pushToRemote', () {
    test('baca lokal lalu push ke remote, return Right(unit)', () async {
      await seedLocal(completed: true, rent: 750000);
      when(() => remote.saveUserSettings(any())).thenAnswer((_) async {});

      final result = await repo.pushToRemote();

      expect(result, const Right(unit));
      final captured = verify(() => remote.saveUserSettings(captureAny()))
          .captured
          .single as UserSettingsModel;
      expect(captured.onboardingCompleted, true);
      expect(captured.rentExpense, 750000);
    });
  });
}
