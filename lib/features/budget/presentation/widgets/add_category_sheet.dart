import 'package:flutter/material.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/category_metadata.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';

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

    // Guard against all-special-char names that produce empty slug
    if (slug.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Nama harus mengandung minimal satu huruf atau angka.'),
        ),
      );
      return;
    }

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
    Navigator.of(context).pop(entity);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final textSoft = isDark ? AppColors.textSoftDark : AppColors.textSoftLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final slugs = CategoryMetadata.availableIconSlugs;

    return Container(
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
            // ── Drag handle ────────────────────────────────────────────
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
                  // ── Title ─────────────────────────────────────────────
                  Text(
                    widget.existing == null
                        ? 'Tambah Kategori'
                        : 'Edit Kategori',
                    style: AppTextStyles.h3.copyWith(color: textColor),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Name field ────────────────────────────────────────
                  Text(
                    'Nama Kategori',
                    style: AppTextStyles.label.copyWith(color: textSoft),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _nameController,
                    style: AppTextStyles.body.copyWith(color: textColor),
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'cth. Langganan, Olah Raga...',
                      hintStyle: AppTextStyles.body.copyWith(
                        color: isDark
                            ? AppColors.mutedDark
                            : AppColors.mutedLight,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.all(Radius.circular(AppRadius.md)),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.all(Radius.circular(AppRadius.md)),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.all(Radius.circular(AppRadius.md)),
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

                  // ── Icon picker ───────────────────────────────────────
                  Text(
                    'Ikon',
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
                        onTap: () => setState(
                          () => _selectedIconSlug =
                              selected ? null : slug,
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

                  // ── isLimitable toggle ────────────────────────────────
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Tambahkan ke batas anggaran?',
                      style: AppTextStyles.body.copyWith(color: textColor),
                    ),
                    subtitle: Text(
                      'Aktifkan agar kategori ini bisa diberi limit bulanan.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color:
                            isDark ? AppColors.mutedDark : AppColors.mutedLight,
                      ),
                    ),
                    value: _isLimitable,
                    onChanged: (v) => setState(() => _isLimitable = v),
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Simpan button ─────────────────────────────────────
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(AppRadius.md)),
                        ),
                      ),
                      child: Text(
                        'Simpan',
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
    );
  }
}
