import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/network/network_info.dart';
import 'package:penyintas_app/features/transaction/data/datasources/transaction_local_datasource.dart';
import 'package:penyintas_app/features/transaction/data/datasources/transaction_remote_datasource.dart';
import 'package:penyintas_app/features/transaction/data/models/transaction_model.dart';
import 'package:penyintas_app/features/transaction/data/repositories/transaction_repository_impl.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';

class MockLocalDataSource extends Mock implements TransactionLocalDataSource {}

class MockRemoteDataSource extends Mock
    implements TransactionRemoteDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseUser extends Mock implements User {}

class FakeTransactionModel extends Fake implements TransactionModel {}

void main() {
  late TransactionRepositoryImpl repository;
  late MockLocalDataSource mockLocal;
  late MockRemoteDataSource mockRemote;
  late MockNetworkInfo mockNetwork;
  late MockFirebaseAuth mockAuth;
  late MockFirebaseUser mockUser;

  final tEntity = TransactionEntity(
    id: 'tx-1',
    amount: 50000,
    category: 'food',
    type: TransactionType.expense,
    date: DateTime(2026, 5, 8),
    isFixed: false,
    isSynced: false,
    createdAt: DateTime(2026, 5, 8),
    updatedAt: DateTime(2026, 5, 8),
  );

  setUpAll(() {
    registerFallbackValue(FakeTransactionModel());
    registerFallbackValue(SyncOperation.create);
  });

  setUp(() {
    mockLocal = MockLocalDataSource();
    mockRemote = MockRemoteDataSource();
    mockNetwork = MockNetworkInfo();
    mockAuth = MockFirebaseAuth();
    mockUser = MockFirebaseUser();

    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('uid-123');

    repository = TransactionRepositoryImpl(
      localDataSource: mockLocal,
      remoteDataSource: mockRemote,
      networkInfo: mockNetwork,
      auth: mockAuth,
    );
  });

  group('addTransaction', () {
    setUp(() {
      when(() => mockLocal.saveTransaction(any())).thenAnswer((_) async {});
      when(() => mockLocal.markSynced(any())).thenAnswer((_) async {});
      when(
        () => mockLocal.addToSyncQueue(
          itemId: any(named: 'itemId'),
          collectionPath: any(named: 'collectionPath'),
          data: any(named: 'data'),
          operation: any(named: 'operation'),
        ),
      ).thenAnswer((_) async {});
    });

    test(
      'online + Firestore succeeds → saves Isar, saves Firestore, marks synced',
      () async {
        when(() => mockNetwork.isConnected).thenAnswer((_) async => true);
        when(() => mockRemote.saveTransaction(any())).thenAnswer((_) async {});

        final result = await repository.addTransaction(tEntity);

        expect(result, const Right(null));
        verify(() => mockLocal.saveTransaction(any())).called(1);
        verify(() => mockRemote.saveTransaction(any())).called(1);
        verify(() => mockLocal.markSynced('tx-1')).called(1);
        verifyNever(
          () => mockLocal.addToSyncQueue(
            itemId: any(named: 'itemId'),
            collectionPath: any(named: 'collectionPath'),
            data: any(named: 'data'),
            operation: any(named: 'operation'),
          ),
        );
      },
    );

    test('online + Firestore fails → saves Isar, adds to sync queue', () async {
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);
      when(() => mockRemote.saveTransaction(any())).thenThrow(Exception('err'));

      final result = await repository.addTransaction(tEntity);

      expect(result, const Right(null));
      verify(() => mockLocal.saveTransaction(any())).called(1);
      verify(
        () => mockLocal.addToSyncQueue(
          itemId: any(named: 'itemId'),
          collectionPath: any(named: 'collectionPath'),
          data: any(named: 'data'),
          operation: SyncOperation.create,
        ),
      ).called(1);
      verifyNever(() => mockLocal.markSynced(any()));
    });

    test('offline → saves Isar, adds to sync queue, skips Firestore', () async {
      when(() => mockNetwork.isConnected).thenAnswer((_) async => false);

      final result = await repository.addTransaction(tEntity);

      expect(result, const Right(null));
      verify(() => mockLocal.saveTransaction(any())).called(1);
      verify(
        () => mockLocal.addToSyncQueue(
          itemId: any(named: 'itemId'),
          collectionPath: any(named: 'collectionPath'),
          data: any(named: 'data'),
          operation: SyncOperation.create,
        ),
      ).called(1);
      verifyNever(() => mockRemote.saveTransaction(any()));
    });
  });

  group('deleteTransaction', () {
    setUp(() {
      when(() => mockLocal.deleteTransaction(any())).thenAnswer((_) async {});
      when(
        () => mockLocal.addToSyncQueue(
          itemId: any(named: 'itemId'),
          collectionPath: any(named: 'collectionPath'),
          data: any(named: 'data'),
          operation: any(named: 'operation'),
        ),
      ).thenAnswer((_) async {});
    });

    test('online → deletes from Isar and Firestore', () async {
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);
      when(() => mockRemote.deleteTransaction(any())).thenAnswer((_) async {});

      final result = await repository.deleteTransaction('tx-1');

      expect(result, const Right(null));
      verify(() => mockLocal.deleteTransaction('tx-1')).called(1);
      verify(() => mockRemote.deleteTransaction('tx-1')).called(1);
    });

    test('offline → deletes from Isar, adds delete op to sync queue', () async {
      when(() => mockNetwork.isConnected).thenAnswer((_) async => false);

      final result = await repository.deleteTransaction('tx-1');

      expect(result, const Right(null));
      verify(() => mockLocal.deleteTransaction('tx-1')).called(1);
      verify(
        () => mockLocal.addToSyncQueue(
          itemId: any(named: 'itemId'),
          collectionPath: any(named: 'collectionPath'),
          data: any(named: 'data'),
          operation: SyncOperation.delete,
        ),
      ).called(1);
      verifyNever(() => mockRemote.deleteTransaction(any()));
    });
  });
}
