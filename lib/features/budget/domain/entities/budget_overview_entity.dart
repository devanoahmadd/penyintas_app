import 'package:equatable/equatable.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_cycle.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';

class BudgetOverviewEntity extends Equatable {
  const BudgetOverviewEntity({
    required this.monthlyIncome,
    required this.totalFixedExpenses,
    required this.emergencyFundMonthly,
    required this.totalSpendable,
    required this.categoryItems,
    required this.totalLimitSet,
    required this.totalSpentInLimited,
    required this.overallStatus,
    required this.remainingDays,
    required this.daysElapsed,
  });

  final int monthlyIncome;
  final int totalFixedExpenses;
  final int emergencyFundMonthly;
  final int totalSpendable;
  final List<CategoryBudgetItem> categoryItems;
  final int totalLimitSet;
  final int totalSpentInLimited;
  final BudgetStatus overallStatus;

  /// Hari tersisa dalam siklus ini.
  final int remainingDays;

  /// Hari yang sudah berjalan dalam siklus ini (minimal 1).
  final int daysElapsed;

  /// Total yang sudah dibelanjakan di semua kategori operasional.
  int get totalOperationalSpent =>
      categoryItems.fold(0, (sum, i) => sum + i.spentAmount);

  /// Sisa anggaran operasional = totalSpendable - totalOperationalSpent (min 0).
  int get operationalRemaining =>
      (totalSpendable - totalOperationalSpent).clamp(0, totalSpendable);

  /// Persentase pemakaian operasional 0.0–1.0.
  double get operationalUsagePct => totalSpendable > 0
      ? (totalOperationalSpent / totalSpendable).clamp(0.0, 1.0)
      : 0.0;

  /// Rata-rata pengeluaran harian dalam siklus ini (Rp/hari).
  /// 0.0 jika belum ada pengeluaran.
  double get dailyBurnRate =>
      daysElapsed > 0 ? totalOperationalSpent / daysElapsed : 0.0;

  /// Estimasi berapa hari lagi saldo operasional bertahan dengan pace sekarang.
  /// null jika belum cukup data (burn rate = 0).
  int? get projectedOperationalDays => dailyBurnRate > 0
      ? (operationalRemaining / dailyBurnRate).floor()
      : null;

  /// Status pace operasional: aman / hati-hati / bahaya.
  /// null jika belum ada data pace atau remainingDays == 0 (edge case bulan pendek).
  BudgetStatus? get paceStatus {
    if (remainingDays <= 0) return null; // siklus berakhir hari ini — pace tak bermakna
    final projected = projectedOperationalDays;
    if (projected == null) return null;
    if (projected >= remainingDays) return BudgetStatus.safe;
    if (projected >= (remainingDays * 0.5).ceil()) return BudgetStatus.caution;
    return BudgetStatus.danger;
  }

  @override
  List<Object> get props => [
        monthlyIncome, totalFixedExpenses, emergencyFundMonthly,
        totalSpendable, categoryItems, totalLimitSet,
        totalSpentInLimited, overallStatus, remainingDays, daysElapsed,
      ];
}

class CategoryBudgetItem extends Equatable {
  const CategoryBudgetItem({
    required this.category,
    required this.spentAmount,
    this.limitAmount,
    this.cycleType,
    this.usagePct,
    this.status,
    this.projectedDaysLeft,
    this.paceStatus,
  });

  final CategoryEntity category;
  final int? limitAmount;
  final BudgetCycle? cycleType;
  final int spentAmount;
  final double? usagePct;
  final BudgetStatus? status;

  /// Estimasi hari sampai anggaran kategori ini habis pada pace sekarang.
  /// null jika tidak ada limit, belum ada data, atau tidak ada pengeluaran.
  final int? projectedDaysLeft;

  /// Status pace kategori ini relatif terhadap sisa hari siklus.
  /// null jika tidak ada data pace.
  final BudgetStatus? paceStatus;

  bool get hasLimit => limitAmount != null;

  @override
  // projectedDaysLeft dan paceStatus sengaja TIDAK dimasukkan ke props:
  // keduanya adalah turunan time-sensitive dari daysElapsed yang berubah
  // setiap hari, dan akan memicu state rebuild meski pengeluaran tidak berubah.
  // Spending equality (category, limitAmount, spentAmount, dll.) sudah cukup.
  List<Object?> get props =>
      [category, limitAmount, cycleType, spentAmount, usagePct, status];
}
