import 'package:equatable/equatable.dart';

class BudgetSettingsEntity extends Equatable {
  const BudgetSettingsEntity({
    required this.monthlyIncome,
    required this.paymentDate,
    required this.emergencyFundPct,
    required this.createdAt,
    this.rentExpense = 0,
    this.utilitiesExpense = 0,
    this.internetExpense = 0,
    this.phoneExpense = 0,
    this.otherFixedExpense = 0,
  });

  final int monthlyIncome;
  final int paymentDate; // 1–31
  final double emergencyFundPct; // 0.05–0.25
  final DateTime createdAt;

  // #40 — expense breakdown per kategori
  final int rentExpense;
  final int utilitiesExpense;
  final int internetExpense;
  final int phoneExpense;
  final int otherFixedExpense;

  /// Total pengeluaran tetap — jumlah dari 5 breakdown kategori.
  int get fixedExpenses =>
      rentExpense +
      utilitiesExpense +
      internetExpense +
      phoneExpense +
      otherFixedExpense;

  @override
  List<Object> get props => [
    monthlyIncome,
    paymentDate,
    emergencyFundPct,
    createdAt,
    rentExpense,
    utilitiesExpense,
    internetExpense,
    phoneExpense,
    otherFixedExpense,
  ];
}
