import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_limit_entity.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_overview_entity.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';
import 'package:penyintas_app/features/budget/domain/usecases/get_budget_overview_usecase.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';

final _settings = BudgetSettingsEntity(
  monthlyIncome: 5000000,
  paymentDate: 25,
  emergencyFundPct: 0.10,
  createdAt: DateTime(2026, 1, 1),
  rentExpense: 1000000,
  utilitiesExpense: 200000,
  internetExpense: 100000,
  phoneExpense: 100000,
  otherFixedExpense: 100000,
);
// totalFixedExpenses = 1_500_000
// emergencyFundMonthly = 500_000
// totalSpendable = 5_000_000 - 1_500_000 - 500_000 = 3_000_000

TransactionEntity _tx(TransactionCategory cat, int amount) => TransactionEntity(
      id: 'tx_${cat.name}_$amount',
      amount: amount,
      category: cat,
      type: TransactionType.expense,
      date: DateTime(2026, 5, 15),
      isFixed: false,
      isSynced: false,
      createdAt: DateTime(2026, 5, 15),
      updatedAt: DateTime(2026, 5, 15),
    );

final _foodLimit = BudgetLimitEntity(
  id: 1,
  category: TransactionCategory.food,
  limitAmount: 1000000,
  cycleType: 'monthly',
  isEnabled: true,
  updatedAt: DateTime(2026, 5, 1),
);

void main() {
  const usecase = GetBudgetOverviewUseCase();

  OverviewParams _params({
    List<BudgetLimitEntity> limits = const [],
    List<TransactionEntity> txns = const [],
    int remainingDays = 10,
  }) =>
      OverviewParams(
        settings: _settings,
        limits: limits,
        currentPeriodTransactions: txns,
        remainingDays: remainingDays,
      );

  test('kalkulasi income allocation benar', () {
    final result = usecase(_params());
    expect(result.monthlyIncome, 5000000);
    expect(result.totalFixedExpenses, 1500000);
    expect(result.emergencyFundMonthly, 500000);
    expect(result.totalSpendable, 3000000);
  });

  test('kategori tanpa limit: hasLimit = false, status = null', () {
    final result = usecase(_params());
    final food = result.categoryItems.firstWhere((i) => i.category == TransactionCategory.food);
    expect(food.hasLimit, false);
    expect(food.status, null);
    expect(food.usagePct, null);
  });

  test('kategori dengan limit dan spending ≤50%: status safe', () {
    final result = usecase(_params(
      limits: [_foodLimit],
      txns: [_tx(TransactionCategory.food, 400000)],
    ));
    final food = result.categoryItems.firstWhere((i) => i.category == TransactionCategory.food);
    expect(food.spentAmount, 400000);
    expect(food.limitAmount, 1000000);
    expect(food.usagePct, closeTo(0.4, 0.001));
    expect(food.status, BudgetStatus.safe);
  });

  test('kategori dengan spending 50–80%: status caution', () {
    final result = usecase(_params(
      limits: [_foodLimit],
      txns: [_tx(TransactionCategory.food, 700000)],
    ));
    final food = result.categoryItems.firstWhere((i) => i.category == TransactionCategory.food);
    expect(food.status, BudgetStatus.caution);
  });

  test('kategori dengan spending >80%: status danger', () {
    final result = usecase(_params(
      limits: [_foodLimit],
      txns: [_tx(TransactionCategory.food, 900000)],
    ));
    final food = result.categoryItems.firstWhere((i) => i.category == TransactionCategory.food);
    expect(food.status, BudgetStatus.danger);
    expect(result.overallStatus, BudgetStatus.danger);
  });

  test('disabled limit diperlakukan seperti tidak ada limit', () {
    final disabledLimit = _foodLimit.copyWith(isEnabled: false);
    final result = usecase(_params(
      limits: [disabledLimit],
      txns: [_tx(TransactionCategory.food, 900000)],
    ));
    final food = result.categoryItems.firstWhere((i) => i.category == TransactionCategory.food);
    expect(food.hasLimit, false);
    expect(result.overallStatus, BudgetStatus.safe);
  });
}
