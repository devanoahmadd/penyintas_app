import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/features/goal/data/models/goal_model.dart';

abstract class GoalRemoteDatasource {
  /// Semua goal milik user. Return [] jika belum login
  /// (pola BudgetRemoteDatasource.getBudgetSettings — read tak melempar auth).
  Future<List<GoalModel>> getGoals();

  /// Set penuh (create & update memakai jalur yang sama — doc ID stabil).
  Future<void> saveGoal(GoalModel goal);

  Future<void> deleteGoal(String firestoreId);
}

class GoalRemoteDatasourceImpl implements GoalRemoteDatasource {
  GoalRemoteDatasourceImpl({
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
      _firestore.collection('users').doc(uid).collection('goals');

  static void _logError(Object e, StackTrace stack) {
    try {
      FirebaseCrashlytics.instance.recordError(e, stack);
    } catch (_) {}
  }

  @override
  Future<List<GoalModel>> getGoals() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const [];
    try {
      final snap = await _col(uid).get();
      return snap.docs
          .map((d) => GoalModel.fromFirestore(d.id, d.data()))
          .toList();
    } catch (e, stack) {
      _logError(e, stack);
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> saveGoal(GoalModel goal) async {
    final uid = _uid; // AuthException bila belum login — sebelum try/catch
    try {
      await _col(uid).doc(goal.firestoreId).set(goal.toFirestore());
    } catch (e, stack) {
      _logError(e, stack);
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteGoal(String firestoreId) async {
    final uid = _uid;
    try {
      await _col(uid).doc(firestoreId).delete();
    } catch (e, stack) {
      _logError(e, stack);
      throw ServerException(e.toString());
    }
  }
}
