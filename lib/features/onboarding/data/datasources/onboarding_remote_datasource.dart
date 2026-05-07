import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/features/onboarding/data/models/budget_settings_model.dart';
import 'package:penyintas_app/features/onboarding/domain/entities/budget_settings_entity.dart';

abstract class OnboardingRemoteDataSource {
  Future<void> saveBudgetSettings(BudgetSettingsEntity settings);
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

      await firestore
          .collection('users')
          .doc(uid)
          .update({'onboardingCompleted': true});
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const ServerException();
    }
  }
}
