import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:penyintas_app/features/onboarding/domain/entities/budget_settings_entity.dart';

class BudgetSettingsModel extends BudgetSettingsEntity {
  const BudgetSettingsModel({
    required super.monthlyIncome,
    required super.paymentDate,
    required super.fixedExpenses,
    required super.emergencyFundPct,
    required super.createdAt,
  });

  factory BudgetSettingsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BudgetSettingsModel(
      monthlyIncome: (data['monthlyIncome'] as num).toInt(),
      paymentDate: (data['paymentDate'] as num).toInt(),
      fixedExpenses: (data['fixedExpenses'] as num).toInt(),
      emergencyFundPct: (data['emergencyFundPct'] as num).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  factory BudgetSettingsModel.fromEntity(BudgetSettingsEntity entity) {
    return BudgetSettingsModel(
      monthlyIncome: entity.monthlyIncome,
      paymentDate: entity.paymentDate,
      fixedExpenses: entity.fixedExpenses,
      emergencyFundPct: entity.emergencyFundPct,
      createdAt: entity.createdAt,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'monthlyIncome': monthlyIncome,
        'paymentDate': paymentDate,
        'fixedExpenses': fixedExpenses,
        'emergencyFundPct': emergencyFundPct,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
