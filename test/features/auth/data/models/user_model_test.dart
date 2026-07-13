import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/auth/data/models/user_model.dart';

void main() {
  final tModel = UserModel(
    uid: 'uid-1',
    email: 'a@b.com',
    displayName: 'Tester',
    createdAt: DateTime.utc(2026, 1, 1),
  );

  test('toFirestore TIDAK menulis fcmToken (ditulis registerToken saja)', () {
    final map = tModel.toFirestore();
    expect(map.containsKey('fcmToken'), isFalse);
    expect(map['email'], 'a@b.com');
    expect(map['displayName'], 'Tester');
  });

  test('fromFirestore tetap toleran membaca fcmToken legacy', () async {
    final fs = FakeFirebaseFirestore();
    await fs.collection('users').doc('uid-1').set({
      'email': 'a@b.com',
      'displayName': 'Tester',
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      'fcmToken': 'legacy-tok',
    });
    final doc = await fs.collection('users').doc('uid-1').get();
    final model = UserModel.fromFirestore(doc);
    expect(model.fcmToken, 'legacy-tok');
  });

  group('flag verifikasi email (B4)', () {
    test(
      'default: emailVerified true, hasPasswordProvider false (banner tersembunyi)',
      () {
        final model = UserModel(
          uid: 'u1',
          email: 'a@b.com',
          displayName: 'A',
          createdAt: DateTime(2026),
        );
        expect(model.emailVerified, isTrue);
        expect(model.hasPasswordProvider, isFalse);
      },
    );

    test('ctor menerima flag eksplisit dan masuk props (Equatable)', () {
      final a = UserModel(
        uid: 'u1',
        email: 'a@b.com',
        displayName: 'A',
        createdAt: DateTime(2026),
        emailVerified: false,
        hasPasswordProvider: true,
      );
      final b = UserModel(
        uid: 'u1',
        email: 'a@b.com',
        displayName: 'A',
        createdAt: DateTime(2026),
      );
      expect(
        a == b,
        isFalse,
      ); // flag beda → entity beda → BLoC re-emit terbaca UI
    });

    test('copyWith mempertahankan flag', () {
      final model = UserModel(
        uid: 'u1',
        email: 'a@b.com',
        displayName: 'A',
        createdAt: DateTime(2026),
        emailVerified: false,
        hasPasswordProvider: true,
      );
      final copied = model.copyWith(fcmToken: 'tok');
      expect(copied.emailVerified, isFalse);
      expect(copied.hasPasswordProvider, isTrue);
    });
  });
}
