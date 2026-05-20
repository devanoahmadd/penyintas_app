import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

abstract class NotificationRemoteDatasource {
  Future<String?> getFcmToken();
  Future<void> saveFcmToken(String uid, String token);
  Stream<String> get onTokenRefresh;
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
  Future<void> saveFcmToken(String uid, String token) =>
      _firestore.collection('users').doc(uid).set(
    {'fcmToken': token, 'fcmUpdatedAt': FieldValue.serverTimestamp()},
    SetOptions(merge: true),
  );

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}
