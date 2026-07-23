import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/network/network_info.dart';
import 'package:penyintas_app/features/bills/data/datasources/bill_local_datasource.dart';
import 'package:penyintas_app/features/bills/data/datasources/bill_remote_datasource.dart';
import 'package:penyintas_app/features/bills/data/models/bill_model.dart';
import 'package:penyintas_app/features/bills/data/repositories/bill_repository_impl.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';

class MockBillLocalDatasource extends Mock implements BillLocalDatasource {}

class MockBillRemoteDatasource extends Mock implements BillRemoteDatasource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class FakeBillModel extends Fake implements BillModel {}

/// Builder model bill untuk fixture test (mirror
/// test/features/bills/data/bill_local_datasource_test.dart) — semua field
/// wajib entity diisi nilai default masuk akal, override lewat parameter.
BillModel _billModel({
  String? cloudId,
  String name = 'Kos Bu Tini',
  int estimatedAmount = 750000,
  String category = 'kos',
  bool isFixedNeed = true,
  String? notes,
  DateTime? dueDate,
  Recurrence recurrence = Recurrence.monthly,
  int? installmentTotal,
  int installmentsPaid = 0,
  DateTime? recurrenceEndDate,
  int? dueDayOfMonth,
  int? reminderDaysBefore,
  bool reminderEnabled = true,
  BillStatus status = BillStatus.active,
  DateTime? createdAt,
  DateTime? updatedAt,
}) => BillModel(
  cloudId: cloudId,
  name: name,
  estimatedAmount: estimatedAmount,
  category: category,
  isFixedNeed: isFixedNeed,
  notes: notes,
  dueDate: dueDate ?? DateTime(2026, 8, 5),
  recurrence: recurrence,
  installmentTotal: installmentTotal,
  installmentsPaid: installmentsPaid,
  recurrenceEndDate: recurrenceEndDate,
  dueDayOfMonth: dueDayOfMonth,
  reminderDaysBefore: reminderDaysBefore,
  reminderEnabled: reminderEnabled,
  status: status,
  createdAt: createdAt ?? DateTime(2026, 7, 1),
  updatedAt: updatedAt ?? DateTime(2026, 7, 1),
);

void main() {
  setUpAll(() {
    registerFallbackValue(FakeBillModel());
    registerFallbackValue(SyncOperation.create);
  });

  late BillRepositoryImpl repo;
  late MockBillLocalDatasource local;
  late MockBillRemoteDatasource remote;
  late MockNetworkInfo network;
  late MockFirebaseAuth auth;
  late MockUser user;

  const tUid = 'uid123';
  final tModel = _billModel(cloudId: 'c1');
  const tPath = 'users/uid123/bills/c1';

  setUp(() {
    local = MockBillLocalDatasource();
    remote = MockBillRemoteDatasource();
    network = MockNetworkInfo();
    auth = MockFirebaseAuth();
    user = MockUser();
    when(() => user.uid).thenReturn(tUid);
    when(() => auth.currentUser).thenReturn(user);
    repo = BillRepositoryImpl(
      local: local,
      remote: remote,
      networkInfo: network,
      auth: auth,
    );
  });

  group('createBill (local-first, re-fetch cloudId)', () {
    setUp(() {
      when(() => local.createBill(any())).thenAnswer((_) async => 5);
      when(() => local.findById(5)).thenAnswer((_) async => tModel);
    });

    test('(a) online sukses → remote.saveBill dipanggil', () async {
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(() => remote.saveBill(any())).thenAnswer((_) async {});

      final result = await repo.createBill(_billModel());

      expect(result, const Right<Failure, int>(5));
      verify(() => local.createBill(any())).called(1);
      verify(() => local.findById(5)).called(1);
      verify(() => remote.saveBill(tModel)).called(1);
      verifyNever(
        () => local.addToSyncQueue(
          itemId: any(named: 'itemId'),
          collectionPath: any(named: 'collectionPath'),
          data: any(named: 'data'),
          operation: any(named: 'operation'),
        ),
      );
    });

    test(
      '(b) offline → enqueue dengan collectionPath PENUH (bukan {uid})',
      () async {
        when(() => network.isConnected).thenAnswer((_) async => false);
        when(
          () => local.addToSyncQueue(
            itemId: any(named: 'itemId'),
            collectionPath: any(named: 'collectionPath'),
            data: any(named: 'data'),
            operation: any(named: 'operation'),
          ),
        ).thenAnswer((_) async {});

        final result = await repo.createBill(_billModel());

        expect(result, const Right<Failure, int>(5));
        verifyNever(() => remote.saveBill(any()));
        verify(
          () => local.addToSyncQueue(
            itemId: 'c1',
            collectionPath: tPath,
            data: tModel.toFirestore(),
            operation: SyncOperation.create,
          ),
        ).called(1);
      },
    );

    test('(c) belum login (uid null) → tak enqueue, tak push', () async {
      when(() => auth.currentUser).thenReturn(null);
      when(() => network.isConnected).thenAnswer((_) async => true);

      final result = await repo.createBill(_billModel());

      expect(result, const Right<Failure, int>(5));
      verifyNever(() => remote.saveBill(any()));
      verifyNever(
        () => local.addToSyncQueue(
          itemId: any(named: 'itemId'),
          collectionPath: any(named: 'collectionPath'),
          data: any(named: 'data'),
          operation: any(named: 'operation'),
        ),
      );
    });

    test('online tapi remote gagal → fallback queue, tetap Right', () async {
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(
        () => remote.saveBill(any()),
      ).thenThrow(const ServerException('boom'));
      when(
        () => local.addToSyncQueue(
          itemId: any(named: 'itemId'),
          collectionPath: any(named: 'collectionPath'),
          data: any(named: 'data'),
          operation: any(named: 'operation'),
        ),
      ).thenAnswer((_) async {});

      final result = await repo.createBill(_billModel());

      expect(
        result,
        const Right<Failure, int>(5),
        reason: 'local-first: kegagalan remote tak menggagalkan operasi',
      );
      verify(
        () => local.addToSyncQueue(
          itemId: 'c1',
          collectionPath: tPath,
          data: tModel.toFirestore(),
          operation: SyncOperation.create,
        ),
      ).called(1);
    });

    test('lokal gagal → Left(CacheFailure), tanpa remote', () async {
      when(() => local.createBill(any())).thenThrow(Exception('disk penuh'));

      final result = await repo.createBill(_billModel());

      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<CacheFailure>()), (_) {});
      verifyNever(() => remote.saveBill(any()));
    });
  });

  group('updateBill (local-first, model sudah bawa cloudId)', () {
    test('online → update lokal dulu, lalu push', () async {
      when(() => local.updateBill(tModel)).thenAnswer((_) async {});
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(() => remote.saveBill(any())).thenAnswer((_) async {});

      final result = await repo.updateBill(tModel);

      expect(result, const Right<Failure, void>(null));
      verifyInOrder([
        () => local.updateBill(tModel),
        () => remote.saveBill(tModel),
      ]);
    });

    test('offline → enqueue update', () async {
      when(() => local.updateBill(tModel)).thenAnswer((_) async {});
      when(() => network.isConnected).thenAnswer((_) async => false);
      when(
        () => local.addToSyncQueue(
          itemId: any(named: 'itemId'),
          collectionPath: any(named: 'collectionPath'),
          data: any(named: 'data'),
          operation: any(named: 'operation'),
        ),
      ).thenAnswer((_) async {});

      final result = await repo.updateBill(tModel);

      expect(result, const Right<Failure, void>(null));
      verify(
        () => local.addToSyncQueue(
          itemId: 'c1',
          collectionPath: tPath,
          data: tModel.toFirestore(),
          operation: SyncOperation.update,
        ),
      ).called(1);
    });
  });

  group('deleteBill (fetch cloudId SEBELUM delete lokal)', () {
    test('online → cloudId diambil dulu, lalu remote delete', () async {
      when(() => local.findById(3)).thenAnswer((_) async => tModel);
      when(() => local.deleteBill(3)).thenAnswer((_) async {});
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(() => remote.deleteBill('c1')).thenAnswer((_) async {});

      final result = await repo.deleteBill(3);

      expect(result, const Right<Failure, void>(null));
      verifyInOrder([
        () => local.findById(3),
        () => local.deleteBill(3),
        () => remote.deleteBill('c1'),
      ]);
    });

    test('offline → enqueue delete dengan data kosong', () async {
      when(() => local.findById(3)).thenAnswer((_) async => tModel);
      when(() => local.deleteBill(3)).thenAnswer((_) async {});
      when(() => network.isConnected).thenAnswer((_) async => false);
      when(
        () => local.addToSyncQueue(
          itemId: any(named: 'itemId'),
          collectionPath: any(named: 'collectionPath'),
          data: any(named: 'data'),
          operation: any(named: 'operation'),
        ),
      ).thenAnswer((_) async {});

      final result = await repo.deleteBill(3);

      expect(result, const Right<Failure, void>(null));
      verifyNever(() => remote.deleteBill(any()));
      verify(
        () => local.addToSyncQueue(
          itemId: 'c1',
          collectionPath: tPath,
          data: const <String, dynamic>{},
          operation: SyncOperation.delete,
        ),
      ).called(1);
    });

    test('cloudId null (belum tersinkron) → tak enqueue, tak remote', () async {
      final tNoCloud = _billModel();
      when(() => local.findById(3)).thenAnswer((_) async => tNoCloud);
      when(() => local.deleteBill(3)).thenAnswer((_) async {});

      final result = await repo.deleteBill(3);

      expect(result, const Right<Failure, void>(null));
      verifyNever(() => remote.deleteBill(any()));
      verifyNever(
        () => local.addToSyncQueue(
          itemId: any(named: 'itemId'),
          collectionPath: any(named: 'collectionPath'),
          data: any(named: 'data'),
          operation: any(named: 'operation'),
        ),
      );
    });
  });

  group('syncBillsFromRemote (pull-all-on-first-sync)', () {
    test('(d) lokal sudah berisi → Right(0), remote TIDAK disentuh', () async {
      when(() => local.hasAnyBills()).thenAnswer((_) async => true);

      final result = await repo.syncBillsFromRemote();

      expect(result, const Right<Failure, int>(0));
      verifyNever(() => remote.getBills());
    });

    test('lokal kosong + offline → Right(0), remote TIDAK disentuh', () async {
      when(() => local.hasAnyBills()).thenAnswer((_) async => false);
      when(() => network.isConnected).thenAnswer((_) async => false);

      final result = await repo.syncBillsFromRemote();

      expect(result, const Right<Failure, int>(0));
      verifyNever(() => remote.getBills());
    });

    test('lokal kosong + online → pull semua, upsert, Right(n)', () async {
      when(() => local.hasAnyBills()).thenAnswer((_) async => false);
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(() => remote.getBills()).thenAnswer((_) async => [tModel]);
      when(() => local.upsertFromRemote(any())).thenAnswer((_) async {});

      final result = await repo.syncBillsFromRemote();

      expect(result, const Right<Failure, int>(1));
      verify(() => local.upsertFromRemote([tModel])).called(1);
    });

    test('remote kosong → Right(0) tanpa upsert', () async {
      when(() => local.hasAnyBills()).thenAnswer((_) async => false);
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(() => remote.getBills()).thenAnswer((_) async => const []);

      final result = await repo.syncBillsFromRemote();

      expect(result, const Right<Failure, int>(0));
      verifyNever(() => local.upsertFromRemote(any()));
    });

    test('remote melempar ServerException → Left(ServerFailure)', () async {
      when(() => local.hasAnyBills()).thenAnswer((_) async => false);
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(() => remote.getBills()).thenThrow(const ServerException('boom'));

      final result = await repo.syncBillsFromRemote();

      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<ServerFailure>()), (_) {});
    });
  });

  group('watchActiveBills', () {
    test('memancarkan Right(list) dari local.watchActive()', () async {
      when(() => local.watchActive()).thenAnswer((_) => Stream.value([]));

      final result = await repo.watchActiveBills().first;

      expect(result.isRight(), isTrue);
      result.fold(
        (f) => fail('Seharusnya Right, dapat Left: $f'),
        (list) => expect(list, isEmpty),
      );
    });
  });
}
