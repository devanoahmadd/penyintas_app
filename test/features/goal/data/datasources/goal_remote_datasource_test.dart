import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/features/goal/data/datasources/goal_remote_datasource.dart';
import 'package:penyintas_app/features/goal/data/models/goal_model.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late MockUser user;
  late GoalRemoteDatasourceImpl datasource;

  const tUid = 'uid-test';

  final tModel = GoalModel(
    firestoreId: 'fid-123',
    title: 'Pulang kampung',
    targetAmount: 1500000,
    targetDate: DateTime.fromMillisecondsSinceEpoch(1798675200000),
    isCompleted: false,
    createdAt: DateTime.fromMillisecondsSinceEpoch(1751700000000),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(1751700000000),
  );

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth();
    user = MockUser();
    when(() => user.uid).thenReturn(tUid);
    when(() => auth.currentUser).thenReturn(user);
    datasource = GoalRemoteDatasourceImpl(auth: auth, firestore: firestore);
  });

  group('getGoals', () {
    test('returns [] jika belum ada dokumen', () async {
      expect(await datasource.getGoals(), isEmpty);
    });

    test('returns [] jika uid null (belum login)', () async {
      when(() => auth.currentUser).thenReturn(null);
      expect(await datasource.getGoals(), isEmpty);
    });

    test('returns semua model, docId → firestoreId', () async {
      await firestore
          .collection('users')
          .doc(tUid)
          .collection('goals')
          .doc('fid-123')
          .set(tModel.toFirestore());

      final result = await datasource.getGoals();

      expect(result, hasLength(1));
      expect(result.first.firestoreId, 'fid-123');
      expect(result.first.title, 'Pulang kampung');
      expect(result.first.targetAmount, 1500000);
    });
  });

  group('saveGoal', () {
    test('menulis dokumen di users/{uid}/goals/{firestoreId}', () async {
      await datasource.saveGoal(tModel);

      final doc = await firestore
          .collection('users')
          .doc(tUid)
          .collection('goals')
          .doc('fid-123')
          .get();
      expect(doc.exists, isTrue);
      expect(doc.data(), tModel.toFirestore());
    });

    test('throws AuthException jika belum login', () async {
      when(() => auth.currentUser).thenReturn(null);
      expect(() => datasource.saveGoal(tModel), throwsA(isA<AuthException>()));
    });
  });

  group('deleteGoal', () {
    test('menghapus dokumen', () async {
      await datasource.saveGoal(tModel);
      await datasource.deleteGoal('fid-123');

      final doc = await firestore
          .collection('users')
          .doc(tUid)
          .collection('goals')
          .doc('fid-123')
          .get();
      expect(doc.exists, isFalse);
    });

    test('throws AuthException jika belum login', () async {
      when(() => auth.currentUser).thenReturn(null);
      expect(
        () => datasource.deleteGoal('fid-123'),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
