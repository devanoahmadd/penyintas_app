import 'package:equatable/equatable.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';

enum BudgetStatus { safe, caution, danger }

class DashboardEntity extends Equatable {
  const DashboardEntity({
    required this.dailyBudget,
    required this.spentToday,
    required this.remainingToday,
    required this.totalMonthlyBudget,
    required this.totalSpentThisMonth,
    required this.totalRemaining,
    required this.daysToLive,
    required this.remainingDays,
    required this.avgDailySpend,
    required this.status,
    required this.lastUpdated,
    required this.todayTransactions,
    required this.emergencyFundMonthly,
  });

  final int dailyBudget;
  final int spentToday;
  final int remainingToday;
  final int totalMonthlyBudget;
  final int totalSpentThisMonth;
  final int totalRemaining;
  final int daysToLive;
  final int remainingDays;
  final double avgDailySpend;
  final BudgetStatus status;
  final DateTime lastUpdated;
  final List<TransactionEntity> todayTransactions;
  // Cicilan bulanan ke dana darurat (income × emergencyFundPct)
  final int emergencyFundMonthly;

  @override
  List<Object> get props => [
        dailyBudget,
        spentToday,
        remainingToday,
        totalMonthlyBudget,
        totalSpentThisMonth,
        totalRemaining,
        daysToLive,
        remainingDays,
        avgDailySpend,
        status,
        todayTransactions, // lastUpdated sengaja tidak di-include — bukan equality signal
        emergencyFundMonthly,
      ];
}
