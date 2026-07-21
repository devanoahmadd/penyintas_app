import 'package:drift/drift.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/report/domain/entities/report_entity.dart';
import 'package:penyintas_app/features/transaction/data/models/transaction_model.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';

abstract class ReportLocalDatasource {
  Future<ReportEntity> getMonthlyReport(DateTime month);
}

class ReportLocalDatasourceImpl implements ReportLocalDatasource {
  const ReportLocalDatasourceImpl(this._db);
  final AppDatabase _db;

  @override
  Future<ReportEntity> getMonthlyReport(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59, 999);
    final prevStart = DateTime(month.year, month.month - 1, 1);
    final prevEnd = start.subtract(const Duration(milliseconds: 1));

    final rows = await _queryRange(start, end);
    final prevRows = await _queryRange(prevStart, prevEnd);

    final expenses = rows
        .where((t) => t.type == TransactionType.expense)
        .toList();
    final incomeRows = rows
        .where((t) => t.type == TransactionType.income)
        .toList();

    final totalSpent = expenses.fold(0, (s, t) => s + t.amount);
    final totalIncome = incomeRows.fold(0, (s, t) => s + t.amount);

    final breakdown = <String, int>{};
    for (final t in expenses.where((t) => t.category != 'income')) {
      breakdown[t.category] = (breakdown[t.category] ?? 0) + t.amount;
    }

    final topCategory = breakdown.isEmpty
        ? null
        : breakdown.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final elapsedDays = isCurrentMonth ? now.day : end.day;
    final dailyAverageSpend = elapsedDays > 0 ? totalSpent / elapsedDays : 0.0;

    final prevTotalSpent = prevRows
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (s, t) => s + t.amount);
    final hasPreviousMonthData = prevRows.isNotEmpty;
    final double? comparedToPreviousMonth = prevTotalSpent > 0
        ? (totalSpent - prevTotalSpent) / prevTotalSpent
        : null;

    final weekly = List.generate(5, (i) {
      final week = i + 1;
      final weekSpent = expenses
          .where((t) => ((t.date.day - 1) ~/ 7) + 1 == week)
          .fold(0, (s, t) => s + t.amount);
      return WeeklySpendEntity(weekNumber: week, totalSpent: weekSpent);
    });

    return ReportEntity(
      month: month,
      totalSpent: totalSpent,
      totalIncome: totalIncome,
      netBalance: totalIncome - totalSpent,
      categoryBreakdown: breakdown,
      dailyAverageSpend: dailyAverageSpend,
      topCategory: topCategory,
      weeklyBreakdown: weekly,
      comparedToPreviousMonth: comparedToPreviousMonth,
      hasPreviousMonthData: hasPreviousMonthData,
    );
  }

  Future<List<TransactionModel>> _queryRange(DateTime from, DateTime to) async {
    final rows =
        await (_db.select(_db.transactions)..where(
              (t) =>
                  t.date.isBiggerOrEqualValue(from) &
                  t.date.isSmallerOrEqualValue(to),
            ))
            .get();
    return rows.map(TransactionModel.fromDrift).toList();
  }
}
