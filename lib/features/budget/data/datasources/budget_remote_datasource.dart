import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/features/budget/data/models/budget_limit_model.dart';
import 'package:penyintas_app/features/budget/data/models/budget_settings_model.dart';

abstract class BudgetRemoteDatasource {
  Future<void> saveBudgetSettings(BudgetSettingsModel settings);
  Future<void> saveBudgetLimit(BudgetLimitModel limit);
  Future<void> deleteBudgetLimit(String categoryName);
}

class BudgetRemoteDatasourceImpl implements BudgetRemoteDatasource {
  BudgetRemoteDatasourceImpl({
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

  static void _logError(Object e, StackTrace stack) {
    try {
      FirebaseCrashlytics.instance.recordError(e, stack);
    } catch (_) {}
  }

  @override
  Future<void> saveBudgetSettings(BudgetSettingsModel settings) async {
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('budget_settings')
          .doc('current')
          .set(settings.toFirestore());
    } catch (e, stack) {
      _logError(e, stack);
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> saveBudgetLimit(BudgetLimitModel limit) async {
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('budget_limits')
          .doc(limit.category)
          .set(limit.toFirestore());
    } catch (e, stack) {
      _logError(e, stack);
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteBudgetLimit(String categoryName) async {
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('budget_limits')
          .doc(categoryName)
          .delete();
    } catch (e, stack) {
      _logError(e, stack);
      throw ServerException(e.toString());
    }
  }
}
