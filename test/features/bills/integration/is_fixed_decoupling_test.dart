// Test integrasi Task 4.3: kunci decoupling `isFixed` + asimetri report vs DTL.
//
// Keputusan yang dikunci di sini (spec §7):
// 1. DTL & limit budget MENGECUALIKAN transaksi isFixed (sudah dikunci di
//    Task 4.1/4.2 — file ini menambah lapis dashboard-feed & budget entity).
// 2. REPORT TETAP MENYERTAKAN transaksi isFixed — laporan bulanan harus
//    menampilkan realita pengeluaran total user, termasuk tagihan.
// 3. Decoupling: filter memakai flag `isFixed`, BUKAN `category == 'fixed'`.
//    Transaksi bisa isFixed=true dengan category apa pun (mis. 'internet').
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';
import 'package:penyintas_app/features/budget/domain/repositories/budget_repository.dart';
import 'package:penyintas_app/features/budget/domain/usecases/get_budget_overview_usecase.dart';
import 'package:penyintas_app/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:penyintas_app/features/dashboard/domain/usecases/calculate_days_to_live_usecase.dart';
import 'package:penyintas_app/features/report/data/datasources/report_local_datasource.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/domain/repositories/transaction_repository.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockBudgetRepository extends Mock implements BudgetRepository {}

/// Helper bersama — bikin [TransactionEntity] tanpa boilerplate id/tanggal.
TransactionEntity _txn({
  required String id,
  required int amount,
  required String category,
  bool isFixed = false,
  TransactionType type = TransactionType.expense,
  DateTime? date,
}) {
  final d = date ?? DateTime(2026, 5, 15);
  return TransactionEntity(
    id: id,
    amount: amount,
    category: category,
    type: type,
    date: d,
    isFixed: isFixed,
    isSynced: false,
    createdAt: d,
    updatedAt: d,
  );
}

CategoryEntity _cat(String slug) => CategoryEntity(
  id: 0,
  slug: slug,
  labelKey: 'category_$slug',
  isBuiltIn: true,
  isLimitable: true,
  type: 'expense',
  sortOrder: 0,
);

void main() {
  // ── Kelompok 1: asimetri report ─────────────────────────────────────────
  group('asimetri report — report MENYERTAKAN transaksi isFixed', () {
    late AppDatabase db;
    late ReportLocalDatasourceImpl datasource;

    final tMonth = DateTime(2025, 11);

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      datasource = ReportLocalDatasourceImpl(db);
    });

    tearDown(() async => db.close());

    Future<void> insertTx({
      required String id,
      required int amount,
      required String category,
      required DateTime date,
      bool isFixed = false,
    }) async {
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              txId: id,
              amount: amount,
              category: category,
              type: TransactionType.expense.name,
              date: date,
              isFixed: Value(isFixed),
              createdAt: date,
              updatedAt: date,
            ),
          );
    }

    // Insert 1 transaksi operasional + 1 tagihan (isFixed=true) di minggu
    // & bulan yang sama, dipakai ulang oleh ketiga test di bawah.
    Future<void> seedOperationalAndBill() async {
      await insertTx(
        id: 'op1',
        amount: 50000,
        category: 'food',
        date: DateTime(2025, 11, 5),
      );
      await insertTx(
        id: 'bill1',
        amount: 800000,
        category: 'internet',
        date: DateTime(2025, 11, 3),
        isFixed: true,
      );
    }

    test(
      'totalSpent menyertakan tagihan isFixed — DISENGAJA (spec §7): '
      'report menampilkan realita pengeluaran total, BERBEDA dari DTL/limit '
      'yang mengecualikan isFixed. Jangan tambahkan filter isFixed di sini.',
      () async {
        await seedOperationalAndBill();

        final report = await datasource.getMonthlyReport(tMonth);

        expect(
          report.totalSpent,
          850000,
          reason:
              'kedua transaksi (operasional 50.000 + tagihan 800.000) harus '
              'masuk — tagihan TIDAK dikecualikan di report',
        );
      },
    );

    test(
      'categoryBreakdown menyertakan kategori tagihan dengan nominal penuh',
      () async {
        await seedOperationalAndBill();

        final report = await datasource.getMonthlyReport(tMonth);

        expect(
          report.categoryBreakdown['internet'],
          800000,
          reason: 'kategori tagihan (internet) harus muncul di pie breakdown',
        );
        expect(report.categoryBreakdown['food'], 50000);
      },
    );

    test('weeklyBreakdown (bar mingguan) menyertakan nominal tagihan', () async {
      await seedOperationalAndBill();

      final report = await datasource.getMonthlyReport(tMonth);

      // Kedua transaksi jatuh di minggu 1 (tanggal 3 & 5 → (day-1)~/7 + 1 = 1).
      expect(
        report.weeklyBreakdown[0].totalSpent,
        850000,
        reason: 'bar minggu 1 harus menyertakan nominal tagihan 800.000',
      );
    });
  });

  // ── Kelompok 2: decoupling murni entity/logika ──────────────────────────
  group('decoupling — isFixed independen dari category', () {
    test('isFixed=true dengan category BUKAN "fixed" tetap valid apa adanya '
        '(mengunci bahwa invariant lama isFixed == (category=="fixed") sudah '
        'diputus secara sadar)', () {
      final tx = _txn(
        id: 'bill-internet',
        amount: 900000,
        category: 'internet',
        isFixed: true,
      );

      expect(tx.isFixed, isTrue);
      expect(tx.category, 'internet');
      expect(tx.category, isNot('fixed'));
    });

    test(
      'isFixed=false dengan category "fixed" juga tetap valid (decoupling '
      'berlaku dua arah — category tidak pernah dipakai untuk infer isFixed)',
      () {
        final tx = _txn(
          id: 'manual-fixed-cat',
          amount: 10000,
          category: 'fixed',
        );

        expect(tx.isFixed, isFalse);
        expect(tx.category, 'fixed');
      },
    );
  });

  // ── FOLD-IN A: dashboard feed vs akumulator (menutup Minor Task 4.1) ────
  group('dashboard: feed transaksi TETAP menampilkan tagihan', () {
    late MockTransactionRepository mockTxRepo;
    late MockBudgetRepository mockBudget;
    late DashboardRepositoryImpl repo;

    final settings = BudgetSettingsEntity(
      monthlyIncome: 3000000,
      paymentDate: 1,
      otherFixedExpense: 500000,
      emergencyFundPct: 0.10,
      createdAt: DateTime(2026, 5, 1),
    );

    setUp(() {
      mockTxRepo = MockTransactionRepository();
      mockBudget = MockBudgetRepository();
      repo = DashboardRepositoryImpl(
        transactionRepository: mockTxRepo,
        budgetRepository: mockBudget,
        calculateDtl: const CalculateDaysToLiveUseCase(),
      );

      when(
        () => mockBudget.getBudgetSettings(),
      ).thenAnswer((_) async => Right(settings));
      when(
        () => mockTxRepo.getTransactions(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => const Right([]));
    });

    test(
      'todayTransactions menyertakan KEDUANYA (operasional + tagihan), '
      'sekaligus spentToday hanya menghitung yang operasional — mengunci: '
      'akumulator finansial mengecualikan, feed tampilan menyertakan',
      () async {
        final operational = _txn(id: 'op1', amount: 30000, category: 'food');
        final bill = _txn(
          id: 'bill1',
          amount: 800000,
          category: 'kos',
          isFixed: true,
        );

        when(
          () => mockTxRepo.watchTodayTransactions(),
        ).thenAnswer((_) => Stream.value(Right([operational, bill])));

        final result = await repo.watchDashboard().first;
        final entity = result.getOrElse(() => throw Exception());

        expect(
          entity.todayTransactions,
          hasLength(2),
          reason:
              'feed dashboard (mis. "Kos Bu Tini sudah dibayar") harus tetap '
              'menampilkan transaksi tagihan, bukan hanya operasional',
        );
        expect(entity.todayTransactions, containsAll([operational, bill]));
        expect(
          entity.spentToday,
          30000,
          reason:
              'spentToday (akumulator finansial) tetap mengecualikan tagihan '
              'walau feed menampilkannya',
        );
      },
    );
  });

  // ── FOLD-IN B: budget entity-level ripple (menutup Minor Task 4.2) ──────
  group('budget: ripple entity-level mengecualikan isFixed', () {
    const usecase = GetBudgetOverviewUseCase();

    final settings = BudgetSettingsEntity(
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

    final limitableCategories = [_cat('food'), _cat('internet'), _cat('other')];

    test('totalOperationalSpent mengecualikan tagihan isFixed walau kategori '
        'tanpa limit — ripple dari filter Task 4.2 merambat ke entity-level '
        'getter, bukan cuma per-kategori dengan limit', () {
      final operational = _txn(
        id: 'op1',
        amount: 100000,
        category: 'food', // tanpa limit (limits: [])
      );
      final bill = _txn(
        id: 'bill1',
        amount: 500000,
        category: 'internet', // juga tanpa limit — isFixed yang mengecualikan
        isFixed: true,
      );

      final result = usecase(
        OverviewParams(
          settings: settings,
          limits: const [],
          currentPeriodTransactions: [operational, bill],
          remainingDays: 10,
          daysElapsed: 20,
          limitableCategories: limitableCategories,
        ),
      );

      expect(
        result.totalOperationalSpent,
        100000,
        reason:
            'tagihan 500.000 (isFixed) harus dikecualikan meski kategori '
            '"internet" tidak punya limit',
      );
      expect(
        result.dailyBurnRate,
        closeTo(100000 / 20, 0.001),
        reason:
            'dailyBurnRate (turunan totalOperationalSpent) juga harus '
            'mengecualikan tagihan',
      );
    });
  });
}
