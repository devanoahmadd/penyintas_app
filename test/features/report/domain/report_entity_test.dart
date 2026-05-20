import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/report/domain/entities/report_entity.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';

void main() {
  final base = ReportEntity(
    month: DateTime(2026, 5),
    totalSpent: 1000000,
    totalIncome: 3000000,
    netBalance: 2000000,
    categoryBreakdown: const {TransactionCategory.food: 500000},
    dailyAverageSpend: 33333.0,
    topCategory: TransactionCategory.food,
    weeklyBreakdown: const [],
    comparedToPreviousMonth: 0.1,
    aiInsights: ['Insight A'],
    savingTip: 'Original tip',
  );

  group('ReportEntity.copyWith — sentinel pattern', () {
    test('copyWith() with no args preserves all fields', () {
      final copy = base.copyWith();
      expect(copy.savingTip, equals('Original tip'));
      expect(copy.aiInsights, equals(['Insight A']));
    });

    test('copyWith(savingTip: null) sets savingTip to null', () {
      final copy = base.copyWith(savingTip: null);
      expect(copy.savingTip, isNull);
    });

    test('copyWith(savingTip: "new") updates savingTip', () {
      final copy = base.copyWith(savingTip: 'New tip');
      expect(copy.savingTip, equals('New tip'));
    });

    test('copyWith preserves other fields unchanged', () {
      final copy = base.copyWith(savingTip: 'Changed');
      expect(copy.month, equals(base.month));
      expect(copy.totalSpent, equals(base.totalSpent));
      expect(copy.totalIncome, equals(base.totalIncome));
      expect(copy.netBalance, equals(base.netBalance));
      expect(copy.categoryBreakdown, equals(base.categoryBreakdown));
      expect(copy.aiInsights, equals(base.aiInsights));
    });

    test('entity with null savingTip: copyWith() still returns null', () {
      final noTip = base.copyWith(savingTip: null);
      final copy = noTip.copyWith();
      expect(copy.savingTip, isNull);
    });
  });
}
