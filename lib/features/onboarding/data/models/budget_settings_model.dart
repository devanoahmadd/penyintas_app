import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:penyintas_app/features/onboarding/domain/entities/budget_settings_entity.dart';

class BudgetSettingsModel extends BudgetSettingsEntity {
  const BudgetSettingsModel({
    required super.monthlyIncome,
    required super.paymentDate,
    required super.emergencyFundPct,
    required super.createdAt,
    super.rentExpense = 0,
    super.utilitiesExpense = 0,
    super.internetExpense = 0,
    super.phoneExpense = 0,
    super.otherFixedExpense = 0,
  });

  factory BudgetSettingsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Backward compat: jika breakdown belum ada, pakai legacy fixedExpenses di 'other'
    final legacyFixed = (data['fixedExpenses'] as num?)?.toInt() ?? 0;
    final rentExp = (data['rentExpense'] as num?)?.toInt() ?? 0;
    final utilitiesExp = (data['utilitiesExpense'] as num?)?.toInt() ?? 0;
    final internetExp = (data['internetExpense'] as num?)?.toInt() ?? 0;
    final phoneExp = (data['phoneExpense'] as num?)?.toInt() ?? 0;
    final otherExp = (data['otherFixedExpense'] as num?)?.toInt() ?? 0;
    final hasBreakdown =
        rentExp + utilitiesExp + internetExp + phoneExp + otherExp > 0;
    return BudgetSettingsModel(
      monthlyIncome: (data['monthlyIncome'] as num?)?.toInt() ?? 0,
      paymentDate: (data['paymentDate'] as num?)?.toInt() ?? 1,
      emergencyFundPct: (data['emergencyFundPct'] as num?)?.toDouble() ?? 0.10,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      rentExpense: rentExp,
      utilitiesExpense: utilitiesExp,
      internetExpense: internetExp,
      phoneExpense: phoneExp,
      otherFixedExpense: hasBreakdown ? otherExp : legacyFixed,
    );
  }

  factory BudgetSettingsModel.fromEntity(BudgetSettingsEntity entity) {
    return BudgetSettingsModel(
      monthlyIncome: entity.monthlyIncome,
      paymentDate: entity.paymentDate,
      emergencyFundPct: entity.emergencyFundPct,
      createdAt: entity.createdAt,
      rentExpense: entity.rentExpense,
      utilitiesExpense: entity.utilitiesExpense,
      internetExpense: entity.internetExpense,
      phoneExpense: entity.phoneExpense,
      otherFixedExpense: entity.otherFixedExpense,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'monthlyIncome': monthlyIncome,
        'paymentDate': paymentDate,
        'fixedExpenses': fixedExpenses, // backward compat bagi reader lama
        'emergencyFundPct': emergencyFundPct,
        'createdAt': Timestamp.fromDate(createdAt),
        'rentExpense': rentExpense,
        'utilitiesExpense': utilitiesExpense,
        'internetExpense': internetExpense,
        'phoneExpense': phoneExpense,
        'otherFixedExpense': otherFixedExpense,
      };
}
