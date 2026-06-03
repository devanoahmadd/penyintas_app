import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_cycle.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_limit_entity.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';
import 'package:penyintas_app/features/budget/domain/usecases/get_budget_overview_usecase.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';

CategoryEntity _cat(String slug) => CategoryEntity(
  id: 0,
  slug: slug,
  labelKey: 'category_$slug',
  isBuiltIn: true,
  isLimitable: true,
  type: 'expense',
  sortOrder: 0,
);

final _defaultLimitableCategories = [
  _cat('food'), _cat('transport'), _cat('shopping'),
  _cat('health'), _cat('internet'), _cat('other'),
];

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

TransactionEntity _tx(String cat, int amount) => TransactionEntity(
      id: 'tx_${cat}_$amount',
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
  category: 'food',
  limitAmount: 1000000,
  cycleType: BudgetCycle.monthly,
  isEnabled: true,
  updatedAt: DateTime(2026, 5, 1),
);

void main() {
  const usecase = GetBudgetOverviewUseCase();

  OverviewParams params({
    List<BudgetLimitEntity> limits = const [],
    List<TransactionEntity> txns = const [],
    int remainingDays = 10,
    int daysElapsed = 20,
    List<CategoryEntity>? limitableCategories,
  }) =>
      OverviewParams(
        settings: _settings,
        limits: limits,
        currentPeriodTransactions: txns,
        remainingDays: remainingDays,
        daysElapsed: daysElapsed,
        limitableCategories: limitableCategories ?? _defaultLimitableCategories,
      );

  test('kalkulasi income allocation benar', () {
    final result = usecase(params());
    expect(result.monthlyIncome, 5000000);
    expect(result.totalFixedExpenses, 1500000);
    expect(result.emergencyFundMonthly, 500000);
    expect(result.totalSpendable, 3000000);
  });

  test('kategori tanpa limit: hasLimit = false, status = null', () {
    final result = usecase(params());
    final food = result.categoryItems.firstWhere((i) => i.category.slug == 'food');
    expect(food.hasLimit, false);
    expect(food.status, null);
    expect(food.usagePct, null);
  });

  test('kategori dengan limit dan spending ≤50%: status safe', () {
    final result = usecase(params(
      limits: [_foodLimit],
      txns: [_tx('food', 400000)],
    ));
    final food = result.categoryItems.firstWhere((i) => i.category.slug == 'food');
    expect(food.spentAmount, 400000);
    expect(food.limitAmount, 1000000);
    expect(food.usagePct, closeTo(0.4, 0.001));
    expect(food.status, BudgetStatus.safe);
  });

  test('kategori dengan spending 50–80%: status caution', () {
    final result = usecase(params(
      limits: [_foodLimit],
      txns: [_tx('food', 700000)],
    ));
    final food = result.categoryItems.firstWhere((i) => i.category.slug == 'food');
    expect(food.status, BudgetStatus.caution);
  });

  test('kategori dengan spending >80%: status danger', () {
    final result = usecase(params(
      limits: [_foodLimit],
      txns: [_tx('food', 900000)],
    ));
    final food = result.categoryItems.firstWhere((i) => i.category.slug == 'food');
    expect(food.status, BudgetStatus.danger);
    expect(result.overallStatus, BudgetStatus.danger);
  });

  test('disabled limit diperlakukan seperti tidak ada limit', () {
    final disabledLimit = _foodLimit.copyWith(isEnabled: false);
    final result = usecase(params(
      limits: [disabledLimit],
      txns: [_tx('food', 900000)],
    ));
    final food = result.categoryItems.firstWhere((i) => i.category.slug == 'food');
    expect(food.hasLimit, false);
    expect(result.overallStatus, BudgetStatus.safe);
  });

  // ── Pace projection tests ──────────────────────────────────────────────────

  test('pace: projectedDaysLeft null dan paceStatus null saat tidak ada spending', () {
    final result = usecase(params(
      limits: [_foodLimit],
      txns: [],
      daysElapsed: 10,
      remainingDays: 20,
    ));
    final food = result.categoryItems.firstWhere(
        (i) => i.category.slug == 'food');
    expect(food.projectedDaysLeft, null);
    expect(food.paceStatus, null);
  });

  test('pace: paceStatus safe saat projected >= remainingDays', () {
    // spent 250k / 1M, 10 hari, sisa 20 hari
    // dailyBurn = 25k/hari → projected = 750k / 25k = 30 hari >= 20 → safe
    final result = usecase(params(
      limits: [_foodLimit],
      txns: [_tx('food', 250000)],
      daysElapsed: 10,
      remainingDays: 20,
    ));
    final food = result.categoryItems.firstWhere(
        (i) => i.category.slug == 'food');
    expect(food.projectedDaysLeft, 30);
    expect(food.paceStatus, BudgetStatus.safe);
  });

  test('pace: paceStatus caution saat 50% <= projected < remainingDays', () {
    // spent 500k / 1M, 10 hari, sisa 20 hari
    // dailyBurn = 50k/hari → projected = 500k / 50k = 10 hari
    // 10 < 20 tapi 10 >= ceil(20*0.5)=10 → caution
    final result = usecase(params(
      limits: [_foodLimit],
      txns: [_tx('food', 500000)],
      daysElapsed: 10,
      remainingDays: 20,
    ));
    final food = result.categoryItems.firstWhere(
        (i) => i.category.slug == 'food');
    expect(food.projectedDaysLeft, 10);
    expect(food.paceStatus, BudgetStatus.caution);
  });

  test('pace: paceStatus danger saat projected < 50% remainingDays', () {
    // spent 900k / 1M, 10 hari, sisa 20 hari
    // dailyBurn = 90k/hari → projected = 100k / 90k = 1 hari < ceil(10) → danger
    final result = usecase(params(
      limits: [_foodLimit],
      txns: [_tx('food', 900000)],
      daysElapsed: 10,
      remainingDays: 20,
    ));
    final food = result.categoryItems.firstWhere(
        (i) => i.category.slug == 'food');
    expect(food.projectedDaysLeft, 1);
    expect(food.paceStatus, BudgetStatus.danger);
  });

  test('pace: projectedDaysLeft == 0 saat anggaran kategori habis', () {
    // spent == limitAmount → catRemaining = 0 → projectedDaysLeft = 0
    final result = usecase(params(
      limits: [_foodLimit],
      txns: [_tx('food', 1000000)],
      daysElapsed: 10,
      remainingDays: 20,
    ));
    final food = result.categoryItems.firstWhere(
        (i) => i.category.slug == 'food');
    expect(food.projectedDaysLeft, 0);
    expect(food.paceStatus, BudgetStatus.danger);
  });

  test('pace: paceStatus null saat remainingDays == 0 (edge case bulan pendek)', () {
    final result = usecase(params(
      limits: [_foodLimit],
      txns: [_tx('food', 900000)],
      daysElapsed: 1,
      remainingDays: 0,
    ));
    final food = result.categoryItems.firstWhere(
        (i) => i.category.slug == 'food');
    expect(food.paceStatus, null);
    expect(result.paceStatus, null);
  });

  test('pace: entity-level dailyBurnRate dan projectedOperationalDays', () {
    // totalSpendable = 3_000_000
    // spent 300k, 10 hari elapsed, 20 hari remaining
    // dailyBurnRate = 300k/10 = 30k/hari
    // operationalRemaining = 3M - 300k = 2.7M
    // projectedDays = floor(2.7M / 30k) = 90 >= 20 → safe
    final result = usecase(params(
      txns: [_tx('food', 300000)],
      daysElapsed: 10,
      remainingDays: 20,
    ));
    expect(result.dailyBurnRate, closeTo(30000.0, 1.0));
    expect(result.projectedOperationalDays, 90);
    expect(result.paceStatus, BudgetStatus.safe);
  });

  test('pace: entity paceStatus null saat tidak ada spending', () {
    final result = usecase(params(daysElapsed: 10, remainingDays: 20));
    expect(result.dailyBurnRate, 0.0);
    expect(result.projectedOperationalDays, null);
    expect(result.paceStatus, null);
  });
}
