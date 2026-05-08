import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:penyintas_app/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/add_transaction_bloc.dart';
import 'package:penyintas_app/features/transaction/presentation/widgets/add_transaction_sheet.dart';
import 'package:penyintas_app/features/transaction/presentation/widgets/transaction_item.dart';
import 'package:penyintas_app/widgets/common/budget_bar.dart';
import 'package:penyintas_app/widgets/common/days_to_live_card.dart';
import 'package:penyintas_app/widgets/common/survival_mode_banner.dart';
import 'package:penyintas_app/core/di/injection_container.dart';

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

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (_) => sl<AddTransactionBloc>(),
        child: const AddTransactionSheet(),
      ),
    ).then((_) {
      if (mounted) {
        context.read<DashboardBloc>().add(const DashboardRefreshed());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
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
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            );
          }
          final entity = (state as DashboardLoaded).entity;
          return _DashboardContent(
            entity: entity,
            onAddTap: _openAddSheet,
          );
        },
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.entity, required this.onAddTap});

  final DashboardEntity entity;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<DashboardBloc>().add(const DashboardRefreshed());
      },
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: false,
            backgroundColor: bgColor,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Image.asset('assets/images/logo-m7.png', width: 28),
            ),
            title: Text('Penyintas', style: AppTextStyles.h3.copyWith(color: textColor)),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.lg),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  child: Icon(
                    Icons.person_outline,
                    size: 20,
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                  ),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSpacing.lg),
                if (entity.status == BudgetStatus.danger)
                  SurvivalModeBanner(
                    totalRemaining: entity.totalRemaining,
                    remainingDays: entity.remainingDays,
                  )
                else
                  _BudgetHeaderCard(entity: entity),
                const SizedBox(height: AppSpacing.lg),
                DaysToLiveCard(daysToLive: entity.daysToLive),
                const SizedBox(height: AppSpacing.lg),
                BudgetBar(
                  spent: entity.totalSpentThisMonth,
                  total: entity.totalMonthlyBudget,
                ),
                const SizedBox(height: AppSpacing.xl),
                _TodaySection(entity: entity),
                const SizedBox(height: AppSpacing.xxxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetHeaderCard extends StatelessWidget {
  const _BudgetHeaderCard({required this.entity});
  final DashboardEntity entity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ANGGARAN HARI INI', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          Text(
            formatRupiah(entity.remainingToday < 0 ? 0 : entity.remainingToday),
            style: AppTextStyles.numericLg.copyWith(
              fontSize: 36,
              color: entity.remainingToday < 0
                  ? AppColors.warn
                  : AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'dari ${formatRupiah(entity.dailyBudget)} · sisa ${entity.remainingDays} hari',
            style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
          ),
        ],
      ),
    );
  }
}

class _TodaySection extends StatelessWidget {
  const _TodaySection({required this.entity});
  final DashboardEntity entity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final txns = entity.todayTransactions.take(3).toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Hari ini', style: AppTextStyles.h3.copyWith(color: textColor)),
            TextButton(
              onPressed: () => context.push('/transactions'),
              child: Text(
                'Lihat semua →',
                style: AppTextStyles.label.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (txns.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Text(
              'Belum ada catatan. Mulai dari satu pengeluaran kecil hari ini.',
              style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...txns.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: TransactionItem(transaction: t, onDelete: null),
              )),
      ],
    );
  }
}
