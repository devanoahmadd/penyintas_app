import 'package:isar/isar.dart';

part 'app_settings_isar_model.g.dart';

@collection
class AppSettingsIsarModel {
  // Singleton — selalu id = 1
  Id id = 1;

  late String locale; // 'id' | 'en'
  late String themeMode; // 'system' | 'light' | 'dark'
  late bool onboardingCompleted;

  // Budget settings (disimpan bersama agar satu read untuk cold start)
  late int monthlyIncome;
  late int paymentDate; // 1–31
  late int fixedExpenses;
  late double emergencyFundPct; // 0.05–0.25
}
