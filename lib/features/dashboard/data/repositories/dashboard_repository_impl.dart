import 'package:dartz/dartz.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/utils/date_helper.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:penyintas_app/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:penyintas_app/features/dashboard/domain/usecases/calculate_days_to_live_usecase.dart';
import 'package:penyintas_app/features/onboarding/domain/entities/budget_settings_entity.dart';
import 'package:penyintas_app/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/domain/repositories/transaction_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({
    required TransactionRepository transactionRepository,
    required OnboardingRepository onboardingRepository,
    required CalculateDaysToLiveUseCase calculateDtl,
  })  : _transactions = transactionRepository,
        _onboarding = onboardingRepository,
        _calcDtl = calculateDtl;

  final TransactionRepository _transactions;
  final OnboardingRepository _onboarding;
  final CalculateDaysToLiveUseCase _calcDtl;

  // Cache settings — jarang berubah, tidak perlu fetch setiap stream event (#33)
  BudgetSettingsEntity? _cachedSettings;

  void invalidateSettingsCache() => _cachedSettings = null;

  static void _logError(Object e, StackTrace stack) {
    try {
      FirebaseCrashlytics.instance.recordError(e, stack);
    } catch (_) {}
  }

  @override
  Stream<Either<Failure, DashboardEntity>> watchDashboard() async* {
    await for (final todayResult in _transactions.watchTodayTransactions()) {
      try {
        final todayTxns = todayResult.fold((l) => <TransactionEntity>[], (r) => r);

        _cachedSettings ??= (await _onboarding.getBudgetSettings()).fold(
          (_) => null,
          (s) => s,
        );
        final settings = _cachedSettings;

        if (settings == null) {
          yield const Left(CacheFailure('Pengaturan anggaran tidak ditemukan.'));
          continue;
        }

        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
        final sevenDaysAgo = now.subtract(const Duration(days: 7));

        // #36 — parallelise dua DB query yang independen
        final [monthResult, last7Result] = await Future.wait([
          _transactions.getTransactions(from: monthStart, to: monthEnd),
          _transactions.getTransactions(from: sevenDaysAgo, to: now),
        ]);

        final monthTxns = monthResult.fold((l) => <TransactionEntity>[], (r) => r);
        final last7Txns = last7Result.fold((l) => <TransactionEntity>[], (r) => r);

        yield Right<Failure, DashboardEntity>(_compute(
          settings: settings,
          todayTxns: todayTxns,
          monthTxns: monthTxns,
          last7Txns: last7Txns,
        ));
      } catch (e, stack) {
        _logError(e, stack);
        yield const Left(UnknownFailure());
      }
    }
  }

  DashboardEntity _compute({
    required BudgetSettingsEntity settings,
    required List<TransactionEntity> todayTxns,
    required List<TransactionEntity> monthTxns,
    required List<TransactionEntity> last7Txns,
  }) {
    final remainingDays = remainingDaysInCycle(settings.paymentDate);
    // #38: fallback ke panjang siklus penuh berikutnya, bukan hardcode 30
    final effectiveDays = remainingDays > 0 ? remainingDays : daysInCycle(settings.paymentDate);

    final emergencyFund =
        (settings.monthlyIncome * settings.emergencyFundPct).round();
    final totalMonthlyBudget =
        settings.monthlyIncome - settings.fixedExpenses - emergencyFund;
    final safeMonthlyBudget = totalMonthlyBudget < 0 ? 0 : totalMonthlyBudget;

    final dailyBudget = (safeMonthlyBudget / effectiveDays).floor();

    final spentToday = todayTxns
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);

    // #25: exclude kategori fixed — sudah diwakili oleh settings.fixedExpenses di formula budget
    final totalSpentThisMonth = monthTxns
        .where((t) =>
            t.type == TransactionType.expense &&
            t.category != TransactionCategory.fixed)
        .fold(0, (sum, t) => sum + t.amount);

    final totalRemaining = safeMonthlyBudget - totalSpentThisMonth;

    final last7Expense = last7Txns
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);
    final avgDailySpend = last7Txns.isEmpty
        ? (dailyBudget > 0 ? dailyBudget.toDouble() : 0.0)
        : last7Expense / 7.0;

    final daysToLive = _calcDtl(CalcDtlParams(
      totalRemaining: totalRemaining,
      avgDailySpend: avgDailySpend,
      remainingDays: effectiveDays,
    ));

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
    );
  }
}
