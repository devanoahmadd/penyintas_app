import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

abstract class NotificationRemoteDatasource {
  Future<String?> getFcmToken();
  Stream<String> get onTokenRefresh;
  Future<void> registerToken(String uid, String token);
  Future<void> unregisterToken(String uid, String token);
  Future<void> deleteToken();
  Future<bool> getPushEnabled(String uid);
  Future<void> setPushEnabled(String uid, bool enabled);
}

class NotificationRemoteDatasourceImpl implements NotificationRemoteDatasource {
  const NotificationRemoteDatasourceImpl({
    required FirebaseMessaging messaging,
    required FirebaseFirestore firestore,
  })  : _messaging = messaging,
        _firestore = firestore;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  @override
  Future<String?> getFcmToken() => _messaging.getToken();

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Future<void> registerToken(String uid, String token) async {
    final platform =
        defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
    final tokenRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .doc(token);
    final snap = await tokenRef.get();
    final data = <String, dynamic>{
      'token': token,
      'platform': platform,
      'lastSeenAt': FieldValue.serverTimestamp(),
    };
    // createdAt create-only — hanya saat dokumen belum ada (M3).
    if (!snap.exists) data['createdAt'] = FieldValue.serverTimestamp();
    await tokenRef.set(data, SetOptions(merge: true));

    // Dual-write legacy (§G) — agar CF lama yang belum deploy tetap menemukan token.
    await _firestore.collection('users').doc(uid).set(
      {'fcmToken': token, 'fcmUpdatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> unregisterToken(String uid, String token) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .doc(token)
        .delete();
    // Bersihkan legacy HANYA bila masih menunjuk token device ini.
    final userRef = _firestore.collection('users').doc(uid);
    final userSnap = await userRef.get();
    if (userSnap.exists && userSnap.data()?['fcmToken'] == token) {
      await userRef.update({
        'fcmToken': FieldValue.delete(),
        'fcmUpdatedAt': FieldValue.delete(),
      });
    }
  }

  @override
  Future<void> deleteToken() => _messaging.deleteToken();

  @override
  Future<bool> getPushEnabled(String uid) async {
    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('notifications')
        .get();
    final v = snap.data()?['pushEnabled'];
    return v is bool ? v : true; // default aktif (opt-out)
  }

  @override
  Future<void> setPushEnabled(String uid, bool enabled) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('notifications')
          .set(
        {'pushEnabled': enabled, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
}
