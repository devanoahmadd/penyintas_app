import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/features/bills/data/models/bill_model.dart';

/// Mirror pola GoalRemoteDatasource. Task 6.3 menambah firestore.rules +
/// composite index + test datasource/rules DI ATAS ini — bukan bikin ulang.
abstract class BillRemoteDatasource {
  /// Semua bill milik user. Return [] jika belum login
  /// (pola GoalRemoteDatasource.getGoals — read tak melempar auth).
  Future<List<BillModel>> getBills();

  /// Set penuh (create & update memakai jalur yang sama — doc ID stabil).
  Future<void> saveBill(BillModel bill);

  Future<void> deleteBill(String cloudId);
}

class BillRemoteDatasourceImpl implements BillRemoteDatasource {
  BillRemoteDatasourceImpl({
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
      _firestore.collection('users').doc(uid).collection('bills');

  static void _logError(Object e, StackTrace stack) {
    try {
      FirebaseCrashlytics.instance.recordError(e, stack);
    } catch (_) {}
  }

  @override
  Future<List<BillModel>> getBills() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const [];
    try {
      final snap = await _col(uid).get();
      return snap.docs
          .map((d) => BillModel.fromFirestore(d.id, d.data()))
          .toList();
    } catch (e, stack) {
      _logError(e, stack);
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> saveBill(BillModel bill) async {
    final uid = _uid; // AuthException bila belum login — sebelum try/catch
    final cloudId = bill.cloudId;
    if (cloudId == null) throw const AuthException('cloudId kosong');
    try {
      await _col(uid).doc(cloudId).set(bill.toFirestore());
    } catch (e, stack) {
      _logError(e, stack);
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteBill(String cloudId) async {
    final uid = _uid;
    try {
      await _col(uid).doc(cloudId).delete();
    } catch (e, stack) {
      _logError(e, stack);
      throw ServerException(e.toString());
    }
  }
}
