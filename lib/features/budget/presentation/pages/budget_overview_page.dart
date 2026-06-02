import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_limit_entity.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_overview_entity.dart';
import 'package:penyintas_app/features/budget/presentation/bloc/budget_limits_bloc.dart';
import 'package:penyintas_app/features/budget/presentation/widgets/budget_allocation_ring.dart';
import 'package:penyintas_app/features/budget/presentation/widgets/budget_limit_card.dart';
import 'package:penyintas_app/features/budget/presentation/widgets/budget_overview_skeleton.dart';
import 'package:penyintas_app/features/budget/presentation/widgets/budget_summary_card.dart';
import 'package:penyintas_app/features/budget/presentation/widgets/category_limit_sheet.dart'
    show CategoryLimitSheet, categoryIcon;
import 'package:penyintas_app/features/goal/domain/entities/goal_entity.dart';
import 'package:penyintas_app/features/goal/domain/usecases/load_goals_usecase.dart';
import 'package:penyintas_app/features/goal/presentation/bloc/goal_bloc.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/add_transaction_bloc.dart';
import 'package:penyintas_app/features/transaction/presentation/widgets/add_transaction_sheet.dart';
import 'package:penyintas_app/widgets/common/app_bottom_nav_bar.dart';

class BudgetOverviewPage extends StatelessWidget {
  const BudgetOverviewPage({super.key});

  // ── FAB: open add-transaction sheet (same as other tab pages) ────────────
  Future<void> _openAddSheet(BuildContext context) async {
    final goalsResult = await sl<LoadGoalsUseCase>().call(const NoParams());
    final activeGoals = goalsResult.fold(
      (_) => <GoalEntity>[],
      (goals) => goals.where((g) => !g.isCompleted).toList(),
    );

    if (!context.mounted) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (_) => sl<AddTransactionBloc>(),
        child: AddTransactionSheet(activeGoals: activeGoals),
      ),
    );

    if (saved == true && context.mounted) {
      sl<GoalBloc>().add(const LoadGoals());
    }
  }

  // ── Limit sheet ───────────────────────────────────────────────────────────
  void _showLimitSheet(
    BuildContext context,
    TransactionCategory category, {
    BudgetLimitEntity? existing,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryLimitSheet(
        category: category,
        existing: existing,
        onSave: (entity) =>
            context.read<BudgetLimitsBloc>().add(SaveBudgetLimit(entity)),
        onDelete: existing != null
            ? (id, catName) => context
                .read<BudgetLimitsBloc>()
                .add(DeleteBudgetLimit(id: id, categoryName: catName))
            : null,
      ),
    );
  }

  // ── Category picker sheet — icon grid ────────────────────────────────────
  void _showAddPicker(
      BuildContext context, List<TransactionCategory> categories) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final hintColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final bottomPad =
        MediaQuery.of(context).padding.bottom + AppSpacing.xl;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          bottomPad,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: hintColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Pilih Kategori', style: AppTextStyles.h3),
            const SizedBox(height: 4),
            Text(
              'Kategori mana yang ingin kamu batasi?',
              style:
                  AppTextStyles.bodySmall.copyWith(color: hintColor),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Icon grid (2 columns)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 2.0,
              children: categories
                  .map(
                    (cat) => _CategoryGridTile(
                      category: cat,
                      isDark: isDark,
                      onTap: () {
                        Navigator.of(context).pop();
                        _showLimitSheet(context, cat);
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/dashboard');
      },
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Inline header ─────────────────────────────────────────
              _PageHeader(
                onSettingsTap: () => context.push('/budget/edit-settings'),
              ),
              // ── Content ───────────────────────────────────────────────
              Expanded(
                child: BlocBuilder<BudgetLimitsBloc, BudgetLimitsState>(
                  builder: (context, state) {
                    if (state is BudgetLimitsLoading ||
                        state is BudgetLimitsInitial) {
                      return const BudgetOverviewSkeleton();
                    }
                    if (state is BudgetLimitsError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Text(state.message,
                              style: AppTextStyles.body),
                        ),
                      );
                    }
                    if (state is BudgetLimitsLoaded) {
                      return _LoadedBody(
                        overview: state.overview,
                        limits: state.limits,
                        onAddLimit: (cat) => _showLimitSheet(context, cat),
                        onEditLimit: (cat, existing) =>
                            _showLimitSheet(context, cat, existing: existing),
                        onDeleteLimit: (id, catName) => context
                            .read<BudgetLimitsBloc>()
                            .add(DeleteBudgetLimit(
                                id: id, categoryName: catName)),
                        onToggleLimit: (id, enabled) => context
                            .read<BudgetLimitsBloc>()
                            .add(ToggleBudgetLimit(id: id, isEnabled: enabled)),
                        onShowPicker: (cats) => _showAddPicker(context, cats),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: 3,
          onFabTap: () => _openAddSheet(context),
        ),
      ),
    );
  }
}

// ── Inline header ────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onSettingsTap});
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg2,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ANGGARAN',
                style: AppTextStyles.caption.copyWith(color: muted),
              ),
              const SizedBox(height: 2),
              Text('Kelola keuanganmu', style: AppTextStyles.h2),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Atur anggaran',
            onPressed: onSettingsTap,
          ),
        ],
      ),
    );
  }
}

// ── Loaded body ──────────────────────────────────────────────────────────────

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({
    required this.overview,
    required this.limits,
    required this.onAddLimit,
    required this.onEditLimit,
    required this.onDeleteLimit,
    required this.onToggleLimit,
    required this.onShowPicker,
  });

  final BudgetOverviewEntity overview;
  final List<BudgetLimitEntity> limits;
  final void Function(TransactionCategory) onAddLimit;
  final void Function(TransactionCategory, BudgetLimitEntity) onEditLimit;
  final void Function(int, String) onDeleteLimit;
  final void Function(int, bool) onToggleLimit;
  final void Function(List<TransactionCategory>) onShowPicker;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;

    final withLimit =
        overview.categoryItems.where((i) => i.hasLimit).toList();
    final withoutLimit =
        overview.categoryItems.where((i) => !i.hasLimit).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        // 1. Hero summary card
        BudgetSummaryCard(overview: overview),
        const SizedBox(height: AppSpacing.xl),

        // 2. Allocation (flat, no card surface)
        BudgetAllocationRing(overview: overview),
        const SizedBox(height: AppSpacing.xl),

        // 3. Section header
        Text('BATAS PER KATEGORI', style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.md),

        // 4. Limit cards
        if (withLimit.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text(
              'Belum ada batas kategori.\nTambah batas untuk mulai melacak pengeluaran.',
              style: AppTextStyles.body.copyWith(color: muted),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...withLimit.map((item) {
            final entity =
                limits.firstWhere((l) => l.category == item.category);
            return BudgetLimitCard(
              item: item,
              isEnabled: entity.isEnabled,
              onEdit: () => onEditLimit(item.category, entity),
              onDelete: () =>
                  onDeleteLimit(entity.id, entity.category.name),
              onToggle: (v) => onToggleLimit(entity.id, v),
            );
          }),

        // 5. Single add tile
        if (withoutLimit.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _AddLimitTile(
            borderColor: borderColor,
            onTap: () =>
                onShowPicker(withoutLimit.map((i) => i.category).toList()),
          ),
        ],
      ],
    );
  }
}

// ── Category grid tile ───────────────────────────────────────────────────────

class _CategoryGridTile extends StatelessWidget {
  const _CategoryGridTile({
    required this.category,
    required this.isDark,
    required this.onTap,
  });

  final TransactionCategory category;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final (icon, accentColor) = categoryIcon(category);
    final iconBg = accentColor.withValues(alpha: isDark ? 0.20 : 0.12);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        splashColor: accentColor.withValues(alpha: 0.10),
        highlightColor: accentColor.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: accentColor),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  category.label,
                  style: AppTextStyles.label.copyWith(color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add tile ─────────────────────────────────────────────────────────────────

class _AddLimitTile extends StatelessWidget {
  const _AddLimitTile({
    required this.borderColor,
    required this.onTap,
  });

  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Tambah batas kategori',
                style: AppTextStyles.label
                    .copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
