import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_limit_entity.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_overview_entity.dart';
import 'package:penyintas_app/features/budget/presentation/bloc/budget_limits_bloc.dart';
import 'package:penyintas_app/features/budget/presentation/widgets/budget_allocation_ring.dart';
import 'package:penyintas_app/features/budget/presentation/widgets/budget_limit_card.dart';
import 'package:penyintas_app/features/budget/presentation/widgets/category_limit_sheet.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';

class BudgetOverviewPage extends StatelessWidget {
  const BudgetOverviewPage({super.key});

  void _showLimitSheet(
    BuildContext context,
    TransactionCategory category, {
    BudgetLimitEntity? existing,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('Anggaran', style: AppTextStyles.h3),
        backgroundColor: bg,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/budget/edit-settings'),
          ),
        ],
      ),
      body: BlocBuilder<BudgetLimitsBloc, BudgetLimitsState>(
        builder: (context, state) {
          if (state is BudgetLimitsLoading ||
              state is BudgetLimitsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BudgetLimitsError) {
            return Center(
                child: Text(state.message, style: AppTextStyles.body));
          }
          if (state is BudgetLimitsLoaded) {
            return _Loaded(
              overview: state.overview,
              limits: state.limits,
              onAddLimit: (cat) => _showLimitSheet(context, cat),
              onEditLimit: (cat, existing) =>
                  _showLimitSheet(context, cat, existing: existing),
              onDeleteLimit: (id, catName) => context
                  .read<BudgetLimitsBloc>()
                  .add(DeleteBudgetLimit(id: id, categoryName: catName)),
              onToggleLimit: (id, enabled) => context
                  .read<BudgetLimitsBloc>()
                  .add(ToggleBudgetLimit(id: id, isEnabled: enabled)),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.overview,
    required this.limits,
    required this.onAddLimit,
    required this.onEditLimit,
    required this.onDeleteLimit,
    required this.onToggleLimit,
  });

  final BudgetOverviewEntity overview;
  final List<BudgetLimitEntity> limits;
  final void Function(TransactionCategory) onAddLimit;
  final void Function(TransactionCategory, BudgetLimitEntity) onEditLimit;
  final void Function(int, String) onDeleteLimit;
  final void Function(int, bool) onToggleLimit;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final surface =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    final withLimit =
        overview.categoryItems.where((i) => i.hasLimit).toList();
    final withoutLimit =
        overview.categoryItems.where((i) => !i.hasLimit).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        BudgetAllocationRing(overview: overview),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Text('BATAS PER KATEGORI', style: AppTextStyles.caption),
            const Spacer(),
            TextButton.icon(
              onPressed: withoutLimit.isNotEmpty
                  ? () => _showAddPicker(
                      context,
                      withoutLimit.map((i) => i.category).toList())
                  : null,
              icon: const Icon(Icons.add, size: 16),
              label: Text('Tambah', style: AppTextStyles.label),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (withLimit.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text(
              'Belum ada batas kategori.\nTap + Tambah untuk mulai.',
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
        if (withoutLimit.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Kategori tanpa batas',
            style: AppTextStyles.caption.copyWith(color: muted),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: withoutLimit
                .map(
                  (item) => GestureDetector(
                    onTap: () => onAddLimit(item.category),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                          item.category.label, style: AppTextStyles.caption),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  void _showAddPicker(
      BuildContext context, List<TransactionCategory> categories) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: categories
            .map(
              (cat) => ListTile(
                title: Text(cat.label),
                onTap: () {
                  Navigator.of(context).pop();
                  onAddLimit(cat);
                },
              ),
            )
            .toList(),
      ),
    );
  }
}
