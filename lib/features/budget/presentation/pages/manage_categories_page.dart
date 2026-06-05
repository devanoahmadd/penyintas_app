import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/category_metadata.dart';
import 'package:penyintas_app/features/budget/presentation/widgets/add_category_sheet.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/category_bloc.dart';

class ManageCategoriesPage extends StatelessWidget {
  const ManageCategoriesPage({super.key});

  Future<void> _openAddSheet(BuildContext context,
      {CategoryEntity? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<CategoryBloc>(),
        child: AddCategorySheet(existing: existing),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, CategoryEntity category) async {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = CategoryMetadata.resolveLabel(category, l10n);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          l10n.manageCategoriesDeleteTitle,
          style: AppTextStyles.h3.copyWith(
            color: isDark ? AppColors.textDark : AppColors.textLight,
          ),
        ),
        content: Text(
          l10n.manageCategoriesDeleteBody(label),
          style: AppTextStyles.body.copyWith(
            color: isDark ? AppColors.textSoftDark : AppColors.textSoftLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.btnCancel,
              style: AppTextStyles.label.copyWith(
                color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.manageCategoriesDeleteConfirm,
              style: AppTextStyles.label.copyWith(color: AppColors.warn),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    context.read<CategoryBloc>().add(DeleteCategory(category.slug));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(l10n.manageCategoriesTitle, style: AppTextStyles.h3),
        backgroundColor: bg,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddSheet(context),
        backgroundColor: AppColors.primary,
        tooltip: l10n.addCategoryTitle,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocConsumer<CategoryBloc, CategoryState>(
        listenWhen: (previous, current) =>
            (current is CategoryLoaded && current.successType != null) ||
            (current is CategoryError && previous is CategoryActionLoading),
        listener: (context, state) {
          if (state is CategoryLoaded && state.successType != null) {
            final msg = switch (state.successType!) {
              CategorySuccessType.created => l10n.categorySuccessCreated,
              CategorySuccessType.updated => l10n.categorySuccessUpdated,
              CategorySuccessType.deleted => l10n.categorySuccessDeleted,
            };
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg)),
            );
          } else if (state is CategoryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.warn,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CategoryInitial || state is CategoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CategoryError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.message,
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.warn),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextButton(
                      onPressed: () => context
                          .read<CategoryBloc>()
                          .add(const LoadCategories()),
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final categories = state is CategoryLoaded
              ? state.categories
              : (state as CategoryActionLoading).categories;

          final builtIn = categories
              .where((c) => c.isBuiltIn)
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          final custom = categories
              .where((c) => !c.isBuiltIn)
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.only(
                  bottom: AppSpacing.xxxl + AppSpacing.xxl,
                ),
                children: [
                  _SectionHeader(title: l10n.manageCategoriesSectionBuiltIn),
                  ...builtIn.map(
                    (cat) => _BuiltInItem(category: cat, l10n: l10n),
                  ),
                  _SectionHeader(title: l10n.manageCategoriesSectionCustom),
                  if (custom.isEmpty)
                    _EmptyCustomState(l10n: l10n)
                  else
                    ...custom.map(
                      (cat) => _CustomItem(
                        category: cat,
                        onEdit: () => _openAddSheet(context, existing: cat),
                        onDelete: () => _confirmDelete(context, cat),
                      ),
                    ),
                ],
              ),
              if (state is CategoryActionLoading)
                const _LoadingOverlay(),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm,
      ),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
        ),
      ),
    );
  }
}

class _BuiltInItem extends StatelessWidget {
  const _BuiltInItem({required this.category, required this.l10n});
  final CategoryEntity category;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (icon, _) =
        CategoryMetadata.of(category.slug, iconSlug: category.iconSlug);
    final label = CategoryMetadata.resolveLabel(category, l10n);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg, vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ListTile(
        minVerticalPadding: AppSpacing.md,
        leading: Icon(
          icon,
          color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
          size: 22,
        ),
        title: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: isDark ? AppColors.textDark : AppColors.textLight,
          ),
        ),
        trailing: Icon(
          Icons.lock_outline,
          size: 16,
          color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
        ),
      ),
    );
  }
}

class _CustomItem extends StatelessWidget {
  const _CustomItem({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });
  final CategoryEntity category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (icon, _) =
        CategoryMetadata.of(category.slug, iconSlug: category.iconSlug);
    final label = category.labelOverride ?? category.slug;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg, vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ListTile(
        minVerticalPadding: AppSpacing.md,
        leading: Icon(icon, color: AppColors.primary, size: 22),
        title: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: isDark ? AppColors.textDark : AppColors.textLight,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                tooltip: 'Edit kategori',
                icon: Icon(Icons.edit_outlined, size: 20, color: mutedColor),
                onPressed: onEdit,
              ),
            ),
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                tooltip: 'Hapus kategori',
                icon: Icon(Icons.delete_outline, size: 20, color: AppColors.warn),
                onPressed: onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCustomState extends StatelessWidget {
  const _EmptyCustomState({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg, vertical: AppSpacing.xl,
      ),
      child: Column(
        children: [
          Icon(Icons.category_outlined, size: 40, color: mutedColor),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.manageCategoriesEmpty,
            style: AppTextStyles.body.copyWith(color: mutedColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.manageCategoriesEmptyHint,
            style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: Container(
        color: Colors.black.withValues(alpha: 0.1),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
