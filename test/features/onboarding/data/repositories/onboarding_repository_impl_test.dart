import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/network/network_info.dart';
import 'package:penyintas_app/features/onboarding/data/datasources/onboarding_local_datasource.dart';
import 'package:penyintas_app/features/onboarding/data/datasources/onboarding_remote_datasource.dart';
import 'package:penyintas_app/features/onboarding/data/models/budget_settings_model.dart';
import 'package:penyintas_app/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:penyintas_app/features/onboarding/domain/entities/budget_settings_entity.dart';

class MockLocalDataSource extends Mock implements OnboardingLocalDataSource {}

class MockRemoteDataSource extends Mock implements OnboardingRemoteDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class FakeBudgetSettingsEntity extends Fake implements BudgetSettingsEntity {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeBudgetSettingsEntity());
  });
  late OnboardingRepositoryImpl repository;
  late MockLocalDataSource local;
  late MockRemoteDataSource remote;
  late MockNetworkInfo networkInfo;
  late MockFirebaseAuth auth;
  late MockUser user;

  final tSettings = BudgetSettingsEntity(
    monthlyIncome: 5000000,
    paymentDate: 25,
    fixedExpenses: 1500000,
    emergencyFundPct: 0.10,
    createdAt: DateTime(2026, 5, 1),
  );

  final tModel = BudgetSettingsModel(
    monthlyIncome: 5000000,
    paymentDate: 25,
    fixedExpenses: 1500000,
    emergencyFundPct: 0.10,
    createdAt: DateTime(2026, 5, 1),
  );

  setUp(() {
    local = MockLocalDataSource();
    remote = MockRemoteDataSource();
    networkInfo = MockNetworkInfo();
    auth = MockFirebaseAuth();
    user = MockUser();

    repository = OnboardingRepositoryImpl(
      localDataSource: local,
      remoteDataSource: remote,
      networkInfo: networkInfo,
      auth: auth,
    );

    when(() => user.uid).thenReturn('uid-test');
    when(() => auth.currentUser).thenReturn(user);
  });

  group('saveBudgetSettings', () {
    setUp(() {
      when(() => local.saveBudgetSettings(any())).thenAnswer((_) async {});
      when(
        () => local.addToSyncQueue(
          itemId: any(named: 'itemId'),
          collectionPath: any(named: 'collectionPath'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async {});
    });

    test('offline — saves local and adds to sync queue, no remote call',
        () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.saveBudgetSettings(tSettings);

      expect(result, const Right<Failure, void>(null));
      verify(() => local.saveBudgetSettings(tSettings)).called(1);
      verify(
        () => local.addToSyncQueue(
          itemId: 'budget_settings_uid-test',
          collectionPath: 'users/uid-test/budget_settings/current',
          data: any(named: 'data'),
        ),
      ).called(1);
      verifyNever(() => remote.saveBudgetSettings(any()));
    });

    test('online + remote success — saves local and remote, no sync queue',
        () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => remote.saveBudgetSettings(any())).thenAnswer((_) async {});

      final result = await repository.saveBudgetSettings(tSettings);

      expect(result, const Right<Failure, void>(null));
      verify(() => local.saveBudgetSettings(tSettings)).called(1);
      verify(() => remote.saveBudgetSettings(tSettings)).called(1);
      verifyNever(
        () => local.addToSyncQueue(
          itemId: any(named: 'itemId'),
          collectionPath: any(named: 'collectionPath'),
          data: any(named: 'data'),
        ),
      );
    });

    test('online + remote failure — saves local and adds to sync queue',
        () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => remote.saveBudgetSettings(any()))
          .thenThrow(const ServerException());

      final result = await repository.saveBudgetSettings(tSettings);

      expect(result, const Right<Failure, void>(null));
      verify(() => local.saveBudgetSettings(tSettings)).called(1);
      verify(
        () => local.addToSyncQueue(
          itemId: 'budget_settings_uid-test',
          collectionPath: 'users/uid-test/budget_settings/current',
          data: any(named: 'data'),
        ),
      ).called(1);
    });

    test('local throws CacheException — returns CacheFailure', () async {
      when(() => local.saveBudgetSettings(any()))
          .thenThrow(const CacheException('disk full'));

      final result = await repository.saveBudgetSettings(tSettings);

      expect(result, const Left<Failure, void>(CacheFailure('disk full')));
    });
  });

  group('getBudgetSettings', () {
    test('local hit — returns local data without remote call', () async {
      when(() => local.getBudgetSettings()).thenAnswer((_) async => tSettings);

      final result = await repository.getBudgetSettings();

      expect(result, Right<Failure, BudgetSettingsEntity?>(tSettings));
      verifyNever(() => remote.getBudgetSettings());
    });

    test('local miss + online + remote has data — fetches remote and caches',
        () async {
      when(() => local.getBudgetSettings()).thenAnswer((_) async => null);
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => remote.getBudgetSettings()).thenAnswer((_) async => tModel);
      when(() => local.saveBudgetSettings(any())).thenAnswer((_) async {});

      final result = await repository.getBudgetSettings();

      expect(result, Right<Failure, BudgetSettingsEntity?>(tModel));
      verify(() => local.saveBudgetSettings(tModel)).called(1);
    });

    test('local miss + offline — returns Right(null)', () async {
      when(() => local.getBudgetSettings()).thenAnswer((_) async => null);
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.getBudgetSettings();

      expect(result, const Right<Failure, BudgetSettingsEntity?>(null));
    });

    test('local throws CacheException — returns CacheFailure', () async {
      when(() => local.getBudgetSettings())
          .thenThrow(const CacheException('corrupt'));

      final result = await repository.getBudgetSettings();

      expect(result, const Left<Failure, BudgetSettingsEntity?>(CacheFailure('corrupt')));
    });
  });
}
