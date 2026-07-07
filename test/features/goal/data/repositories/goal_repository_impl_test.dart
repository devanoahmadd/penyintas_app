import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/network/network_info.dart';
import 'package:penyintas_app/features/goal/data/datasources/goal_local_datasource.dart';
import 'package:penyintas_app/features/goal/data/datasources/goal_remote_datasource.dart';
import 'package:penyintas_app/features/goal/data/models/goal_model.dart';
import 'package:penyintas_app/features/goal/data/repositories/goal_repository_impl.dart';

class MockGoalLocalDatasource extends Mock implements GoalLocalDatasource {}

class MockGoalRemoteDatasource extends Mock implements GoalRemoteDatasource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class FakeGoalModel extends Fake implements GoalModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeGoalModel());
    registerFallbackValue(SyncOperation.create);
  });

  late GoalRepositoryImpl repo;
  late MockGoalLocalDatasource local;
  late MockGoalRemoteDatasource remote;
  late MockNetworkInfo network;
  late MockFirebaseAuth auth;
  late MockUser user;

  const tUid = 'u1';
  final tModel = GoalModel(
    firestoreId: 'fid-1',
    title: 'Pulang kampung',
    targetAmount: 1500000,
    targetDate: DateTime(2026, 12, 31),
    isCompleted: false,
    createdAt: DateTime(2026, 7, 5),
    updatedAt: DateTime(2026, 7, 5),
  );
  const tPath = 'users/u1/goals/fid-1';

  setUp(() {
    local = MockGoalLocalDatasource();
    remote = MockGoalRemoteDatasource();
    network = MockNetworkInfo();
    auth = MockFirebaseAuth();
    user = MockUser();
    when(() => user.uid).thenReturn(tUid);
    when(() => auth.currentUser).thenReturn(user);
    repo = GoalRepositoryImpl(
      local: local,
      remote: remote,
      networkInfo: network,
      auth: auth,
    );
  });

  Future<Either<Failure, void>> callCreate() => repo.createGoal(
        title: 'Pulang kampung',
        targetAmount: 1500000,
        targetDate: DateTime(2026, 12, 31),
      );

  group('createGoal (local-first)', () {
    setUp(() {
      when(() => local.createGoal(
            title: any(named: 'title'),
            targetAmount: any(named: 'targetAmount'),
            targetDate: any(named: 'targetDate'),
          )).thenAnswer((_) async => tModel);
    });

    test('online → lokal dulu, lalu push remote; tanpa queue', () async {
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(() => remote.saveGoal(any())).thenAnswer((_) async {});

      final result = await callCreate();

      expect(result.isRight(), isTrue);
      verify(() => local.createGoal(
            title: 'Pulang kampung',
            targetAmount: 1500000,
            targetDate: DateTime(2026, 12, 31),
          )).called(1);
      verify(() => remote.saveGoal(tModel)).called(1);
      verifyNever(() => local.addToSyncQueue(
            itemId: any(named: 'itemId'),
            collectionPath: any(named: 'collectionPath'),
            data: any(named: 'data'),
            operation: any(named: 'operation'),
          ));
    });

    test('offline → enqueue create dengan path doc penuh (pola transaction)',
        () async {
      when(() => network.isConnected).thenAnswer((_) async => false);
      when(() => local.addToSyncQueue(
            itemId: any(named: 'itemId'),
            collectionPath: any(named: 'collectionPath'),
            data: any(named: 'data'),
            operation: any(named: 'operation'),
          )).thenAnswer((_) async {});

      final result = await callCreate();

      expect(result.isRight(), isTrue);
      verifyNever(() => remote.saveGoal(any()));
      verify(() => local.addToSyncQueue(
            itemId: 'fid-1',
            collectionPath: tPath,
            data: tModel.toFirestore(),
            operation: SyncOperation.create,
          )).called(1);
    });

    test('online tapi remote gagal → fallback queue, tetap Right', () async {
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(() => remote.saveGoal(any()))
          .thenThrow(const ServerException('boom'));
      when(() => local.addToSyncQueue(
            itemId: any(named: 'itemId'),
            collectionPath: any(named: 'collectionPath'),
            data: any(named: 'data'),
            operation: any(named: 'operation'),
          )).thenAnswer((_) async {});

      final result = await callCreate();

      expect(result.isRight(), isTrue,
          reason: 'local-first: kegagalan remote tak menggagalkan operasi');
      verify(() => local.addToSyncQueue(
            itemId: 'fid-1',
            collectionPath: tPath,
            data: tModel.toFirestore(),
            operation: SyncOperation.create,
          )).called(1);
    });

    test('belum login (uid null) → simpan lokal saja, tanpa remote/queue',
        () async {
      when(() => auth.currentUser).thenReturn(null);

      final result = await callCreate();

      expect(result.isRight(), isTrue);
      verifyNever(() => remote.saveGoal(any()));
      verifyNever(() => local.addToSyncQueue(
            itemId: any(named: 'itemId'),
            collectionPath: any(named: 'collectionPath'),
            data: any(named: 'data'),
            operation: any(named: 'operation'),
          ));
    });

    test('lokal gagal → Left(CacheFailure), tanpa remote', () async {
      when(() => local.createGoal(
            title: any(named: 'title'),
            targetAmount: any(named: 'targetAmount'),
            targetDate: any(named: 'targetDate'),
          )).thenThrow(Exception('disk penuh'));

      final result = await callCreate();

      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<CacheFailure>()), (_) {});
      verifyNever(() => remote.saveGoal(any()));
    });
  });

  group('completeGoal (local-first)', () {
    final tCompleted = GoalModel(
      firestoreId: 'fid-1',
      title: 'Pulang kampung',
      targetAmount: 1500000,
      targetDate: DateTime(2026, 12, 31),
      isCompleted: true,
      createdAt: DateTime(2026, 7, 5),
      updatedAt: DateTime(2026, 7, 6),
    );

    test('online → update lokal dulu, lalu push snapshot terbaru', () async {
      when(() => local.completeGoal(3)).thenAnswer((_) async {});
      when(() => local.findById(3)).thenAnswer((_) async => tCompleted);
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(() => remote.saveGoal(any())).thenAnswer((_) async {});

      final result = await repo.completeGoal(3);

      expect(result.isRight(), isTrue);
      verifyInOrder([
        () => local.completeGoal(3),
        () => local.findById(3),
        () => remote.saveGoal(tCompleted),
      ]);
    });

    test('offline → enqueue update', () async {
      when(() => local.completeGoal(3)).thenAnswer((_) async {});
      when(() => local.findById(3)).thenAnswer((_) async => tCompleted);
      when(() => network.isConnected).thenAnswer((_) async => false);
      when(() => local.addToSyncQueue(
            itemId: any(named: 'itemId'),
            collectionPath: any(named: 'collectionPath'),
            data: any(named: 'data'),
            operation: any(named: 'operation'),
          )).thenAnswer((_) async {});

      final result = await repo.completeGoal(3);

      expect(result.isRight(), isTrue);
      verify(() => local.addToSyncQueue(
            itemId: 'fid-1',
            collectionPath: tPath,
            data: tCompleted.toFirestore(),
            operation: SyncOperation.update,
          )).called(1);
    });
  });

  group('deleteGoal (local-first)', () {
    test('firestoreId diambil SEBELUM delete lokal; online → remote delete',
        () async {
      when(() => local.firestoreIdOf(3)).thenAnswer((_) async => 'fid-1');
      when(() => local.deleteGoal(3)).thenAnswer((_) async {});
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(() => remote.deleteGoal('fid-1')).thenAnswer((_) async {});

      final result = await repo.deleteGoal(3);

      expect(result.isRight(), isTrue);
      verifyInOrder([
        () => local.firestoreIdOf(3),
        () => local.deleteGoal(3),
        () => remote.deleteGoal('fid-1'),
      ]);
    });

    test('offline → enqueue delete dengan data kosong', () async {
      when(() => local.firestoreIdOf(3)).thenAnswer((_) async => 'fid-1');
      when(() => local.deleteGoal(3)).thenAnswer((_) async {});
      when(() => network.isConnected).thenAnswer((_) async => false);
      when(() => local.addToSyncQueue(
            itemId: any(named: 'itemId'),
            collectionPath: any(named: 'collectionPath'),
            data: any(named: 'data'),
            operation: any(named: 'operation'),
          )).thenAnswer((_) async {});

      final result = await repo.deleteGoal(3);

      expect(result.isRight(), isTrue);
      verifyNever(() => remote.deleteGoal(any()));
      verify(() => local.addToSyncQueue(
            itemId: 'fid-1',
            collectionPath: tPath,
            data: const <String, dynamic>{},
            operation: SyncOperation.delete,
          )).called(1);
    });
  });

  group('syncGoalsFromRemote (pull-all-on-first-sync, KD-2)', () {
    test('lokal sudah berisi → Right(0), remote TIDAK disentuh', () async {
      when(() => local.hasAnyGoals()).thenAnswer((_) async => true);

      final result = await repo.syncGoalsFromRemote();

      expect(result, const Right<Failure, int>(0));
      verifyNever(() => remote.getGoals());
    });

    test('lokal kosong + offline → Right(0), remote TIDAK disentuh', () async {
      when(() => local.hasAnyGoals()).thenAnswer((_) async => false);
      when(() => network.isConnected).thenAnswer((_) async => false);

      final result = await repo.syncGoalsFromRemote();

      expect(result, const Right<Failure, int>(0));
      verifyNever(() => remote.getGoals());
    });

    test('lokal kosong + online → pull semua, upsert, Right(n)', () async {
      when(() => local.hasAnyGoals()).thenAnswer((_) async => false);
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(() => remote.getGoals()).thenAnswer((_) async => [tModel]);
      when(() => local.upsertFromRemote(any())).thenAnswer((_) async {});

      final result = await repo.syncGoalsFromRemote();

      expect(result, const Right<Failure, int>(1));
      verify(() => local.upsertFromRemote([tModel])).called(1);
    });

    test('remote kosong → Right(0) tanpa upsert', () async {
      when(() => local.hasAnyGoals()).thenAnswer((_) async => false);
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(() => remote.getGoals()).thenAnswer((_) async => const []);

      final result = await repo.syncGoalsFromRemote();

      expect(result, const Right<Failure, int>(0));
      verifyNever(() => local.upsertFromRemote(any()));
    });

    test('remote melempar ServerException → Left(ServerFailure)', () async {
      when(() => local.hasAnyGoals()).thenAnswer((_) async => false);
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(() => remote.getGoals()).thenThrow(const ServerException('boom'));

      final result = await repo.syncGoalsFromRemote();

      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<ServerFailure>()), (_) {});
    });
  });
}
