import 'package:flutter/material.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/core/utils/category_metadata.dart';
import 'package:penyintas_app/features/budget/presentation/widgets/add_category_sheet.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/create_category_usecase.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/delete_category_usecase.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/get_categories_usecase.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/update_category_usecase.dart';

class ManageCategoriesPage extends StatefulWidget {
  const ManageCategoriesPage({super.key});

  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  List<CategoryEntity> _builtIn = [];
  List<CategoryEntity> _custom = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await sl<GetCategoriesUseCase>()(const NoParams());

    result.fold(
      (failure) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        });
      },
      (categories) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _builtIn = categories.where((c) => c.isBuiltIn).toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          _custom = categories.where((c) => !c.isBuiltIn).toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        });
      },
    );
  }

  Future<void> _showAddSheet({CategoryEntity? existing}) async {
    final result = await showModalBottomSheet<CategoryEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCategorySheet(existing: existing),
    );
    if (result != null && mounted) {
      if (existing == null) {
        // Mode tambah
        final usecase = sl<CreateCategoryUseCase>();
        final either = await usecase(result);
        either.fold(
          (f) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(f.message)),
              );
            }
          },
          (_) => _loadCategories(),
        );
      } else {
        // Mode edit
        final usecase = sl<UpdateCategoryUseCase>();
        final either = await usecase(result);
        either.fold(
          (f) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(f.message)),
              );
            }
          },
          (_) => _loadCategories(),
        );
      }
    }
  }

  Future<void> _confirmDelete(CategoryEntity category) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.cardDark : AppColors.cardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'Hapus kategori?',
          style: AppTextStyles.h3.copyWith(
            color: isDark ? AppColors.textDark : AppColors.textLight,
          ),
        ),
        content: Text(
          'Kategori "${category.labelOverride ?? category.slug}" akan dihapus permanen.',
          style: AppTextStyles.body.copyWith(
            color:
                isDark ? AppColors.textSoftDark : AppColors.textSoftLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Batal',
              style: AppTextStyles.label.copyWith(
                color:
                    isDark ? AppColors.mutedDark : AppColors.mutedLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Hapus',
              style:
                  AppTextStyles.label.copyWith(color: AppColors.warn),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await sl<DeleteCategoryUseCase>()(
      DeleteCategoryParams(slug: category.slug, isBuiltIn: category.isBuiltIn),
    );

    result.fold(
      (failure) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
          ),
        );
      },
      (_) => _loadCategories(),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
        ),
      ),
    );
  }

  Widget _buildBuiltInItem(CategoryEntity category, AppLocalizations l10n,
      bool isDark) {
    final (icon, _) = CategoryMetadata.of(category.slug, iconSlug: category.iconSlug);
    final label = CategoryMetadata.resolveLabel(category, l10n);
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ListTile(
        minVerticalPadding: AppSpacing.md,
        leading: Icon(icon, color: mutedColor, size: 22),
        title: Text(
          label,
          style: AppTextStyles.body.copyWith(color: textColor),
        ),
        trailing: Icon(
          Icons.lock_outline,
          size: 16,
          color: mutedColor,
        ),
      ),
    );
  }

  Widget _buildCustomItem(CategoryEntity category, AppLocalizations l10n,
      bool isDark) {
    final (icon, _) =
        CategoryMetadata.of(category.slug, iconSlug: category.iconSlug);
    final label = category.labelOverride ?? category.slug;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ListTile(
        minVerticalPadding: AppSpacing.md,
        leading: Icon(icon, color: AppColors.primary, size: 22),
        title: Text(
          label,
          style: AppTextStyles.body.copyWith(color: textColor),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                tooltip: 'Edit kategori',
                icon: Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: mutedColor,
                ),
                onPressed: () => _showAddSheet(existing: category),
              ),
            ),
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                tooltip: 'Hapus kategori',
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: AppColors.warn,
                ),
                onPressed: () => _confirmDelete(category),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomEmptyState(bool isDark) {
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 40,
            color: mutedColor,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Belum ada kategori kustom.',
            style: AppTextStyles.body.copyWith(color: mutedColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Ketuk + untuk membuat kategori baru.',
            style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('Kelola Kategori', style: AppTextStyles.h3),
        backgroundColor: bg,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(),
        backgroundColor: AppColors.primary,
        tooltip: 'Tambah kategori',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      _errorMessage!,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.warn,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(
                    bottom: AppSpacing.xxxl + AppSpacing.xxl,
                  ),
                  children: [
                    // ── Section: Bawaan ─────────────────────────────────
                    _buildSectionHeader('BAWAAN', isDark),
                    ..._builtIn.map(
                      (cat) => _buildBuiltInItem(cat, l10n, isDark),
                    ),

                    // ── Section: Kustom ─────────────────────────────────
                    _buildSectionHeader('KUSTOM', isDark),
                    if (_custom.isEmpty)
                      _buildCustomEmptyState(isDark)
                    else
                      ..._custom.map(
                        (cat) => _buildCustomItem(cat, l10n, isDark),
                      ),
                  ],
                ),
    );
  }
}
