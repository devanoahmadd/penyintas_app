import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/features/preferences/data/models/preferences_model.dart';
import 'package:penyintas_app/features/preferences/domain/entities/preferences_entity.dart';

abstract class PreferencesRemoteDatasource {
  Future<PreferencesModel?> fetch();
  Future<void> mirror(PreferencesEntity prefs);
}

class PreferencesRemoteDatasourceImpl implements PreferencesRemoteDatasource {
  PreferencesRemoteDatasourceImpl({
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
      .collection('users').doc(_uid)
      .collection('preferences').doc('current');

  // Menyerap kegagalan Crashlytics saat test (tak ada Firebase app di unit test
  // environment). Pola konsisten dengan auth_remote_datasource.dart.
  static void _logError(Object e, StackTrace s) {
    try {
      FirebaseCrashlytics.instance.recordError(e, s);
    } catch (_) {}
  }

  @override
  Future<PreferencesModel?> fetch() async {
    try {
      final snap = await _doc.get();
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return PreferencesModel.fromFirestore(data);
    } catch (e, s) {
      _logError(e, s);
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> mirror(PreferencesEntity prefs) async {
    try {
      // Full-doc — TANPA SetOptions(merge) — agar lolos rules hasAll/hasOnly (A7).
      await _doc.set(PreferencesModel.fromEntity(prefs).toFirestore());
    } on FirebaseException catch (e, s) {
      _logError(e, s);
      // `permission-denied` di sini = BUG KONTRAK (model ↔ rules drift), BUKAN
      // offline. Suarakan keras di debug/test agar mismatch ketahuan saat dev —
      // bukan diam-diam jadi "phantom field" yg baru muncul di Crashlytics (C1).
      // `assert` di-strip di release → tetap non-fatal di produksi.
      assert(
        e.code != 'permission-denied',
        'Preferences mirror DITOLAK rules — toFirestore() melanggar '
        'hasAll/hasOnly/validasi. Sinkronkan model dgn firestore.rules. ($e)',
      );
      throw ServerException(e.toString());
    } catch (e, s) {
      _logError(e, s);
      throw ServerException(e.toString());
    }
  }
}
