import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/category_metadata.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/category_bloc.dart';

class AddCategorySheet extends StatefulWidget {
  const AddCategorySheet({super.key, this.existing});

  /// null = mode tambah, non-null = mode edit.
  final CategoryEntity? existing;

  @override
  State<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<AddCategorySheet> {
  late final TextEditingController _nameController;
  String? _selectedIconSlug;
  bool _isLimitable = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.labelOverride ?? '');
    _selectedIconSlug = e?.iconSlug;
    _isLimitable = e?.isLimitable ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama kategori tidak boleh kosong.')),
      );
      return;
    }

    final existing = widget.existing;
    final slug = existing?.slug ?? _generateSlug(name);

    if (slug.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama harus mengandung minimal satu huruf atau angka.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final entity = CategoryEntity(
      id: existing?.id ?? 0,
      slug: slug,
      labelOverride: name,
      isBuiltIn: false,
      isLimitable: _isLimitable,
      type: 'expense',
      sortOrder: existing?.sortOrder ?? 100,
      iconSlug: _selectedIconSlug,
    );

    if (existing == null) {
      context.read<CategoryBloc>().add(CreateCategory(entity));
    } else {
      context.read<CategoryBloc>().add(UpdateCategory(entity));
    }
    // Sheet does NOT pop here — BlocListener closes it after success
  }

  String _generateSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final textSoft = isDark ? AppColors.textSoftDark : AppColors.textSoftLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final slugs = CategoryMetadata.availableIconSlugs;

    return BlocListener<CategoryBloc, CategoryState>(
      listener: (context, state) {
        if (!_isSaving) return;
        if (state is CategoryLoaded) {
          Navigator.of(context).pop();
        } else if (state is CategoryError) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.warn,
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xs,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.existing == null
                          ? l10n.addCategoryTitle
                          : l10n.editCategoryTitle,
                      style: AppTextStyles.h3.copyWith(color: textColor),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      l10n.addCategoryNameLabel,
                      style: AppTextStyles.label.copyWith(color: textSoft),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _nameController,
                      style: AppTextStyles.body.copyWith(color: textColor),
                      textCapitalization: TextCapitalization.sentences,
                      enabled: !_isSaving,
                      decoration: InputDecoration(
                        hintText: l10n.addCategoryNameHint,
                        hintStyle: AppTextStyles.body.copyWith(
                          color: isDark
                              ? AppColors.mutedDark
                              : AppColors.mutedLight,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(AppRadius.md),
                          ),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(AppRadius.md),
                          ),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(AppRadius.md),
                          ),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      l10n.addCategoryIconLabel,
                      style: AppTextStyles.label.copyWith(color: textSoft),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: AppSpacing.sm,
                            crossAxisSpacing: AppSpacing.sm,
                            childAspectRatio: 1,
                          ),
                      itemCount: slugs.length,
                      itemBuilder: (ctx, i) {
                        final slug = slugs[i];
                        final icon = CategoryMetadata.iconFromSlug(slug);
                        final selected = _selectedIconSlug == slug;
                        return GestureDetector(
                          onTap: _isSaving
                              ? null
                              : () => setState(
                                  () => _selectedIconSlug = selected
                                      ? null
                                      : slug,
                                ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : (isDark
                                        ? AppColors.surfaceDark
                                        : AppColors.surfaceLight),
                              borderRadius: BorderRadius.all(
                                Radius.circular(AppRadius.md),
                              ),
                            ),
                            child: Icon(
                              icon,
                              size: 22,
                              color: selected
                                  ? Colors.white
                                  : (isDark
                                        ? AppColors.mutedDark
                                        : AppColors.mutedLight),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n.addCategoryLimitableLabel,
                        style: AppTextStyles.body.copyWith(color: textColor),
                      ),
                      subtitle: Text(
                        l10n.addCategoryLimitableSub,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.mutedDark
                              : AppColors.mutedLight,
                        ),
                      ),
                      value: _isLimitable,
                      onChanged: _isSaving
                          ? null
                          : (v) => setState(() => _isLimitable = v),
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withValues(
                        alpha: 0.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.primary.withValues(
                            alpha: 0.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(AppRadius.md),
                            ),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                l10n.btnSave,
                                style: AppTextStyles.label.copyWith(
                                  color: Colors.white,
                                ),
                              ),
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
