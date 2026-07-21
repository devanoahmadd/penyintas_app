import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/features/preferences/data/datasources/preferences_remote_datasource.dart';
import 'package:penyintas_app/features/preferences/domain/entities/preferences_entity.dart';

class _MockAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late _MockAuth auth;
  late PreferencesRemoteDatasourceImpl ds;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = _MockAuth();
    final user = _MockUser();
    when(() => user.uid).thenReturn('u1');
    when(() => auth.currentUser).thenReturn(user);
    ds = PreferencesRemoteDatasourceImpl(auth: auth, firestore: firestore);
  });

  test('fetch() saat dokumen belum ada → null', () async {
    expect(await ds.fetch(), isNull);
  });

  test('mirror() menulis full-doc lalu fetch() membacanya', () async {
    await ds.mirror(
      PreferencesEntity.defaults.copyWith(
        timezone: 'Europe/Moscow',
        profileCompleted: true,
      ),
    );
    final snap = await firestore
        .collection('users')
        .doc('u1')
        .collection('preferences')
        .doc('current')
        .get();
    expect(snap.exists, true);
    expect(snap.data()!['timezone'], 'Europe/Moscow');
    expect(snap.data()!['baseCurrency'], 'IDR');

    final got = await ds.fetch();
    expect(got!.profileCompleted, true);
  });

  test(
    'mirror() overwrite penuh (bukan merge) — field lama tak nyangkut',
    () async {
      await firestore
          .collection('users')
          .doc('u1')
          .collection('preferences')
          .doc('current')
          .set({'ghostField': 'x', 'timezone': 'Asia/Jakarta'});
      await ds.mirror(
        PreferencesEntity.defaults.copyWith(timezone: 'Europe/Moscow'),
      );
      final snap = await firestore
          .collection('users')
          .doc('u1')
          .collection('preferences')
          .doc('current')
          .get();
      expect(snap.data()!.containsKey('ghostField'), false); // overwrite penuh
      expect(snap.data()!['timezone'], 'Europe/Moscow');
    },
  );
}
