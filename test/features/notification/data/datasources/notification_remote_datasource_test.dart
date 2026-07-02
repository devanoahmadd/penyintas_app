import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/features/notification/data/datasources/notification_remote_datasource.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseMessaging messaging;
  late NotificationRemoteDatasourceImpl ds;

  const tUid = 'uid-1';
  const tToken = 'tok-1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    messaging = MockFirebaseMessaging();
    ds = NotificationRemoteDatasourceImpl(messaging: messaging, firestore: firestore);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  DocumentReference<Map<String, dynamic>> tokenRef() => firestore
      .collection('users').doc(tUid).collection('fcmTokens').doc(tToken);

  group('registerToken', () {
    test('menulis subcollection (token, platform, createdAt, lastSeenAt) + legacy', () async {
      await ds.registerToken(tUid, tToken);

      final snap = await tokenRef().get();
      expect(snap.exists, isTrue);
      expect(snap.data()!['token'], tToken);
      expect(snap.data()!['platform'], 'android');
      expect(snap.data()!['createdAt'], isNotNull);
      expect(snap.data()!['lastSeenAt'], isNotNull);

      final userSnap = await firestore.collection('users').doc(tUid).get();
      expect(userSnap.data()!['fcmToken'], tToken);
    });

    test('platform ios saat target iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await ds.registerToken(tUid, tToken);
      final snap = await tokenRef().get();
      expect(snap.data()!['platform'], 'ios');
    });

    test('createdAt create-only: register ulang TIDAK menimpa createdAt', () async {
      final seeded = Timestamp.fromDate(DateTime.utc(2020, 1, 1));
      await tokenRef().set({'token': tToken, 'platform': 'android', 'createdAt': seeded});

      await ds.registerToken(tUid, tToken); // doc sudah ada → createdAt tak ditulis

      final snap = await tokenRef().get();
      expect(snap.data()!['createdAt'], seeded);
      expect(snap.data()!['lastSeenAt'], isNotNull);
    });
  });

  group('unregisterToken', () {
    test('hapus dok token + bersihkan legacy bila == token', () async {
      await tokenRef().set({'token': tToken, 'platform': 'android'});
      await firestore.collection('users').doc(tUid).set({'fcmToken': tToken});

      await ds.unregisterToken(tUid, tToken);

      expect((await tokenRef().get()).exists, isFalse);
      final userSnap = await firestore.collection('users').doc(tUid).get();
      expect(userSnap.data()?['fcmToken'], isNull);
    });

    test('legacy beda token TIDAK dihapus', () async {
      await firestore.collection('users').doc(tUid).set({'fcmToken': 'token-lain'});
      await ds.unregisterToken(tUid, tToken);
      final userSnap = await firestore.collection('users').doc(tUid).get();
      expect(userSnap.data()?['fcmToken'], 'token-lain');
    });
  });

  group('getPushEnabled', () {
    test('default true bila doc tak ada', () async {
      expect(await ds.getPushEnabled(tUid), isTrue);
    });
    test('false bila pushEnabled == false', () async {
      await firestore.collection('users').doc(tUid)
          .collection('settings').doc('notifications').set({'pushEnabled': false});
      expect(await ds.getPushEnabled(tUid), isFalse);
    });
  });

  group('setPushEnabled', () {
    test('menulis pushEnabled + updatedAt', () async {
      await ds.setPushEnabled(tUid, false);
      final snap = await firestore.collection('users').doc(tUid)
          .collection('settings').doc('notifications').get();
      expect(snap.data()!['pushEnabled'], isFalse);
      expect(snap.data()!['updatedAt'], isNotNull);
    });
  });
}
