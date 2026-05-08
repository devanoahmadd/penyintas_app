import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:penyintas_app/features/transaction/data/models/transaction_model.dart';

abstract class TransactionRemoteDataSource {
  Future<void> saveTransaction(TransactionModel model);
  Future<void> updateTransaction(TransactionModel model);
  Future<void> deleteTransaction(String txId);
  Future<List<TransactionModel>> getTransactions({
    DateTime? from,
    DateTime? to,
  });
}

class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  TransactionRemoteDataSourceImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col() {
    final uid = _auth.currentUser!.uid;
    return _firestore.collection('users/$uid/transactions');
  }

  @override
  Future<void> saveTransaction(TransactionModel model) async {
    await _col().doc(model.id).set(model.toFirestore());
  }

  @override
  Future<void> updateTransaction(TransactionModel model) async {
    await _col().doc(model.id).update(model.toFirestore());
  }

  @override
  Future<void> deleteTransaction(String txId) async {
    await _col().doc(txId).delete();
  }

  @override
  Future<List<TransactionModel>> getTransactions({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      Query<Map<String, dynamic>> q = _col();
      if (from != null) {
        q = q.where('date', isGreaterThanOrEqualTo: from.toIso8601String());
      }
      if (to != null) {
        q = q.where('date', isLessThanOrEqualTo: to.toIso8601String());
      }
      final snap = await q.get();
      return snap.docs
          .map((d) => TransactionModel.fromFirestore(d.data()))
          .toList();
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      rethrow;
    }
  }
}
