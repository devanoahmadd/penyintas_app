import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/app_clock.dart';
import 'package:penyintas_app/core/utils/category_metadata.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/dashboard/presentation/widgets/saldo_card.dart';
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
import 'package:penyintas_app/widgets/common/dashed_border_painter.dart';
import 'package:penyintas_app/widgets/common/email_verification_banner.dart';
import 'package:penyintas_app/features/dashboard/presentation/widgets/bento_feat_tile.dart';
import 'package:penyintas_app/features/dashboard/presentation/widgets/bills_bento_tile.dart';
import 'package:penyintas_app/features/dashboard/presentation/widgets/consistency_bento_tile.dart';
import 'package:penyintas_app/features/dashboard/presentation/widgets/dashboard_skeleton.dart';
import 'package:penyintas_app/features/dashboard/presentation/widgets/financial_slider_widget.dart';
import 'package:penyintas_app/features/budget/presentation/bloc/budget_limits_bloc.dart';
import 'package:penyintas_app/features/streak/presentation/widgets/evening_nudge_card.dart';
import 'package:penyintas_app/features/survival/presentation/bloc/survival_bloc.dart';
import 'package:penyintas_app/features/preferences/presentation/cubit/timezone_reconciliation_cubit.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Jam pengingat harian — dipakai kartu sore (Task 17) untuk ambangnya.
  // Default meniru default kolom `app_settings` (schemaVersion 2): baris bisa
  // TIDAK ADA (mis. sesudah logout, sebelum bootstrap memulihkannya) — itu
  // diperlakukan sebagai "pengingat memakai nilai baku", bukan galat.
  bool _reminderEnabled = true;
  int _reminderHour = 20;
  int _reminderMinute = 0;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<DashboardBloc>();
    // LoadDashboard hanya dikirim jika bloc belum punya data.
    // DashboardBloc adalah singleton — bila DashboardLoaded sudah ada,
    // stream Drift masih berjalan; jangan restart agar tidak flash loading.
    if (bloc.state is DashboardInitial || bloc.state is DashboardError) {
      bloc.add(const LoadDashboard());
    }
    // F5/D3: rekonsiliasi zona waktu non-blocking. Dipanggil post-frame agar
    // app sudah usable saat I/O berjalan. Cubit adalah lazySingleton → check()
    // idempoten (re-entrancy guard internal; snooze dihormati lintas-remount).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TimezoneReconciliationCubit>().check();
      }
    });
    _loadReminderSettings();
  }

  /// Baca jam pengingat dari `app_settings` (Task 17) — pola sama seperti
  /// `SettingsPage._loadReminder`. Baris `id == 1` bisa tidak ada; itu
  /// diperlakukan sebagai nilai baku, bukan galat.
  Future<void> _loadReminderSettings() async {
    final row = await (sl<AppDatabase>().select(
      sl<AppDatabase>().appSettings,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    if (!mounted) return;
    setState(() {
      _reminderEnabled = row?.reminderEnabled ?? true;
      _reminderHour = row?.reminderHour ?? 20;
      _reminderMinute = row?.reminderMinute ?? 0;
    });
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
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        body: BlocListener<DashboardBloc, DashboardState>(
          listener: (context, state) {
            if (state is DashboardLoaded) {
              context.read<SurvivalBloc>().add(LoadSurvivalMode(state.entity));
            }
          },
          child: BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              if (state is DashboardLoading || state is DashboardInitial) {
                return const DashboardSkeleton();
              }
              if (state is DashboardError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.message, style: AppTextStyles.body),
                      const SizedBox(height: AppSpacing.lg),
                      TextButton(
                        onPressed: () => context.read<DashboardBloc>().add(
                          const LoadDashboard(),
                        ),
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
                onRefresh: () async => context.read<DashboardBloc>().add(
                  const DashboardRefreshed(),
                ),
                onSeeAllTap: () => context.go('/transactions'),
                reminderEnabled: _reminderEnabled,
                reminderHour: _reminderHour,
                reminderMinute: _reminderMinute,
              );
            },
          ),
        ),
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
    required this.reminderEnabled,
    required this.reminderHour,
    required this.reminderMinute,
  });

  final DashboardEntity entity;
  final VoidCallback onAddTap;
  final Future<void> Function() onRefresh;
  final VoidCallback onSeeAllTap;

  // Task 17 — jam pengingat harian dari `app_settings`, dioper ke
  // `EveningNudgeCard` sebagai ambang kemunculannya.
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: onRefresh,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // Header
            const SliverToBoxAdapter(
              child: _DashboardHeader(hasNotification: false),
            ),
            // F5/D3: banner rekonsiliasi zona waktu (non-blocking, selalu konfirmasi)
            const SliverToBoxAdapter(child: _TimezoneReconciliationBanner()),
            // B4: banner soft verifikasi email — hilang sendiri saat verified
            const SliverToBoxAdapter(child: EmailVerificationBanner()),
            // Financial slider — no horizontal padding so peek bleeds to edges
            SliverToBoxAdapter(
              child: BlocBuilder<BudgetLimitsBloc, BudgetLimitsState>(
                builder: (context, budgetState) {
                  final overview = budgetState is BudgetLimitsLoaded
                      ? budgetState.overview
                      : null;
                  return FinancialSliderWidget(
                    entity: entity,
                    budgetOverview: overview,
                  );
                },
              ),
            ),
            // Remaining content with horizontal padding
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Saldo Terkini
                  SaldoCard(
                    entity: entity,
                    onDetailTap: () => context.go('/transactions'),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Task 17: kartu sore — bertanya, bukan menagih. Dipasang
                  // DI ATAS grid bento, bukan menggantikan apa pun. Widget
                  // ini sendiri yang menyembunyikan diri (SizedBox.shrink)
                  // bila aturan tampil tidak terpenuhi.
                  EveningNudgeCard(
                    reminderEnabled: reminderEnabled,
                    reminderHour: reminderHour,
                    reminderMinute: reminderMinute,
                    clock: sl<AppClock>(),
                    onRecord: onAddTap,
                  ),

                  // Akses Cepat
                  _SectionHeader(
                    title: l10n.dashboardQuickAccess,
                    action: l10n.dashboardQuickAccessAction,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _BentoGrid(),
                  const SizedBox(height: AppSpacing.lg),

                  // Tip
                  const _TipCard(),
                  const SizedBox(height: AppSpacing.xl),

                  // Transaksi hari ini
                  _SectionHeader(
                    title: l10n.dashboardRecentTx,
                    action: l10n.dashboardSeeAllAction,
                    onActionTap: onSeeAllTap,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _TxCard(entity: entity),
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
  const _DashboardHeader({required this.hasNotification});

  final bool hasNotification;

  String _greeting(BuildContext context) {
    final l10n = context.l10n;
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.dashboardGreetingMorning;
    if (hour < 15) return l10n.dashboardGreetingNoon;
    if (hour < 18) return l10n.dashboardGreetingAfternoon;
    return l10n.dashboardGreetingEvening;
  }

  String _dateStr(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat(
      'EEE, d MMM',
      locale == 'id' ? 'id' : 'en',
    ).format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;

    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? context.l10n.appName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg2,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Row(
        children: [
          // Avatar with subtle brand ring
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? AppColors.shoot.withValues(alpha: 0.35)
                    : AppColors.primary.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: isDark
                  ? AppColors.shoot.withValues(alpha: 0.18)
                  : AppColors.primary.withValues(alpha: 0.10),
              child: Text(
                initial,
                style: AppTextStyles.label.copyWith(
                  color: isDark ? AppColors.shoot : AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
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
                  '${_greeting(context)} · ${_dateStr(context)}',
                  style: AppTextStyles.caption.copyWith(
                    color: mutedColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: AppTextStyles.h3.copyWith(
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Bell
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 20,
                  color: mutedColor,
                ),
              ),
              if (hasNotification)
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.warn,
                      shape: BoxShape.circle,
                      border: Border.all(color: surfaceColor, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TxnRow extends StatelessWidget {
  const _TxnRow({
    required this.transaction,
    required this.isDark,
    this.showDivider = false,
    this.borderColor = AppColors.borderLight,
  });
  final TransactionEntity transaction;
  final bool isDark;
  final bool showDivider;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final isExpense = transaction.type == TransactionType.expense;

    final h = transaction.date.hour.toString().padLeft(2, '0');
    final m = transaction.date.minute.toString().padLeft(2, '0');
    final catLabel = CategoryMetadata.resolveLabelFromSlug(
      transaction.category,
      l10n,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md2,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              // Category icon + sync dot (#66)
              Stack(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                    ),
                    child: Icon(
                      CategoryMetadata.of(transaction.category).$1,
                      color: textColor,
                      size: 18,
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
                      transaction.note ?? catLabel,
                      style: AppTextStyles.bodySmall.copyWith(color: textColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$catLabel  $h:$m',
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
                style: AppTextStyles.numericSm.copyWith(
                  color: isExpense ? AppColors.warn : AppColors.success,
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, thickness: 1, color: borderColor),
      ],
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    this.onActionTap,
  });

  final String title;
  final String action;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(title, style: AppTextStyles.h3.copyWith(color: textColor)),
        GestureDetector(
          onTap: onActionTap,
          child: Text(
            '$action →',
            style: AppTextStyles.label.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

// ── Bento — Quick tile ────────────────────────────────────────────────────

class _BentoQuickTile extends StatelessWidget {
  const _BentoQuickTile({
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          height: 60,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.label.copyWith(color: textColor),
                    ),
                    Text(
                      sub,
                      style: AppTextStyles.caption.copyWith(
                        color: mutedColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bento grid ────────────────────────────────────────────────────────────

class _BentoGrid extends StatelessWidget {
  const _BentoGrid();

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.commonComingSoon),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        // Featured row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: BentoFeatTile(
                bg: AppColors.warn,
                icon: Icons.lightbulb_outline_rounded,
                label: l10n.dashboardBentoSurvivalLabel,
                sub: l10n.dashboardBentoSurvivalSub,
                badge: l10n.dashboardBentoSurvivalBadge,
                onTap: () => context.push('/survival/tips'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm2),
            // Task 7.1: tile hidup, data nyata dari BillsBloc — lihat
            // BillsBentoTile.
            const Expanded(child: BillsBentoTile()),
          ],
        ),
        const SizedBox(height: AppSpacing.sm2),
        // Quick row 1
        Row(
          children: [
            Expanded(
              child: _BentoQuickTile(
                icon: Icons.track_changes_outlined,
                label: l10n.sayaQuickGoals,
                sub: l10n.dashboardBentoGoalsSub,
                onTap: () => context.go('/goals'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm2),
            Expanded(
              child: _BentoQuickTile(
                icon: Icons.qr_code_scanner_outlined,
                label: l10n.dashboardBentoScanLabel,
                sub: l10n.dashboardBentoScanSub,
                onTap: () => _comingSoon(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm2),
        // Quick row 2
        Row(
          children: [
            Expanded(
              child: _BentoQuickTile(
                icon: Icons.people_outline_rounded,
                label: l10n.dashboardBentoSplitLabel,
                sub: l10n.dashboardBentoSplitSub,
                onTap: () => _comingSoon(context),
              ),
            ),
            const SizedBox(width: AppSpacing.sm2),
            // Task 16: tile hidup, angka streak nyata dari StreakBloc —
            // lihat ConsistencyBentoTile.
            const Expanded(child: ConsistencyBentoTile()),
          ],
        ),
      ],
    );
  }
}

// ── Tip card ──────────────────────────────────────────────────────────────

class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.shoot.withValues(alpha: 0.07)
        : AppColors.primary.withValues(alpha: 0.06);
    final borderColor = isDark
        ? AppColors.shoot.withValues(alpha: 0.3)
        : AppColors.primary.withValues(alpha: 0.25);
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return CustomPaint(
      foregroundPainter: DashedBorderPainter(
        color: borderColor,
        radius: AppRadius.md,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md2,
          vertical: AppSpacing.sm2,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lightbulb_outline_rounded,
                size: 13,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${context.l10n.dashboardTipEyebrow}  ',
                      style: AppTextStyles.caption.copyWith(
                        color: mutedColor,
                        letterSpacing: 0.12,
                      ),
                    ),
                    TextSpan(
                      text: context.l10n.dashboardTipText,
                      style: AppTextStyles.bodySmall.copyWith(color: textColor),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Transaction card ──────────────────────────────────────────────────────

class _TxCard extends StatelessWidget {
  const _TxCard({required this.entity});
  final DashboardEntity entity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final txns = entity.todayTransactions.take(3).toList();

    if (txns.isEmpty) {
      final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(
          child: Text(
            context.l10n.dashboardTxEmpty,
            style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < txns.length; i++)
          _TxnRow(
            transaction: txns[i],
            isDark: isDark,
            showDivider: i < txns.length - 1,
            borderColor: borderColor,
          ),
      ],
    );
  }
}

// ── Timezone Reconciliation Banner (F5/D3) ────────────────────────────────
//
// Banner non-modal compact — muncul di bawah header saat zona device beda dari
// yang tersimpan. Tak pernah silent, selalu tunggu konfirmasi user.
// Desain token: card*/border*/text* + aksen primary/shoot — sesuai CLAUDE.md.
// Tenang & menyatu dengan kartu dashboard lain (bukan alert box), tanpa stripe.
//
// Keputusan Temuan-4 (Opsi a): banner tetap tampil, copy netral (tidak janji
// rekalkulasi instan). Efek angka Days-to-Live menyusul di rewrite budget-warning.

class _TimezoneReconciliationBanner extends StatelessWidget {
  const _TimezoneReconciliationBanner();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      TimezoneReconciliationCubit,
      TimezoneReconciliationState
    >(
      builder: (context, state) {
        final prompt = state.prompt;

        // AnimatedSize: collapse smooth saat dismiss (250ms easeOut)
        return AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: prompt == null
              ? const SizedBox.shrink()
              : _BannerContent(prompt: prompt),
        );
      },
    );
  }
}

class _BannerContent extends StatelessWidget {
  const _BannerContent({required this.prompt});
  final TimezonePrompt prompt;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    // Permukaan disamakan dengan kartu dashboard lain (cardLight/cardDark) agar
    // banner menyatu — bukan "alert box". Border hairline + radius lg (lembut).
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    // Aksen tunggal: hijau brand di light, shoot (mint) di dark agar kontras AAA
    // di atas cardDark. Dipakai konsisten untuk chip ikon + tombol tonal.
    final accent = isDark ? AppColors.shoot : AppColors.primary;

    // Border uniform (tanpa stripe non-uniform), jadi borderRadius aman di
    // BoxDecoration — tak perlu ClipRRect & tak memicu crash paint() seperti dulu.
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chip ikon lembut — pola kanonik dashboard (aksen @ alpha rendah).
          // Memberi konteks "zona waktu" tanpa warna peringatan.
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.16 : 0.10),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.public_rounded, size: 18, color: accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Copy pesan — hangat, netral, tidak menakuti
                Text(
                  l10n.tzReconMessage(prompt.deviceLabel),
                  style: AppTextStyles.bodySmall.copyWith(color: textColor),
                ),
                const SizedBox(height: AppSpacing.xs),
                // Zona tersimpan saat ini — informatif, muted
                Text(
                  l10n.tzReconStored(prompt.storedLabel),
                  style: AppTextStyles.caption.copyWith(color: mutedColor),
                ),
                const SizedBox(height: AppSpacing.md),
                // Aksi rata-kanan: sekunder (Nanti) lalu CTA tonal (Pakai zona ini)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _BannerButton(
                      key: const Key('tz_recon_dismiss'),
                      label: l10n.tzReconDismiss,
                      isPrimary: false,
                      isDark: isDark,
                      onTap: () =>
                          context.read<TimezoneReconciliationCubit>().dismiss(),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _BannerButton(
                      key: const Key('tz_recon_confirm'),
                      label: l10n.tzReconConfirm,
                      isPrimary: true,
                      isDark: isDark,
                      onTap: () =>
                          context.read<TimezoneReconciliationCubit>().confirm(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerButton extends StatelessWidget {
  const _BannerButton({
    super.key,
    required this.label,
    required this.isPrimary,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isPrimary;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Aksen hijau lembut: shoot (mint) di dark agar kontras AAA di cardDark.
    final accent = isDark ? AppColors.shoot : AppColors.primary;
    // CTA utama = pill tonal (bg hijau tipis + teks hijau). Sekunder = teks muted.
    final bg = isPrimary
        ? accent.withValues(alpha: isDark ? 0.18 : 0.12)
        : Colors.transparent;
    final fgColor = isPrimary
        ? accent
        : (isDark ? AppColors.mutedDark : AppColors.mutedLight);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        splashColor: accent.withValues(alpha: 0.14),
        highlightColor: accent.withValues(alpha: 0.07),
        child: Container(
          // hit-target min 48dp (Android)
          constraints: const BoxConstraints(minHeight: 48),
          padding: EdgeInsets.symmetric(
            horizontal: isPrimary ? AppSpacing.lg : AppSpacing.md,
            vertical: AppSpacing.sm2,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(color: fgColor, fontSize: 13),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}
