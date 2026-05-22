import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:penyintas_app/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:penyintas_app/features/goal/domain/entities/goal_entity.dart';
import 'package:penyintas_app/features/goal/domain/usecases/load_goals_usecase.dart';
import 'package:penyintas_app/features/goal/presentation/bloc/goal_bloc.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/add_transaction_bloc.dart';
import 'package:penyintas_app/features/transaction/presentation/widgets/add_transaction_sheet.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/widgets/common/app_bottom_nav_bar.dart';
import 'package:penyintas_app/widgets/common/days_to_live_card.dart';
import 'package:penyintas_app/features/survival/presentation/bloc/survival_bloc.dart';
import 'package:penyintas_app/widgets/common/survival_mode_banner.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(const LoadDashboard());
  }

  Future<void> _openAddSheet() async {
    List<GoalEntity> activeGoals;
    final goalState = sl<GoalBloc>().state;
    if (goalState is GoalLoaded) {
      activeGoals = goalState.goals.where((g) => !g.isCompleted).toList();
    } else if (goalState is GoalActionLoading) {
      activeGoals = goalState.goals.where((g) => !g.isCompleted).toList();
    } else {
      // GoalBloc not yet loaded (cold start) — fall back to DB query.
      final result = await sl<LoadGoalsUseCase>().call(const NoParams());
      if (!mounted) return;
      activeGoals = result.fold(
        (_) => <GoalEntity>[],
        (goals) => goals.where((g) => !g.isCompleted).toList(),
      );
    }

    if (!mounted) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (_) => sl<AddTransactionBloc>(),
        child: AddTransactionSheet(activeGoals: activeGoals),
      ),
    );

    if (mounted && saved == true) {
      context.read<DashboardBloc>().add(const DashboardRefreshed());
      sl<GoalBloc>().add(const LoadGoals());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        body: BlocListener<DashboardBloc, DashboardState>(
          listener: (context, state) {
            if (state is DashboardLoaded) {
              context
                  .read<SurvivalBloc>()
                  .add(LoadSurvivalMode(state.entity));
            }
          },
          child: BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              if (state is DashboardLoading || state is DashboardInitial) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is DashboardError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.message, style: AppTextStyles.body),
                      const SizedBox(height: AppSpacing.lg),
                      TextButton(
                        onPressed: () => context
                            .read<DashboardBloc>()
                            .add(const LoadDashboard()),
                        child: Text(context.l10n.retry),
                      ),
                    ],
                  ),
                );
              }
              final entity = (state as DashboardLoaded).entity;
              return _DashboardBody(
                entity: entity,
                onAddTap: _openAddSheet,
                onRefresh: () async => context
                    .read<DashboardBloc>()
                    .add(const DashboardRefreshed()),
                onSeeAllTap: () => context.go('/transactions'),
              );
            },
          ),
        ),
        floatingActionButton: AppNavFab(onTap: _openAddSheet),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: 0,
          onFabTap: _openAddSheet,
        ),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.entity,
    required this.onAddTap,
    required this.onRefresh,
    required this.onSeeAllTap,
  });

  final DashboardEntity entity;
  final VoidCallback onAddTap;
  final Future<void> Function() onRefresh;
  final VoidCallback onSeeAllTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: onRefresh,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: const _DashboardHeader(),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Survival banner hanya saat danger
                  if (entity.status == BudgetStatus.danger) ...[
                    SurvivalModeBanner(
                      totalRemaining: entity.totalRemaining,
                      remainingDays: entity.remainingDays,
                      onTap: () => context.go('/survival/tips'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Days to Live card
                  DaysToLiveCard(
                    daysToLive: entity.daysToLive,
                    remainingDays: entity.remainingDays,
                    status: entity.status,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Saldo Terkini
                  _SaldoCard(entity: entity),
                  const SizedBox(height: AppSpacing.md),

                  // Pengeluaran + Cicilan Darurat (2 mini cards)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _SpendingCard(entity: entity)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: _EmergencyCard(entity: entity)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Transaksi terkini
                  _RecentTransactionsSection(entity: entity, onSeeAllTap: onSeeAllTap),
                  const SizedBox(height: AppSpacing.xxxl),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat pagi,';
    if (hour < 15) return 'Selamat siang,';
    if (hour < 18) return 'Selamat sore,';
    return 'Selamat malam,';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? 'Penyintas';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              initial,
              style: AppTextStyles.label.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
                ),
                Text(
                  name,
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Bell
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: surfaceColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 20,
              color: mutedColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Saldo Terkini card ────────────────────────────────────────────────────

class _SaldoCard extends StatelessWidget {
  const _SaldoCard({required this.entity});
  final DashboardEntity entity;

  String _timestamp(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return 'Per ${dt.day} ${months[dt.month - 1]} ${dt.year} · $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboardSaldoLabel,
            style: AppTextStyles.caption.copyWith(color: mutedColor),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            formatRupiah(entity.totalRemaining),
            style: AppTextStyles.h1.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.0,
              color: textColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _timestamp(entity.lastUpdated),
            style: AppTextStyles.caption.copyWith(
              color: mutedColor,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini card — Pengeluaran Bulan Ini ─────────────────────────────────────

class _SpendingCard extends StatelessWidget {
  const _SpendingCard({required this.entity});
  final DashboardEntity entity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final l10n = AppLocalizations.of(context);

    final pct = entity.totalMonthlyBudget > 0
        ? (entity.totalSpentThisMonth / entity.totalMonthlyBudget)
            .clamp(0.0, 1.0)
        : 0.0;
    final pctInt = (pct * 100).round();

    final barColor = pct <= 0.50
        ? AppColors.primary
        : pct <= 0.80
            ? AppColors.caution
            : AppColors.warn;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboardSpendingLabel,
            style: AppTextStyles.caption.copyWith(
              color: mutedColor,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            formatRupiah(entity.totalSpentThisMonth),
            style: AppTextStyles.label.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: borderColor,
              valueColor: AlwaysStoppedAnimation(barColor),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$pctInt% ${l10n.dashboardFromBudget}',
            style: AppTextStyles.caption.copyWith(
              color: mutedColor,
              fontSize: 11,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini card — Cicilan Darurat ───────────────────────────────────────────

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({required this.entity});
  final DashboardEntity entity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final l10n = AppLocalizations.of(context);

    // Cicilan bulanan relatif terhadap total budget
    final total = entity.totalMonthlyBudget + entity.emergencyFundMonthly;
    final pct = total > 0
        ? (entity.emergencyFundMonthly / total).clamp(0.0, 1.0)
        : 0.0;
    final pctInt = (pct * 100).round();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboardEmergencyLabel,
            style: AppTextStyles.caption.copyWith(
              color: mutedColor,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            formatRupiah(entity.emergencyFundMonthly),
            style: AppTextStyles.label.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: borderColor,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$pctInt% ${l10n.dashboardFromBudget}',
            style: AppTextStyles.caption.copyWith(
              color: mutedColor,
              fontSize: 11,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Transaksi terkini ─────────────────────────────────────────────────────

class _RecentTransactionsSection extends StatelessWidget {
  const _RecentTransactionsSection({
    required this.entity,
    required this.onSeeAllTap,
  });
  final DashboardEntity entity;
  final VoidCallback onSeeAllTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final l10n = AppLocalizations.of(context);
    // #61: take(3) — data sudah di-fallback ke last7 di repository jika hari ini kosong
    final txns = entity.todayTransactions.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              l10n.dashboardRecentTx,
              style: AppTextStyles.h3.copyWith(color: textColor),
            ),
            GestureDetector(
              onTap: onSeeAllTap,
              child: Text(
                l10n.dashboardSeeAll,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (txns.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Text(
              l10n.emptyStateTransactions,
              style:
                  AppTextStyles.bodySmall.copyWith(color: mutedColor),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...txns.map((t) => _TxnRow(transaction: t, isDark: isDark)),
      ],
    );
  }
}

class _TxnRow extends StatelessWidget {
  const _TxnRow({required this.transaction, required this.isDark});
  final TransactionEntity transaction;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final isExpense = transaction.type == TransactionType.expense;

    final h = transaction.date.hour.toString().padLeft(2, '0');
    final m = transaction.date.minute.toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          // Category icon + sync dot (#66)
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                ),
                child: Icon(
                  _categoryIcon(transaction.category),
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              if (!transaction.isSynced)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.caution,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          // Name + category · time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.note ??
                      _categoryLabel(transaction.category),
                  style: AppTextStyles.body.copyWith(color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_categoryLabel(transaction.category)}  $h:$m',
                  style: AppTextStyles.caption.copyWith(
                    color: mutedColor,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Text(
            '${isExpense ? '−' : '+'} ${formatRupiah(transaction.amount)}',
            style: AppTextStyles.label.copyWith(
              color: isExpense ? AppColors.warn : AppColors.success,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _categoryIcon(TransactionCategory cat) {
    switch (cat) {
      case TransactionCategory.food:
        return Icons.restaurant_outlined;
      case TransactionCategory.transport:
        return Icons.directions_bus_outlined;
      case TransactionCategory.shopping:
        return Icons.shopping_bag_outlined;
      case TransactionCategory.health:
        return Icons.favorite_border;
      case TransactionCategory.internet:
        return Icons.wifi_outlined;
      case TransactionCategory.fixed:
        return Icons.home_outlined;
      case TransactionCategory.income:
        return Icons.arrow_downward_rounded;
      case TransactionCategory.other:
        return Icons.more_horiz_rounded;
    }
  }

  static String _categoryLabel(TransactionCategory cat) {
    switch (cat) {
      case TransactionCategory.food:
        return 'Makan';
      case TransactionCategory.transport:
        return 'Transport';
      case TransactionCategory.shopping:
        return 'Belanja';
      case TransactionCategory.health:
        return 'Kesehatan';
      case TransactionCategory.internet:
        return 'Internet';
      case TransactionCategory.fixed:
        return 'Kos';
      case TransactionCategory.income:
        return 'Pemasukan';
      case TransactionCategory.other:
        return 'Lainnya';
    }
  }
}
