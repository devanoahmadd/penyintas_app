import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/auth/data/models/user_settings_model.dart';

void main() {
  test('fromFirestore membaca onboardingCompleted', () {
    final model = UserSettingsModel.fromFirestore({'onboardingCompleted': true});
    expect(model.onboardingCompleted, true);
  });

  test('fromFirestore null-safe: field hilang → false', () {
    final model = UserSettingsModel.fromFirestore({});
    expect(model.onboardingCompleted, false);
  });

  test('fromFirestore valor truthy non-bool → false', () {
    final model = UserSettingsModel.fromFirestore({'onboardingCompleted': 1});
    expect(model.onboardingCompleted, false);
  });

  test('toFirestore hanya menulis onboardingCompleted + updatedAt', () {
    const model = UserSettingsModel(onboardingCompleted: true);
    final map = model.toFirestore();
    expect(map['onboardingCompleted'], true);
    expect(map.containsKey('updatedAt'), true);
    expect(map.containsKey('rentAmount'), false);
    expect(map.length, 2);
  });
}
