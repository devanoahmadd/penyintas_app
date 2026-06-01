import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/features/auth/data/models/user_settings_model.dart';

abstract class UserSettingsRemoteDatasource {
  /// Null jika dokumen belum ada (user baru).
  Future<UserSettingsModel?> fetchUserSettings();
  Future<void> saveUserSettings(UserSettingsModel settings);
}

class UserSettingsRemoteDatasourceImpl implements UserSettingsRemoteDatasource {
  UserSettingsRemoteDatasourceImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const AuthException('Pengguna belum login.');
    return uid;
  }

  DocumentReference<Map<String, dynamic>> get _doc => _firestore
      .collection('users')
      .doc(_uid)
      .collection('settings')
      .doc('app');

  static void _logError(Object e, StackTrace stack) {
    try {
      FirebaseCrashlytics.instance.recordError(e, stack);
    } catch (_) {}
  }

  @override
  Future<UserSettingsModel?> fetchUserSettings() async {
    try {
      final snap = await _doc.get();
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return UserSettingsModel.fromFirestore(data);
    } catch (e, stack) {
      _logError(e, stack);
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> saveUserSettings(UserSettingsModel settings) async {
    try {
      await _doc.set(settings.toFirestore(), SetOptions(merge: true));
    } catch (e, stack) {
      _logError(e, stack);
      throw ServerException(e.toString());
    }
  }
}
