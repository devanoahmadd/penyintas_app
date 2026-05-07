import 'package:equatable/equatable.dart';

class DailyBudgetResult extends Equatable {
  const DailyBudgetResult({
    required this.dailyBudget,
    required this.totalAvailable,
    required this.emergencyFund,
    required this.remainingDays,
  });

  final int dailyBudget;
  final int totalAvailable; // income - fixedExpenses
  final int emergencyFund;
  final int remainingDays;

  @override
  List<Object> get props => [dailyBudget, totalAvailable, emergencyFund, remainingDays];
}
