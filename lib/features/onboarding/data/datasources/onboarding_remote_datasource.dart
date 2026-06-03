import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/features/budget/data/models/budget_settings_model.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';

abstract class OnboardingRemoteDataSource {
  Future<void> saveBudgetSettings(BudgetSettingsEntity settings);
  Future<BudgetSettingsModel?> getBudgetSettings();
}

class OnboardingRemoteDataSourceImpl implements OnboardingRemoteDataSource {
  OnboardingRemoteDataSourceImpl({
    required this.firestore,
    required this.auth,
  });

  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  @override
  Future<void> saveBudgetSettings(BudgetSettingsEntity settings) async {
    final uid = auth.currentUser?.uid;
    if (uid == null) throw const AuthException('Pengguna tidak terautentikasi.');
    try {
      final model = BudgetSettingsModel.fromEntity(settings);
      await firestore
          .collection('users')
          .doc(uid)
          .collection('budget_settings')
          .doc('current')
          .set(model.toFirestore());
    } on AuthException {
      rethrow;
    } catch (e, s) {
      try { FirebaseCrashlytics.instance.recordError(e, s); } catch (_) {}
      throw const ServerException();
    }
  }

  @override
  Future<BudgetSettingsModel?> getBudgetSettings() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return null;
    try {
      final doc = await firestore
          .collection('users')
          .doc(uid)
          .collection('budget_settings')
          .doc('current')
          .get();
      if (!doc.exists) return null;
      return BudgetSettingsModel.fromFirestore(doc);
    } catch (e, s) {
      try { FirebaseCrashlytics.instance.recordError(e, s); } catch (_) {}
      throw const ServerException();
    }
  }
}
