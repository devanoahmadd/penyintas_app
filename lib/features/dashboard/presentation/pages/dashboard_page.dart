import 'dart:math' show pi;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
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

  Widget _buildSpendingRing() {
    final pct = entity.totalMonthlyBudget > 0
        ? (entity.totalSpentThisMonth / entity.totalMonthlyBudget)
            .clamp(0.0, 1.0)
        : 0.0;
    final color = pct <= 0.50
        ? AppColors.primary
        : pct <= 0.80
            ? AppColors.caution
            : AppColors.warn;
    final pctInt = (pct * 100).round();
    final delta = pct <= 0.50
        ? 'On track'
        : pct <= 0.80
            ? 'Mendekati limit'
            : 'Melebihi batas';

    return _RingWidget(
      label: 'PENGELUARAN BULAN INI',
      value: formatRupiah(entity.totalSpentThisMonth),
      sub: '$pctInt% dari anggaran',
      delta: delta,
      pct: pct,
      color: color,
    );
  }

  Widget _buildEmergencyRing() {
    final total = entity.totalMonthlyBudget + entity.emergencyFundMonthly;
    final pct = total > 0
        ? (entity.emergencyFundMonthly / total).clamp(0.0, 1.0)
        : 0.0;
    final pctInt = (pct * 100).round();

    return _RingWidget(
      label: 'ALOKASI DARURAT',
      value: formatRupiah(entity.emergencyFundMonthly),
      sub: '$pctInt% dari total',
      delta: 'On track',
      pct: pct,
      color: AppColors.primaryBright,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: onRefresh,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _DashboardHeader()),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 1. Days to Live
                  DaysToLiveCard(
                    daysToLive: entity.daysToLive,
                    remainingDays: entity.remainingDays,
                    status: entity.status,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 2. Akses Cepat
                  const _SectionHeader(title: 'Akses Cepat', action: 'Atur'),
                  const SizedBox(height: AppSpacing.sm),
                  const _BentoGrid(),
                  const SizedBox(height: AppSpacing.md),

                  // 3. Saldo Terkini
                  _SaldoCard(
                    entity: entity,
                    onDetailTap: () => context.go('/transactions'),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // 4. Ring widgets
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildSpendingRing()),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: _buildEmergencyRing()),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // 5. Tip
                  const _TipCard(),
                  const SizedBox(height: AppSpacing.md),

                  // 6. Transaksi terkini
                  _SectionHeader(
                    title: 'Transaksi terkini',
                    action: 'Lihat semua',
                    onActionTap: onSeeAllTap,
                  ),
                  const SizedBox(height: AppSpacing.sm),
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
          Stack(
            clipBehavior: Clip.none,
            children: [
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
              Positioned(
                top: 8,
                right: 8,
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

// ── Saldo Terkini card ────────────────────────────────────────────────────

class _SaldoCard extends StatefulWidget {
  const _SaldoCard({required this.entity, required this.onDetailTap});
  final DashboardEntity entity;
  final VoidCallback onDetailTap;

  @override
  State<_SaldoCard> createState() => _SaldoCardState();
}

class _SaldoCardState extends State<_SaldoCard> {
  bool _hidden = false;

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
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row + eye toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SALDO TERKINI',
                style: AppTextStyles.caption.copyWith(color: mutedColor),
              ),
              GestureDetector(
                onTap: () => setState(() => _hidden = !_hidden),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    _hidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 14,
                    color: mutedColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Balance amount
          Text(
            _hidden ? 'Rp ••••••' : formatRupiah(widget.entity.totalRemaining),
            style: AppTextStyles.h1.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.0,
              color: textColor,
              fontFeatures:
                  _hidden ? null : const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Timestamp + Detail link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _timestamp(widget.entity.lastUpdated),
                style: AppTextStyles.caption.copyWith(
                  color: mutedColor,
                  letterSpacing: 0,
                ),
              ),
              GestureDetector(
                onTap: widget.onDetailTap,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Detail',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward,
                      size: 11,
                      color: AppColors.primary,
                    ),
                  ],
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
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final isExpense = transaction.type == TransactionType.expense;

    final h = transaction.date.hour.toString().padLeft(2, '0');
    final m = transaction.date.minute.toString().padLeft(2, '0');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: AppSpacing.md,
          ),
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
        ),
        if (showDivider) Divider(height: 1, thickness: 1, color: borderColor),
      ],
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
            style: AppTextStyles.label.copyWith(
              color: AppColors.primary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Bento — Featured tile ─────────────────────────────────────────────────

class _BentoFeatTile extends StatelessWidget {
  const _BentoFeatTile({
    required this.bg,
    required this.icon,
    required this.label,
    required this.sub,
    required this.badge,
    required this.onTap,
  });

  final Color bg;
  final IconData icon;
  final String label;
  final String sub;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 116),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 26, color: Colors.white),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    badge,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      letterSpacing: 0.12,
                      fontFamily: 'JetBrainsMono',
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.h3.copyWith(color: Colors.white)),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: cardColor,
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
                borderRadius: BorderRadius.circular(10),
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
                    style: AppTextStyles.label.copyWith(
                      color: textColor,
                      fontSize: 12,
                    ),
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
    );
  }
}

// ── Bento grid ────────────────────────────────────────────────────────────

class _BentoGrid extends StatelessWidget {
  const _BentoGrid();

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Segera hadir'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Featured row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _BentoFeatTile(
                bg: AppColors.warn,
                icon: Icons.lightbulb_outline_rounded,
                label: 'Survival Mode',
                sub: '3 tips hemat menunggu',
                badge: 'AI',
                onTap: () => context.go('/survival/tips'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _BentoFeatTile(
                bg: AppColors.primary,
                icon: Icons.receipt_long_outlined,
                label: 'Tagihan',
                sub: 'Listrik · 3 hari lagi',
                badge: '2 JT',
                onTap: () => _comingSoon(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Quick row 1
        Row(
          children: [
            Expanded(
              child: _BentoQuickTile(
                icon: Icons.track_changes_outlined,
                label: 'Tujuan',
                sub: '3 aktif',
                onTap: () => context.go('/goals'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _BentoQuickTile(
                icon: Icons.qr_code_scanner_outlined,
                label: 'Scan Struk',
                sub: 'OCR',
                onTap: () => _comingSoon(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Quick row 2
        Row(
          children: [
            Expanded(
              child: _BentoQuickTile(
                icon: Icons.people_outline_rounded,
                label: 'Bagi Tagihan',
                sub: 'Split bill',
                onTap: () => _comingSoon(context),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _BentoQuickTile(
                icon: Icons.emoji_events_outlined,
                label: 'Tantangan',
                sub: 'Mingguan',
                onTap: () => _comingSoon(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Ring widget (donut chart) ──────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.pct,
    required this.color,
    required this.trackColor,
  });

  final double pct;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - 4) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Track
    paint.color = trackColor;
    canvas.drawCircle(center, radius, paint);

    // Arc (starts at top, goes clockwise)
    if (pct > 0) {
      paint.color = color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * pct.clamp(0.0, 1.0),
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.pct != pct || old.color != color || old.trackColor != trackColor;
}

class _RingWidget extends StatelessWidget {
  const _RingWidget({
    required this.label,
    required this.value,
    required this.sub,
    required this.delta,
    required this.pct,
    required this.color,
  });

  final String label;
  final String value;
  final String sub;
  final String delta;
  final double pct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final trackColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final pctInt = (pct * 100).round();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: mutedColor,
              fontSize: 9,
              letterSpacing: 0.1,
              fontFamily: 'JetBrainsMono',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ring + percentage text
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(52, 52),
                      painter: _RingPainter(
                        pct: pct,
                        color: color,
                        trackColor: trackColor,
                      ),
                    ),
                    Text(
                      '$pctInt%',
                      style: AppTextStyles.caption.copyWith(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Value + sub
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: AppTextStyles.label.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: AppSpacing.xs),
          Text(
            delta,
            style: AppTextStyles.caption.copyWith(color: color, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ── Tip card ──────────────────────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rRect);

    const dashLen = 5.0;
    const gapLen = 4.0;
    final dashPath = Path();
    for (final pm in path.computeMetrics()) {
      double dist = 0;
      while (dist < pm.length) {
        dashPath.addPath(pm.extractPath(dist, dist + dashLen), Offset.zero);
        dist += dashLen + gapLen;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

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
      foregroundPainter: _DashedBorderPainter(
        color: borderColor,
        radius: AppRadius.md,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      text: 'TIP HARI INI  ',
                      style: AppTextStyles.caption.copyWith(
                        color: mutedColor,
                        fontSize: 9,
                        letterSpacing: 0.12,
                        fontFamily: 'JetBrainsMono',
                      ),
                    ),
                    TextSpan(
                      text: 'Bawa botol minum — hemat Rp 6.000/hari.',
                      style: AppTextStyles.body.copyWith(
                        color: textColor,
                        fontSize: 12,
                      ),
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
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final txns = entity.todayTransactions.take(3).toList();

    if (txns.isEmpty) {
      final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(
          child: Text(
            'Belum ada transaksi. Catat pengeluaran pertamamu hari ini.',
            style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          for (int i = 0; i < txns.length; i++)
            _TxnRow(
              transaction: txns[i],
              isDark: isDark,
              showDivider: i < txns.length - 1,
              borderColor: borderColor,
            ),
        ],
      ),
    );
  }
}
