import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/native.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/network/network_info.dart';
import 'package:penyintas_app/core/sync/sync_service.dart';

class MockNetworkInfo extends Mock implements NetworkInfo {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockFirebaseUser extends Mock implements User {}

AppDatabase openTestDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late MockNetworkInfo mockNetwork;
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseUser mockUser;

  // Jumlah kali dispatchFn dipanggil
  int dispatchCallCount = 0;
  // Apakah dispatchFn harus throw
  bool dispatchShouldFail = false;

  Future<void> fakeDispatch(SyncQueueData item, FirebaseFirestore fs) async {
    dispatchCallCount++;
    if (dispatchShouldFail) throw Exception('dispatch error');
  }

  setUp(() {
    db = openTestDb();
    mockNetwork = MockNetworkInfo();
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockUser = MockFirebaseUser();
    dispatchCallCount = 0;
    dispatchShouldFail = false;

    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('uid-test');
    when(() => mockNetwork.isConnected).thenAnswer((_) async => false);
    when(() => mockNetwork.onConnectivityChanged)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockAuth.authStateChanges())
        .thenAnswer((_) => const Stream.empty());
  });

  tearDown(() => db.close());

  SyncService buildService() => SyncService(
        db: db,
        networkInfo: mockNetwork,
        auth: mockAuth,
        firestore: mockFirestore,
        dispatchFn: fakeDispatch,
      );

  Future<void> insertQueueItem({
    String itemId = 'item-1',
    String path = 'users/uid-test/transactions/item-1',
    SyncOperation op = SyncOperation.create,
  }) =>
      db.into(db.syncQueue).insert(SyncQueueCompanion.insert(
            itemId: itemId,
            collectionPath: path,
            data: '{"id":"$itemId"}',
            operation: op,
            createdAt: DateTime.now(),
          ));

  group('_processQueue', () {
    test('dispatch berhasil → item dihapus dari queue', () async {
      await insertQueueItem();
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);

      final service = buildService()..start();
      await Future.delayed(const Duration(milliseconds: 50));
      service.dispose();

      expect(dispatchCallCount, 1);
      final remaining = await db.select(db.syncQueue).get();
      expect(remaining, isEmpty);
    });

    test('dispatch gagal → item tetap di queue (retry berikutnya)', () async {
      await insertQueueItem();
      dispatchShouldFail = true;
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);

      final service = buildService()..start();
      await Future.delayed(const Duration(milliseconds: 50));
      service.dispose();

      expect(dispatchCallCount, 1);
      final remaining = await db.select(db.syncQueue).get();
      expect(remaining.length, 1);
    });

    test('user tidak login → queue tidak diproses', () async {
      await insertQueueItem();
      when(() => mockAuth.currentUser).thenReturn(null);
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);

      final service = buildService()..start();
      await Future.delayed(const Duration(milliseconds: 50));
      service.dispose();

      expect(dispatchCallCount, 0);
      final remaining = await db.select(db.syncQueue).get();
      expect(remaining.length, 1);
    });

    test('beberapa item diproses sesuai urutan createdAt', () async {
      final dispatched = <String>[];
      Future<void> orderedDispatch(SyncQueueData item, FirebaseFirestore _) async {
        dispatched.add(item.itemId);
      }

      final t1 = DateTime.now().subtract(const Duration(minutes: 1));
      final t2 = DateTime.now();
      await db.into(db.syncQueue).insert(SyncQueueCompanion.insert(
            itemId: 'second',
            collectionPath: 'p/second',
            data: '{}',
            operation: SyncOperation.create,
            createdAt: t2,
          ));
      await db.into(db.syncQueue).insert(SyncQueueCompanion.insert(
            itemId: 'first',
            collectionPath: 'p/first',
            data: '{}',
            operation: SyncOperation.create,
            createdAt: t1,
          ));

      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);

      final service = SyncService(
        db: db,
        networkInfo: mockNetwork,
        auth: mockAuth,
        firestore: mockFirestore,
        dispatchFn: orderedDispatch,
      )..start();
      await Future.delayed(const Duration(milliseconds: 50));
      service.dispose();

      expect(dispatched, ['first', 'second']);
    });

    test(
        'item malformed (ArgumentError) di-purge langsung, item valid tetap diproses',
        () async {
      await insertQueueItem(
        itemId: 'malformed-1',
        path: 'users/{uid}/budget_settings',
      );
      await insertQueueItem(itemId: 'valid-1');
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);

      final dispatched = <String>[];
      final service = SyncService(
        db: db,
        networkInfo: mockNetwork,
        auth: mockAuth,
        firestore: mockFirestore,
        dispatchFn: (item, fs) async {
          // Meniru guard toFirestoreOp (#252)
          if (item.collectionPath.contains('{')) {
            throw ArgumentError.value(
                item.collectionPath, 'collectionPath', 'malformed');
          }
          dispatched.add(item.itemId);
        },
      )..start();
      await Future.delayed(const Duration(milliseconds: 50));
      service.dispose();

      expect(dispatched, ['valid-1']); // item valid tetap terkirim
      final remaining = await db.select(db.syncQueue).get();
      expect(remaining, isEmpty); // malformed di-purge, valid terhapus normal
    });
  });

  group('mutex', () {
    test('_processing flag mencegah concurrent processing', () async {
      await insertQueueItem();
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);

      // Buat dispatch lambat agar mutex sempat tercapture
      Future<void> slowDispatch(SyncQueueData item, FirebaseFirestore _) async {
        dispatchCallCount++;
        await Future.delayed(const Duration(milliseconds: 30));
      }

      final service = SyncService(
        db: db,
        networkInfo: mockNetwork,
        auth: mockAuth,
        firestore: mockFirestore,
        dispatchFn: slowDispatch,
      );

      // Trigger dua kali berturutan — hanya satu yang masuk
      service.start();
      service.start();
      await Future.delayed(const Duration(milliseconds: 100));
      service.dispose();

      expect(dispatchCallCount, 1);
    });
  });

  group('dispose', () {
    test('tidak throw saat dipanggil', () {
      final service = buildService()..start();
      expect(() => service.dispose(), returnsNormally);
    });
  });
}
