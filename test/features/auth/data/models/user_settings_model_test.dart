import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/auth/data/models/user_settings_model.dart';

void main() {
  test('fromFirestore memetakan field Firestore ke field Drift', () {
    final model = UserSettingsModel.fromFirestore({
      'onboardingCompleted': true,
      'rentAmount': 800000,
      'utilitiesAmount': 150000,
      'internetAmount': 100000,
      'phoneAmount': 50000,
      'otherFixedAmount': 25000,
    });

    expect(model.onboardingCompleted, true);
    expect(model.rentExpense, 800000);
    expect(model.utilitiesExpense, 150000);
    expect(model.internetExpense, 100000);
    expect(model.phoneExpense, 50000);
    expect(model.otherFixedExpense, 25000);
  });

  test('fromFirestore null-safe: field hilang pakai default', () {
    final model = UserSettingsModel.fromFirestore({});

    expect(model.onboardingCompleted, false);
    expect(model.rentExpense, 0);
    expect(model.utilitiesExpense, 0);
    expect(model.internetExpense, 0);
    expect(model.phoneExpense, 0);
    expect(model.otherFixedExpense, 0);
  });

  test('toFirestore memetakan field Drift ke nama field Firestore', () {
    const model = UserSettingsModel(
      onboardingCompleted: true,
      rentExpense: 800000,
      utilitiesExpense: 150000,
      internetExpense: 100000,
      phoneExpense: 50000,
      otherFixedExpense: 25000,
    );

    final map = model.toFirestore();

    expect(map['onboardingCompleted'], true);
    expect(map['rentAmount'], 800000);
    expect(map['utilitiesAmount'], 150000);
    expect(map['internetAmount'], 100000);
    expect(map['phoneAmount'], 50000);
    expect(map['otherFixedAmount'], 25000);
    expect(map.containsKey('updatedAt'), true);
  });
}
