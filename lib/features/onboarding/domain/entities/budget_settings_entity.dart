import 'package:equatable/equatable.dart';

class BudgetSettingsEntity extends Equatable {
  const BudgetSettingsEntity({
    required this.monthlyIncome,
    required this.paymentDate,
    required this.fixedExpenses,
    required this.emergencyFundPct,
    required this.createdAt,
  });

  final int monthlyIncome;
  final int paymentDate; // 1–31
  final int fixedExpenses;
  final double emergencyFundPct; // 0.05–0.25
  final DateTime createdAt;

  @override
  List<Object> get props => [
        monthlyIncome,
        paymentDate,
        fixedExpenses,
        emergencyFundPct,
        createdAt,
      ];
}
