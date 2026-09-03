import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/features/streak/data/models/streak_mark_model.dart';

abstract class StreakMarkRemoteDatasource {
  /// Penanda milik user. Return [] bila belum login (pola
  /// GoalRemoteDatasource — read tak melempar auth).
  Future<List<StreakMarkModel>> getMarks({int sinceDayKey});
  Future<void> saveMark(StreakMarkModel mark);
  Future<void> deleteMark(int dayKey);
}

class StreakMarkRemoteDatasourceImpl implements StreakMarkRemoteDatasource {
  StreakMarkRemoteDatasourceImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const AuthException('Pengguna belum login.');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _firestore.collection('users').doc(uid).collection('streak_marks');

  static void _logError(Object e, StackTrace stack) {
    try {
      FirebaseCrashlytics.instance.recordError(e, stack);
    } catch (_) {}
  }

  @override
  Future<List<StreakMarkModel>> getMarks({int sinceDayKey = 0}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const [];
    try {
      // Filter satu field — Firestore mengindeksnya otomatis, jadi
      // firestore.indexes.json TIDAK bertambah.
      final snap = await _col(
        uid,
      ).where('dayKey', isGreaterThanOrEqualTo: sinceDayKey).get();
      return snap.docs
          .map((d) => StreakMarkModel.fromFirestore(d.id, d.data()))
          .toList();
    } catch (e, stack) {
      _logError(e, stack);
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> saveMark(StreakMarkModel mark) async {
    final uid = _uid;
    try {
      await _col(uid)
          .doc(mark.docId)
          .set(
            mark.toFirestore(updatedAtMs: DateTime.now().millisecondsSinceEpoch),
          );
    } catch (e, stack) {
      _logError(e, stack);
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteMark(int dayKey) async {
    final uid = _uid;
    try {
      await _col(uid).doc(dayKey.toString()).delete();
    } catch (e, stack) {
      _logError(e, stack);
      throw ServerException(e.toString());
    }
  }
}
