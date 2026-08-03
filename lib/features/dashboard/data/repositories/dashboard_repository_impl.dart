import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/utils/date_helper.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/domain/repositories/bill_repository.dart';
import 'package:penyintas_app/features/bills/domain/usecases/calculate_bill_commitments.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:penyintas_app/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:penyintas_app/features/dashboard/domain/usecases/calculate_days_to_live_usecase.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';
import 'package:penyintas_app/features/budget/domain/repositories/budget_repository.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/domain/repositories/transaction_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({
    required TransactionRepository transactionRepository,
    required BudgetRepository budgetRepository,
    required BillRepository billRepository,
    required CalculateDaysToLiveUseCase calculateDtl,
  }) : _transactions = transactionRepository,
       _budget = budgetRepository,
       _bills = billRepository,
       _calcDtl = calculateDtl;

  final TransactionRepository _transactions;
  final BudgetRepository _budget;
  final BillRepository _bills;
  final CalculateDaysToLiveUseCase _calcDtl;

  // Cache settings — jarang berubah, tidak perlu fetch setiap stream event (#33)
  BudgetSettingsEntity? _cachedSettings;

  void invalidateSettingsCache() => _cachedSettings = null;

  static void _logError(Object e, StackTrace stack) {
    try {
      FirebaseCrashlytics.instance.recordError(e, stack);
    } catch (_) {}
  }

  /// Dashboard = gabungan dua sumber realtime: transaksi hari ini DAN tagihan
  /// aktif (P1 §5.1). Dipakai `StreamController` manual, bukan `async*`, karena
  /// `await for` hanya bisa menunggu SATU stream.
  @override
  Stream<Either<Failure, DashboardEntity>> watchDashboard() {
    late StreamController<Either<Failure, DashboardEntity>> controller;
    StreamSubscription<Either<Failure, List<TransactionEntity>>>? txSub;
    StreamSubscription<Either<Failure, List<BillEntity>>>? billSub;

    var todayTxns = <TransactionEntity>[];
    var activeBills = <BillEntity>[];
    // Paritas perilaku lama: emisi pertama menunggu transaksi; bills menyusul.
    var txReady = false;
    // Serialisasi (busy + dirty): burst event di-coalesce, urutan emisi
    // terjamin, dan putaran terakhir SELALU membaca data terbaru.
    var running = false;
    var dirty = false;

    Future<void> recomputeOnce() async {
      if (controller.isClosed) return;
      try {
        _cachedSettings ??= (await _budget.getBudgetSettings()).fold(
          (_) => null,
          (s) => s,
        );
        final settings = _cachedSettings;
        if (settings == null) {
          if (controller.isClosed) return;
          controller.add(
            const Left(CacheFailure('Pengaturan anggaran tidak ditemukan.')),
          );
          return;
        }

        final now = DateTime.now();
        // Satu `now` untuk semua date-helper — hindari divergence di tengah
        // malam (#4). Window siklus berbasis paymentDate (#fase0-sinkron-siklus).
        final cycleBegin = cycleStart(settings.paymentDate, now: now);
        final cycleFinish = cycleEnd(settings.paymentDate, now: now);
        final sevenDaysAgo = now.subtract(const Duration(days: 7));

        // #36 — parallelise dua DB query yang independen
        final [monthResult, last7Result] = await Future.wait([
          _transactions.getTransactions(from: cycleBegin, to: cycleFinish),
          _transactions.getTransactions(from: sevenDaysAgo, to: now),
        ]);
        final monthTxns = monthResult.fold(
          (l) => <TransactionEntity>[],
          (r) => r,
        );
        final last7Txns = last7Result.fold(
          (l) => <TransactionEntity>[],
          (r) => r,
        );

        if (controller.isClosed) return; // cancel bisa terjadi selama await
        // Teruskan `now` yang sama ke _compute agar remainingDaysInCycle
        // konsisten dengan cycleBegin/cycleFinish (fix finding #2).
        controller.add(
          Right(
            _compute(
              settings: settings,
              now: now,
              todayTxns: todayTxns,
              monthTxns: monthTxns,
              last7Txns: last7Txns,
              activeBills: activeBills,
            ),
          ),
        );
      } catch (e, stack) {
        _logError(e, stack);
        if (controller.isClosed) return;
        controller.add(const Left(UnknownFailure()));
      }
    }

    Future<void> recompute() async {
      if (running) {
        dirty = true; // data berubah saat putaran berjalan → ulang setelahnya
        return;
      }
      running = true;
      try {
        do {
          dirty = false;
          await recomputeOnce();
        } while (dirty && !controller.isClosed);
      } finally {
        running = false;
      }
    }

    // Error event salah satu stream sumber → satu Left di stream dashboard.
    // Guard `isClosed` sama seperti jalur add() lainnya.
    void teruskanError(Object e, StackTrace stack) {
      _logError(e, stack);
      if (controller.isClosed) return;
      controller.add(const Left(UnknownFailure()));
    }

    controller = StreamController<Either<Failure, DashboardEntity>>(
      onListen: () {
        txSub = _transactions.watchTodayTransactions().listen(
          (either) {
            todayTxns = either.fold((_) => <TransactionEntity>[], (r) => r);
            txReady = true;
            recompute();
          },
          // Paritas `await for` lama: error event stream sumber merambat ke
          // stream dashboard, JANGAN dibuang ke zone. Tanpa ini stream tak
          // emit, tak error, tak pernah close → BLoC tersangkut
          // DashboardLoading selamanya (spinner abadi tanpa jalur pulih).
          onError: teruskanError,
        );
        // Kontrak calculateTiedMoney: hanya bill ACTIVE — watchActiveBills
        // sudah menjaminnya di datasource.
        billSub = _bills.watchActiveBills().listen((either) {
          activeBills = either.fold((_) => <BillEntity>[], (r) => r);
          if (txReady) recompute();
        }, onError: teruskanError);
      },
      onCancel: () async {
        await txSub?.cancel();
        await billSub?.cancel();
        // In-flight recompute dijaga guard `isClosed` — tidak ada add()
        // yang ter-buffer diam-diam setelah titik ini.
        await controller.close();
      },
    );
    return controller.stream;
  }

  DashboardEntity _compute({
    required BudgetSettingsEntity settings,
    required DateTime now,
    required List<TransactionEntity> todayTxns,
    required List<TransactionEntity> monthTxns,
    required List<TransactionEntity> last7Txns,
    required List<BillEntity> activeBills,
  }) {
    final remainingDays = remainingDaysInCycle(settings.paymentDate, now: now);
    // #38: fallback ke panjang siklus penuh berikutnya, bukan hardcode 30
    final effectiveDays = remainingDays > 0
        ? remainingDays
        : daysInCycle(settings.paymentDate);

    final emergencyFund = (settings.monthlyIncome * settings.emergencyFundPct)
        .round();
    final totalMonthlyBudget =
        settings.monthlyIncome - settings.fixedExpenses - emergencyFund;
    final safeMonthlyBudget = totalMonthlyBudget < 0 ? 0 : totalMonthlyBudget;

    final dailyBudget = (safeMonthlyBudget / effectiveDays).floor();

    // Transaksi tagihan (isFixed) dikecualikan dari semua akumulator
    // pengeluaran — tagihan sudah diwakili settings.fixedExpenses di formula
    // budget, jadi menghitungnya lagi = double-count (spec §7).
    final spentToday = todayTxns
        .where((t) => t.type == TransactionType.expense && !t.isFixed)
        .fold(0, (sum, t) => sum + t.amount);

    // #25 digantikan P1 §4.1: `isFixed` satu-satunya penentu (decoupling penuh) —
    // klausa kategori lama membuang transaksi bill ber-includeAsFixed=false.
    final totalSpentThisMonth = monthTxns
        .where((t) => t.type == TransactionType.expense && !t.isFixed)
        .fold(0, (sum, t) => sum + t.amount);

    final totalRemaining = safeMonthlyBudget - totalSpentThisMonth;

    // P1 §3: PRA-clamp (B2) + today ternormalisasi (satu `now`, aturan #4).
    final commitments = calculateBillCommitments(
      activeBills: activeBills,
      today: startOfDay(now),
      paymentDate: settings.paymentDate,
      totalRemaining: totalRemaining,
      fixedExpenses: settings.fixedExpenses,
    );

    // Transaksi operasional = expense NON-tagihan. Tagihan (isFixed) sudah
    // diwakili settings.fixedExpenses di formula budget — ikut menghitungnya
    // di burn-rate = double-count → DTL jatuh (spec §7).
    final last7Operational = last7Txns
        .where((t) => t.type == TransactionType.expense && !t.isFixed)
        .toList();
    final last7Expense = last7Operational.fold(0, (sum, t) => sum + t.amount);
    // Guard memakai daftar OPERASIONAL (bukan last7Txns mentah): riwayat yang
    // hanya berisi tagihan = tak ada sinyal belanja operasional → fallback
    // konservatif dailyBudget, sama seperti riwayat kosong.
    final avgDailySpend = last7Operational.isEmpty
        ? (dailyBudget > 0 ? dailyBudget.toDouble() : 0.0)
        : last7Expense / 7.0;

    final daysToLive = _calcDtl(
      CalcDtlParams(
        totalRemaining: totalRemaining,
        avgDailySpend: avgDailySpend,
        remainingDays: effectiveDays,
      ),
    );

    final ratio = safeMonthlyBudget > 0
        ? totalRemaining / safeMonthlyBudget
        : 0.0;
    final status = ratio > 0.30
        ? BudgetStatus.safe
        : ratio >= 0.15
        ? BudgetStatus.caution
        : BudgetStatus.danger;

    // #61: fallback ke 3 transaksi terakhir (last7) jika tidak ada transaksi hari ini
    final recentTxns = todayTxns.isNotEmpty
        ? todayTxns
        : last7Txns.take(3).toList();

    return DashboardEntity(
      dailyBudget: dailyBudget,
      spentToday: spentToday,
      remainingToday: dailyBudget - spentToday,
      totalMonthlyBudget: safeMonthlyBudget,
      totalSpentThisMonth: totalSpentThisMonth,
      totalRemaining: totalRemaining < 0 ? 0 : totalRemaining,
      daysToLive: daysToLive,
      remainingDays: effectiveDays,
      avgDailySpend: avgDailySpend,
      status: status,
      lastUpdated: DateTime.now(),
      todayTransactions: recentTxns,
      emergencyFundMonthly: emergencyFund,
      billCommitments: commitments,
    );
  }
}
