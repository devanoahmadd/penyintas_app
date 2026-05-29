import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:penyintas_app/features/dashboard/domain/usecases/calculate_days_to_live_usecase.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';
import 'package:penyintas_app/features/budget/domain/repositories/budget_repository.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/domain/repositories/transaction_repository.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockBudgetRepository extends Mock implements BudgetRepository {}

void main() {
  late MockTransactionRepository mockTxRepo;
  late MockBudgetRepository mockBudget;
  late DashboardRepositoryImpl repo;

  // Settings: income 3_000_000, fixed 500_000, emergency 10% → safeMonthly = 2_200_000
  final settings = BudgetSettingsEntity(
    monthlyIncome: 3000000,
    paymentDate: 1,
    otherFixedExpense: 500000,
    emergencyFundPct: 0.10,
    createdAt: DateTime(2026, 5, 1),
  );

  TransactionEntity makeTxn({
    String id = 'id',
    required int amount,
    required TransactionCategory category,
    TransactionType type = TransactionType.expense,
    DateTime? date,
  }) {
    final d = date ?? DateTime.now();
    return TransactionEntity(
      id: id,
      amount: amount,
      category: category,
      type: type,
      date: d,
      isFixed: false,
      isSynced: false,
      createdAt: d,
      updatedAt: d,
    );
  }

  setUp(() {
    mockTxRepo = MockTransactionRepository();
    mockBudget = MockBudgetRepository();
    repo = DashboardRepositoryImpl(
      transactionRepository: mockTxRepo,
      budgetRepository: mockBudget,
      calculateDtl: const CalculateDaysToLiveUseCase(),
    );

    when(() => mockBudget.getBudgetSettings())
        .thenAnswer((_) async => Right(settings));
    when(() => mockTxRepo.getTransactions(from: any(named: 'from'), to: any(named: 'to')))
        .thenAnswer((_) async => const Right([]));
  });

  group('_compute — totalSpentThisMonth', () {
    test('excludes fixed-category expenses (fix #25)', () async {
      final fixedTxn = makeTxn(id: 'f1', amount: 400000, category: TransactionCategory.fixed);
      final foodTxn = makeTxn(id: 'f2', amount: 50000, category: TransactionCategory.food);

      when(() => mockTxRepo.watchTodayTransactions())
          .thenAnswer((_) => Stream.value(const Right([])));
      when(() => mockTxRepo.getTransactions(from: any(named: 'from'), to: any(named: 'to')))
          .thenAnswer((_) async => Right([fixedTxn, foodTxn]));

      final result = await repo.watchDashboard().first;

      final entity = result.getOrElse(() => throw Exception('Expected Right'));
      expect(entity.totalSpentThisMonth, 50000,
          reason: 'fixed-category txn must be excluded from totalSpentThisMonth');
    });

    test('income-type transactions do not affect totalSpentThisMonth', () async {
      final incomeTxn = makeTxn(id: 'i1', amount: 500000, category: TransactionCategory.income, type: TransactionType.income);
      final foodTxn = makeTxn(id: 'f1', amount: 30000, category: TransactionCategory.food);

      when(() => mockTxRepo.watchTodayTransactions())
          .thenAnswer((_) => Stream.value(const Right([])));
      when(() => mockTxRepo.getTransactions(from: any(named: 'from'), to: any(named: 'to')))
          .thenAnswer((_) async => Right([incomeTxn, foodTxn]));

      final result = await repo.watchDashboard().first;
      final entity = result.getOrElse(() => throw Exception());
      expect(entity.totalSpentThisMonth, 30000);
    });
  });

  group('_compute — totalRemaining', () {
    test('clamps totalRemaining to 0 when over budget', () async {
      // safeMonthlyBudget = 2_200_000; spend 3_000_000 → remaining should be 0
      final bigSpend = makeTxn(id: 'b1', amount: 3000000, category: TransactionCategory.food);

      when(() => mockTxRepo.watchTodayTransactions())
          .thenAnswer((_) => Stream.value(const Right([])));
      when(() => mockTxRepo.getTransactions(from: any(named: 'from'), to: any(named: 'to')))
          .thenAnswer((_) async => Right([bigSpend]));

      final result = await repo.watchDashboard().first;
      final entity = result.getOrElse(() => throw Exception());
      expect(entity.totalRemaining, 0,
          reason: 'totalRemaining must not go negative in entity');
    });
  });

  group('_compute — negative safeMonthlyBudget', () {
    test('clamps safeMonthlyBudget to 0 when fixedExpenses exceed income', () async {
      final overSettings = BudgetSettingsEntity(
        monthlyIncome: 500000,
        paymentDate: 1,
        otherFixedExpense: 600000,
        emergencyFundPct: 0.10,
        createdAt: DateTime(2026, 5, 1),
      );
      when(() => mockBudget.getBudgetSettings())
          .thenAnswer((_) async => Right(overSettings));
      when(() => mockTxRepo.watchTodayTransactions())
          .thenAnswer((_) => Stream.value(const Right([])));

      final result = await repo.watchDashboard().first;
      final entity = result.getOrElse(() => throw Exception());
      expect(entity.totalMonthlyBudget, 0);
      expect(entity.dailyBudget, 0);
    });
  });

  group('_compute — spentToday', () {
    test('sums only expense-type today transactions', () async {
      final expense = makeTxn(id: 'e1', amount: 25000, category: TransactionCategory.food);
      final income = makeTxn(id: 'i1', amount: 100000, category: TransactionCategory.income, type: TransactionType.income);

      when(() => mockTxRepo.watchTodayTransactions())
          .thenAnswer((_) => Stream.value(Right([expense, income])));

      final result = await repo.watchDashboard().first;
      final entity = result.getOrElse(() => throw Exception());
      expect(entity.spentToday, 25000);
    });

    test('todayTransactions list is passed through to entity', () async {
      final txn = makeTxn(id: 'x1', amount: 15000, category: TransactionCategory.food);

      when(() => mockTxRepo.watchTodayTransactions())
          .thenAnswer((_) => Stream.value(Right([txn])));

      final result = await repo.watchDashboard().first;
      final entity = result.getOrElse(() => throw Exception());
      expect(entity.todayTransactions, [txn]);
    });
  });

  group('_compute — avgDailySpend', () {
    test('uses last-7-days sum divided by 7', () async {
      final txns = List.generate(
        7,
        (i) => makeTxn(
          id: 'w$i',
          amount: 70000,
          category: TransactionCategory.food,
          date: DateTime.now().subtract(Duration(days: i)),
        ),
      );

      when(() => mockTxRepo.watchTodayTransactions())
          .thenAnswer((_) => Stream.value(const Right([])));
      when(() => mockTxRepo.getTransactions(from: any(named: 'from'), to: any(named: 'to')))
          .thenAnswer((_) async => Right(txns));

      final result = await repo.watchDashboard().first;
      final entity = result.getOrElse(() => throw Exception());
      expect(entity.avgDailySpend, 70000.0);
    });

    test('falls back to dailyBudget when no last-7-day transactions', () async {
      when(() => mockTxRepo.watchTodayTransactions())
          .thenAnswer((_) => Stream.value(const Right([])));
      // getTransactions returns [] by default from setUp

      final result = await repo.watchDashboard().first;
      final entity = result.getOrElse(() => throw Exception());
      expect(entity.avgDailySpend, entity.dailyBudget.toDouble());
    });
  });

  group('_compute — BudgetStatus', () {
    test('status is safe when remaining > 30% of budget', () async {
      // No spending → remaining = safeMonthlyBudget = 2_200_000 → 100% → safe
      when(() => mockTxRepo.watchTodayTransactions())
          .thenAnswer((_) => Stream.value(const Right([])));

      final result = await repo.watchDashboard().first;
      final entity = result.getOrElse(() => throw Exception());
      expect(entity.status, BudgetStatus.safe);
    });

    test('status is caution when remaining 15–30% of budget', () async {
      // safeMonthly = 2_200_000; spend 1_595_001 → remaining = 604_999 ≈ 27.5% → caution
      final spend = makeTxn(id: 'c1', amount: 1595001, category: TransactionCategory.food);
      when(() => mockTxRepo.watchTodayTransactions())
          .thenAnswer((_) => Stream.value(const Right([])));
      when(() => mockTxRepo.getTransactions(from: any(named: 'from'), to: any(named: 'to')))
          .thenAnswer((_) async => Right([spend]));

      final result = await repo.watchDashboard().first;
      final entity = result.getOrElse(() => throw Exception());
      expect(entity.status, BudgetStatus.caution);
    });

    test('status is danger when remaining < 15% of budget', () async {
      // safeMonthly = 2_200_000; spend 1_871_001 → remaining = 328_999 ≈ 14.9% → danger
      final spend = makeTxn(id: 'd1', amount: 1871001, category: TransactionCategory.food);
      when(() => mockTxRepo.watchTodayTransactions())
          .thenAnswer((_) => Stream.value(const Right([])));
      when(() => mockTxRepo.getTransactions(from: any(named: 'from'), to: any(named: 'to')))
          .thenAnswer((_) async => Right([spend]));

      final result = await repo.watchDashboard().first;
      final entity = result.getOrElse(() => throw Exception());
      expect(entity.status, BudgetStatus.danger);
    });
  });

  group('watchDashboard — error handling', () {
    test('yields CacheFailure when settings fetch fails', () async {
      when(() => mockBudget.getBudgetSettings())
          .thenAnswer((_) async => const Left(CacheFailure('Pengaturan anggaran tidak ditemukan.')));
      when(() => mockTxRepo.watchTodayTransactions())
          .thenAnswer((_) => Stream.value(const Right([])));

      final result = await repo.watchDashboard().first;
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });
}
