import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/network/network_info.dart';
import 'package:penyintas_app/features/budget/data/datasources/budget_local_datasource.dart';
import 'package:penyintas_app/features/budget/data/datasources/budget_remote_datasource.dart';
import 'package:penyintas_app/features/budget/data/models/budget_settings_model.dart';
import 'package:penyintas_app/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_cycle.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_limit_entity.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';

class MockBudgetLocalDatasource extends Mock implements BudgetLocalDatasource {}

class MockBudgetRemoteDatasource extends Mock implements BudgetRemoteDatasource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class FakeBudgetSettingsEntity extends Fake implements BudgetSettingsEntity {}

class FakeBudgetLimitEntity extends Fake implements BudgetLimitEntity {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeBudgetSettingsEntity());
    registerFallbackValue(FakeBudgetLimitEntity());
    // Diperlukan karena stubQueueOk() memakai any(named: 'operation') —
    // pola sama seperti transaction_repository_impl_test.dart.
    registerFallbackValue(SyncOperation.create);
  });

  late BudgetRepositoryImpl repository;
  late MockBudgetLocalDatasource local;
  late MockBudgetRemoteDatasource remote;
  late MockNetworkInfo network;
  late MockFirebaseAuth auth;
  late MockUser user;

  final tEntity = BudgetSettingsEntity(
    monthlyIncome: 3000000,
    paymentDate: 25,
    otherFixedExpense: 800000,
    emergencyFundPct: 0.10,
    createdAt: DateTime(2026, 5, 8),
  );
  final tModel = BudgetSettingsModel(
    monthlyIncome: 3000000,
    paymentDate: 25,
    otherFixedExpense: 800000,
    emergencyFundPct: 0.10,
    createdAt: DateTime(2026, 5, 8),
  );

  setUp(() {
    local = MockBudgetLocalDatasource();
    remote = MockBudgetRemoteDatasource();
    network = MockNetworkInfo();
    auth = MockFirebaseAuth();
    user = MockUser();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('uid-1');
    repository = BudgetRepositoryImpl(
      local: local,
      remote: remote,
      networkInfo: network,
      auth: auth,
    );
  });

  group('syncBudgetFromRemote', () {
    test('local hit — returns local, tidak panggil remote', () async {
      when(() => local.getBudgetSettings()).thenAnswer((_) async => tEntity);

      final result = await repository.syncBudgetFromRemote();

      expect(result, Right<dynamic, BudgetSettingsEntity?>(tEntity));
      verifyNever(() => remote.getBudgetSettings());
    });

    test('local miss + online + remote ada — cache lokal lalu return remote',
        () async {
      when(() => local.getBudgetSettings()).thenAnswer((_) async => null);
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(() => remote.getBudgetSettings()).thenAnswer((_) async => tModel);
      when(() => local.saveBudgetSettings(any())).thenAnswer((_) async {});

      final result = await repository.syncBudgetFromRemote();

      expect(result, Right<dynamic, BudgetSettingsEntity?>(tModel));
      verify(() => local.saveBudgetSettings(tModel)).called(1);
    });

    test('local miss + offline — return Right(null), tak sentuh remote',
        () async {
      when(() => local.getBudgetSettings()).thenAnswer((_) async => null);
      when(() => network.isConnected).thenAnswer((_) async => false);

      final result = await repository.syncBudgetFromRemote();

      expect(result, const Right<dynamic, BudgetSettingsEntity?>(null));
      verifyNever(() => remote.getBudgetSettings());
    });
  });

  group('sync queue path #252', () {
    void stubQueueOk() => when(() => local.addToSyncQueue(
          itemId: any(named: 'itemId'),
          collectionPath: any(named: 'collectionPath'),
          data: any(named: 'data'),
          operation: any(named: 'operation'),
        )).thenAnswer((_) async {});

    test('saveBudgetSettings offline → path doc penuh, tanpa docId di data',
        () async {
      when(() => network.isConnected).thenAnswer((_) async => false);
      when(() => local.saveBudgetSettings(any())).thenAnswer((_) async {});
      stubQueueOk();

      await repository.saveBudgetSettings(tEntity);

      final captured = verify(() => local.addToSyncQueue(
            itemId: 'budget_settings_current',
            collectionPath: captureAny(named: 'collectionPath'),
            data: captureAny(named: 'data'),
            operation: SyncOperation.update,
          )).captured;
      expect(captured[0], 'users/uid-1/budget_settings/current');
      expect((captured[1] as Map<String, dynamic>).containsKey('docId'), isFalse);
    });

    test('saveBudgetLimit offline → path doc penuh per kategori', () async {
      final tLimit = BudgetLimitEntity(
        id: 1,
        category: 'makan',
        limitAmount: 500000,
        cycleType: BudgetCycle.monthly,
        isEnabled: true,
        updatedAt: DateTime(2026, 7, 1),
      );
      when(() => network.isConnected).thenAnswer((_) async => false);
      when(() => local.saveBudgetLimit(any())).thenAnswer((_) async => 1);
      stubQueueOk();

      await repository.saveBudgetLimit(tLimit);

      final captured = verify(() => local.addToSyncQueue(
            itemId: 'budget_limit_makan',
            collectionPath: captureAny(named: 'collectionPath'),
            data: captureAny(named: 'data'),
            operation: SyncOperation.update,
          )).captured;
      expect(captured[0], 'users/uid-1/budget_limits/makan');
      expect((captured[1] as Map<String, dynamic>).containsKey('docId'), isFalse);
    });

    test('deleteBudgetLimit offline → path doc penuh, operation delete',
        () async {
      when(() => network.isConnected).thenAnswer((_) async => false);
      when(() => local.deleteBudgetLimit(any())).thenAnswer((_) async {});
      stubQueueOk();

      await repository.deleteBudgetLimit(1, 'makan');

      verify(() => local.addToSyncQueue(
            itemId: 'budget_limit_makan',
            collectionPath: 'users/uid-1/budget_limits/makan',
            data: any(named: 'data'),
            operation: SyncOperation.delete,
          )).called(1);
    });

    test('offline + belum login → tidak enqueue, tetap Right', () async {
      when(() => auth.currentUser).thenReturn(null);
      when(() => network.isConnected).thenAnswer((_) async => false);
      when(() => local.saveBudgetSettings(any())).thenAnswer((_) async {});

      final result = await repository.saveBudgetSettings(tEntity);

      expect(result.isRight(), isTrue);
      verifyNever(() => local.addToSyncQueue(
            itemId: any(named: 'itemId'),
            collectionPath: any(named: 'collectionPath'),
            data: any(named: 'data'),
            operation: any(named: 'operation'),
          ));
    });
  });
}
