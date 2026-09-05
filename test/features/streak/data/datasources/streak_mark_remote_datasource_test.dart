import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/features/streak/data/datasources/streak_mark_remote_datasource.dart';
import 'package:penyintas_app/features/streak/data/models/streak_mark_model.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late MockUser user;
  late StreakMarkRemoteDatasourceImpl datasource;

  const tUid = 'uid-test';

  final tModel = StreakMarkModel(
    dayKey: 20260902,
    markedAt: DateTime.utc(2026, 9, 2, 3),
    timezone: 'Asia/Jakarta',
  );

  // Dokumen mentah — dipakai saat test hanya peduli pada bentuk baris di
  // koleksi (filter, isolasi delete), bukan pada bentuk StreakMarkModel itu
  // sendiri (yang sudah dikunci streak_mark_model_test.dart).
  Map<String, dynamic> rawDoc(int dayKey) => {
    'dayKey': dayKey,
    'markedAt': 1,
    'timezone': 'WIB',
    'updatedAt': 1,
  };

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth();
    user = MockUser();
    when(() => user.uid).thenReturn(tUid);
    when(() => auth.currentUser).thenReturn(user);
    datasource = StreakMarkRemoteDatasourceImpl(
      auth: auth,
      firestore: firestore,
    );
  });

  group('getMarks', () {
    test('returns [] jika belum ada dokumen', () async {
      expect(await datasource.getMarks(), isEmpty);
    });

    test(
      'returns [] jika uid null (belum login) — read tak melempar auth',
      () async {
        when(() => auth.currentUser).thenReturn(null);
        expect(await datasource.getMarks(), isEmpty);
      },
    );

    test('dokumen yang ada kembali sebagai model lewat fromFirestore(docId, '
        'data)', () async {
      // Field 'dayKey' WAJIB ada di sini: query .where('dayKey', ...)
      // sendiri sudah menyaring dokumen yang tak punya field itu sama sekali
      // (perilaku range-query Firestore asli) — jadi fallback docId di
      // fromFirestore() tak pernah tercapai lewat jalur getMarks(). Fallback
      // itu sudah terkunci lain tempat (streak_mark_model_test.dart).
      await firestore
          .collection('users')
          .doc(tUid)
          .collection('streak_marks')
          .doc('20260902')
          .set(rawDoc(20260902));

      final result = await datasource.getMarks();

      expect(result, hasLength(1));
      expect(result.first.dayKey, 20260902);
      expect(result.first.timezone, 'WIB');
    });

    test('sinceDayKey benar-benar menyaring — hanya dayKey >= ambang yang '
        'ikut', () async {
      final col = firestore
          .collection('users')
          .doc(tUid)
          .collection('streak_marks');
      await col.doc('20260901').set(rawDoc(20260901));
      await col.doc('20260902').set(rawDoc(20260902));
      await col.doc('20260903').set(rawDoc(20260903));

      final result = await datasource.getMarks(sinceDayKey: 20260902);

      expect(
        result.map((m) => m.dayKey).toSet(),
        {20260902, 20260903},
        reason: '20260901 ada di bawah ambang — harus tersaring',
      );
    });

    test('panggilan TANPA argumen mengembalikan SEMUA dokumen — mengunci '
        'default sinceDayKey=0', () async {
      final col = firestore
          .collection('users')
          .doc(tUid)
          .collection('streak_marks');
      await col.doc('20200101').set(rawDoc(20200101));
      await col.doc('20260901').set(rawDoc(20260901));
      await col.doc('20260902').set(rawDoc(20260902));

      final result = await datasource.getMarks();

      expect(result.map((m) => m.dayKey).toSet(), {
        20200101,
        20260901,
        20260902,
      });
    });
  });

  group('saveMark', () {
    test('menulis dokumen di users/{uid}/streak_marks/{dayKey} berbentuk '
        'toFirestore(), tanpa viaClockCorrection', () async {
      final sebelum = DateTime.now().millisecondsSinceEpoch;
      await datasource.saveMark(tModel);
      final sesudah = DateTime.now().millisecondsSinceEpoch;

      final doc = await firestore
          .collection('users')
          .doc(tUid)
          .collection('streak_marks')
          .doc('20260902')
          .get();
      expect(doc.exists, isTrue);

      final data = doc.data()!;
      expect(data['dayKey'], tModel.dayKey);
      expect(data['markedAt'], tModel.markedAt.toUtc().millisecondsSinceEpoch);
      expect(data['timezone'], tModel.timezone);
      expect(
        data.containsKey('viaClockCorrection'),
        isFalse,
        reason: 'kolom lokal — tak pernah dikirim ke Firestore',
      );
      expect(
        data['updatedAt'],
        allOf(greaterThanOrEqualTo(sebelum), lessThanOrEqualTo(sesudah)),
      );
    });

    test('throws AuthException jika belum login — TIDAK terbungkus '
        'ServerException', () async {
      when(() => auth.currentUser).thenReturn(null);
      expect(() => datasource.saveMark(tModel), throwsA(isA<AuthException>()));
    });
  });

  group('deleteMark', () {
    test('menghapus tepat dokumen dayKey yang dimaksud, dayKey lain di '
        'koleksi sama tidak tersentuh', () async {
      final col = firestore
          .collection('users')
          .doc(tUid)
          .collection('streak_marks');
      await col.doc('20260902').set(rawDoc(20260902));
      await col.doc('20260903').set(rawDoc(20260903));

      await datasource.deleteMark(20260902);

      final dihapus = await col.doc('20260902').get();
      final sisa = await col.doc('20260903').get();
      expect(dihapus.exists, isFalse);
      expect(
        sisa.exists,
        isTrue,
        reason:
            'dayKey lain dalam koleksi yang sama tidak boleh ikut '
            'terhapus',
      );
    });

    test('throws AuthException jika belum login', () async {
      when(() => auth.currentUser).thenReturn(null);
      expect(
        () => datasource.deleteMark(20260902),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
