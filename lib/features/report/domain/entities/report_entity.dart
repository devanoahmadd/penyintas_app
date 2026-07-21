import 'package:equatable/equatable.dart';

class ReportEntity extends Equatable {
  const ReportEntity({
    required this.month,
    required this.totalSpent,
    required this.totalIncome,
    required this.netBalance,
    required this.categoryBreakdown,
    required this.dailyAverageSpend,
    required this.topCategory,
    required this.weeklyBreakdown,
    required this.comparedToPreviousMonth,
    required this.hasPreviousMonthData,
    this.aiInsights,
    this.savingTip,
  });

  final DateTime month;
  final int totalSpent;
  final int totalIncome;
  final int netBalance;
  final Map<String, int> categoryBreakdown;
  final double dailyAverageSpend;
  final String? topCategory;
  final List<WeeklySpendEntity> weeklyBreakdown;

  /// null = tidak ada dasar perbandingan (pengeluaran bulan lalu = 0).
  final double? comparedToPreviousMonth;

  /// Ada transaksi apa pun di bulan sebelumnya — pembeda "bulan pertama"
  /// vs "bulan lalu tanpa pengeluaran" (#99).
  final bool hasPreviousMonthData;
  final List<String>? aiInsights;
  final String? savingTip;

  @override
  List<Object?> get props => [
        month,
        totalSpent,
        totalIncome,
        netBalance,
        // Spread entries sorted by key — Map insertion order not guaranteed (#118)
        ...(categoryBreakdown.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key)))
            .map((e) => '${e.key}:${e.value}'),
        dailyAverageSpend,
        topCategory,
        weeklyBreakdown,
        comparedToPreviousMonth,
        hasPreviousMonthData,
        aiInsights,
        savingTip,
      ];

  static const _sentinel = Object();

  ReportEntity copyWith({
    List<String>? aiInsights,
    Object? savingTip = _sentinel,
  }) =>
      ReportEntity(
        month: month,
        totalSpent: totalSpent,
        totalIncome: totalIncome,
        netBalance: netBalance,
        categoryBreakdown: categoryBreakdown,
        dailyAverageSpend: dailyAverageSpend,
        topCategory: topCategory,
        weeklyBreakdown: weeklyBreakdown,
        comparedToPreviousMonth: comparedToPreviousMonth,
        hasPreviousMonthData: hasPreviousMonthData,
        aiInsights: aiInsights ?? this.aiInsights,
        savingTip: identical(savingTip, _sentinel)
            ? this.savingTip
            : savingTip as String?,
      );
}

class WeeklySpendEntity extends Equatable {
  const WeeklySpendEntity({
    required this.weekNumber,
    required this.totalSpent,
  });

  final int weekNumber;
  final int totalSpent;

  @override
  List<Object> get props => [weekNumber, totalSpent];
}
