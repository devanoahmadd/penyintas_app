import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/features/bills/data/datasources/bill_remote_datasource.dart';
import 'package:penyintas_app/features/bills/data/models/bill_model.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late MockUser user;
  late BillRemoteDatasourceImpl datasource;

  const tUid = 'uid-test';

  final tModel = BillModel(
    cloudId: 'bill-123',
    name: 'Kos Bulanan',
    estimatedAmount: 750000,
    category: 'Sewa',
    isFixedNeed: true,
    notes: 'Bayar ke Bu Tini',
    dueDate: DateTime.fromMillisecondsSinceEpoch(1798675200000),
    recurrence: Recurrence.monthly,
    installmentsPaid: 0,
    dueDayOfMonth: 5,
    reminderDaysBefore: 3,
    reminderEnabled: true,
    status: BillStatus.active,
    createdAt: DateTime.fromMillisecondsSinceEpoch(1751700000000),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(1751700000000),
  );

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth();
    user = MockUser();
    when(() => user.uid).thenReturn(tUid);
    when(() => auth.currentUser).thenReturn(user);
    datasource = BillRemoteDatasourceImpl(auth: auth, firestore: firestore);
  });

  group('getBills', () {
    test('returns [] jika belum ada dokumen', () async {
      expect(await datasource.getBills(), isEmpty);
    });

    test('returns [] jika uid null (belum login)', () async {
      when(() => auth.currentUser).thenReturn(null);
      expect(await datasource.getBills(), isEmpty);
    });

    test('returns semua model, docId → cloudId', () async {
      await firestore
          .collection('users')
          .doc(tUid)
          .collection('bills')
          .doc('bill-123')
          .set(tModel.toFirestore());

      final result = await datasource.getBills();

      expect(result, hasLength(1));
      expect(result.first.cloudId, 'bill-123');
      expect(result.first.name, 'Kos Bulanan');
      expect(result.first.estimatedAmount, 750000);
      expect(result.first.category, 'Sewa');
      expect(result.first.status, BillStatus.active);
      expect(result.first.recurrence, Recurrence.monthly);
      expect(result.first.dueDate, tModel.dueDate);
    });
  });

  group('saveBill', () {
    test('menulis dokumen di users/{uid}/bills/{cloudId}', () async {
      await datasource.saveBill(tModel);

      final doc = await firestore
          .collection('users')
          .doc(tUid)
          .collection('bills')
          .doc('bill-123')
          .get();
      expect(doc.exists, isTrue);
      expect(doc.data(), tModel.toFirestore());
    });

    test('throws AuthException jika belum login', () async {
      when(() => auth.currentUser).thenReturn(null);
      expect(() => datasource.saveBill(tModel), throwsA(isA<AuthException>()));
    });

    test('throws jika cloudId null', () async {
      final tModelNoCloudId = BillModel(
        name: tModel.name,
        estimatedAmount: tModel.estimatedAmount,
        category: tModel.category,
        isFixedNeed: tModel.isFixedNeed,
        notes: tModel.notes,
        dueDate: tModel.dueDate,
        recurrence: tModel.recurrence,
        installmentsPaid: tModel.installmentsPaid,
        dueDayOfMonth: tModel.dueDayOfMonth,
        reminderDaysBefore: tModel.reminderDaysBefore,
        reminderEnabled: tModel.reminderEnabled,
        status: tModel.status,
        createdAt: tModel.createdAt,
        updatedAt: tModel.updatedAt,
      );
      expect(
        () => datasource.saveBill(tModelNoCloudId),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('deleteBill', () {
    test('menghapus dokumen', () async {
      await datasource.saveBill(tModel);
      await datasource.deleteBill('bill-123');

      final doc = await firestore
          .collection('users')
          .doc(tUid)
          .collection('bills')
          .doc('bill-123')
          .get();
      expect(doc.exists, isFalse);
    });

    test('throws AuthException jika belum login', () async {
      when(() => auth.currentUser).thenReturn(null);
      expect(
        () => datasource.deleteBill('bill-123'),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
