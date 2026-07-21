import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/category_metadata.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_cycle.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_limit_entity.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';
import 'package:penyintas_app/widgets/common/primary_button.dart';

// ── Main sheet ────────────────────────────────────────────────────────────────

/// Bottom sheet to add or edit a per-category spending limit.
///
/// Caller must set [backgroundColor: Colors.transparent] on [showModalBottomSheet].
/// Nominal input opens a numpad sub-sheet (same pattern as AddTransactionSheet).
class CategoryLimitSheet extends StatefulWidget {
  const CategoryLimitSheet({
    super.key,
    required this.category,
    this.existing,
    required this.onSave,
    this.onDelete,
  });

  final CategoryEntity category;
  final BudgetLimitEntity? existing;
  final void Function(BudgetLimitEntity) onSave;
  final void Function(int id, String categoryName)? onDelete;

  @override
  State<CategoryLimitSheet> createState() => _CategoryLimitSheetState();
}

class _CategoryLimitSheetState extends State<CategoryLimitSheet> {
  late int _amount;
  late BudgetCycle _cycleType;
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _amount = e?.limitAmount ?? 0;
    _cycleType = e?.cycleType ?? BudgetCycle.cycle;
    _isEnabled = e?.isEnabled ?? true;
  }

  Future<void> _openNumpad() async {
    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BudgetNumpadSheet(initialAmount: _amount),
    );
    if (result != null && mounted) setState(() => _amount = result);
  }

  void _save() {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal batas yang valid.')),
      );
      return;
    }
    widget.onSave(
      BudgetLimitEntity(
        id: widget.existing?.id ?? 0,
        category: widget.category.slug,
        limitAmount: _amount,
        cycleType: _cycleType,
        isEnabled: _isEnabled,
        updatedAt: DateTime.now(),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Sheet uses page background — cleaner, no surface layer
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final isEdit = widget.existing != null;

    final bottomPad = MediaQuery.of(context).padding.bottom + AppSpacing.xl;
    final l10n = AppLocalizations.of(context);
    final (icon, accentColor) = CategoryMetadata.of(
      widget.category.slug,
      iconSlug: widget.category.isBuiltIn ? null : widget.category.slug,
    );

    return Container(
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
        children: [
          // ── Drag handle ──────────────────────────────────────────────────
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: mutedColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Category chip ────────────────────────────────────────────────
          _CategoryChip(
            label: CategoryMetadata.resolveLabel(widget.category, l10n),
            icon: icon,
            accentColor: accentColor,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Amount display card ──────────────────────────────────────────
          _AmountCard(
            amount: _amount,
            isDark: isDark,
            textColor: textColor,
            mutedColor: mutedColor,
            borderColor: borderColor,
            onTap: _openNumpad,
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Periode hitung ───────────────────────────────────────────────
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Periode hitung',
              style: AppTextStyles.label.copyWith(color: textColor),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _CyclePicker(
            value: _cycleType,
            onChanged: (v) => setState(() => _cycleType = v),
            isDark: isDark,
            borderColor: borderColor,
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Aktif switch (edit only) ──────────────────────────────────────
          if (isEdit) ...[
            Row(
              children: [
                Text('Aktif', style: AppTextStyles.body),
                const Spacer(),
                Switch(
                  value: _isEnabled,
                  activeTrackColor: AppColors.primary,
                  onChanged: (v) => setState(() => _isEnabled = v),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // ── Footer ────────────────────────────────────────────────────────
          Row(
            children: [
              if (isEdit && widget.onDelete != null)
                TextButton(
                  onPressed: () {
                    widget.onDelete!(widget.existing!.id, widget.category.slug);
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Hapus',
                    style: AppTextStyles.label.copyWith(color: AppColors.warn),
                  ),
                ),
              const Spacer(),
              PrimaryButton(label: 'Simpan', width: 120, onPressed: _save),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Category chip ─────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.isDark,
  });

  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final chipBg = accentColor.withValues(alpha: isDark ? 0.15 : 0.08);
    final iconBg = accentColor.withValues(alpha: 0.18);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 17, color: accentColor),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTextStyles.label.copyWith(color: accentColor)),
        ],
      ),
    );
  }
}

// ── Amount display card ───────────────────────────────────────────────────────
// Tappable card — tap opens numpad sub-sheet.
// Uses card surface color for contrast against bg background.

class _AmountCard extends StatelessWidget {
  const _AmountCard({
    required this.amount,
    required this.isDark,
    required this.textColor,
    required this.mutedColor,
    required this.borderColor,
    required this.onTap,
  });

  final int amount;
  final bool isDark;
  final Color textColor;
  final Color mutedColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final displayStr = NumberFormat.decimalPattern('id_ID').format(amount);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: amount > 0 ? AppColors.primary : borderColor,
            width: amount > 0 ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'BATAS PENGELUARAN',
                  style: AppTextStyles.caption.copyWith(color: mutedColor),
                ),
                const Spacer(),
                Icon(Icons.edit_outlined, size: 14, color: mutedColor),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rp',
                  style: AppTextStyles.numericMd.copyWith(
                    color: mutedColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    displayStr,
                    style: AppTextStyles.numericLg.copyWith(
                      fontSize: 38,
                      color: amount == 0 ? mutedColor : textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (amount == 0) ...[
              const SizedBox(height: 4),
              Text(
                'Ketuk untuk isi nominal batas',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary.withValues(alpha: 0.7),
                  letterSpacing: 0,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Numpad sub-sheet ──────────────────────────────────────────────────────────
// Same pattern as _NumpadSheet in AddTransactionSheet.
// Background = bgColor; pops with final int amount.

class _BudgetNumpadSheet extends StatefulWidget {
  const _BudgetNumpadSheet({required this.initialAmount});
  final int initialAmount;

  @override
  State<_BudgetNumpadSheet> createState() => _BudgetNumpadSheetState();
}

class _BudgetNumpadSheetState extends State<_BudgetNumpadSheet> {
  late String _raw;

  @override
  void initState() {
    super.initState();
    _raw = widget.initialAmount == 0 ? '0' : widget.initialAmount.toString();
  }

  void _onKey(String key) {
    setState(() {
      if (key == 'del') {
        _raw = _raw.length <= 1 ? '0' : _raw.substring(0, _raw.length - 1);
      } else if (_raw == '0') {
        _raw = key == '000' ? '0' : key;
      } else {
        final next = _raw + key;
        if (int.tryParse(next) != null && int.parse(next) <= 100000000) {
          _raw = next;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final amount = int.tryParse(_raw) ?? 0;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.sm),
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Amount display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rp',
                  style: AppTextStyles.numericMd.copyWith(
                    color: mutedColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    NumberFormat.decimalPattern('id_ID').format(amount),
                    style: AppTextStyles.numericLg.copyWith(
                      fontSize: 38,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Numpad
          _BudgetNumpad(onKey: _onKey, isDark: isDark),

          // Selesai
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm + bottomPad,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(amount),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: Text(
                  'Selesai',
                  style: AppTextStyles.label.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Numpad widget ─────────────────────────────────────────────────────────────

class _BudgetNumpad extends StatelessWidget {
  const _BudgetNumpad({required this.onKey, required this.isDark});
  final void Function(String) onKey;
  final bool isDark;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['000', '0', 'del'],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: _rows
            .map(
              (row) => Row(
                children: row
                    .map(
                      (key) => Expanded(
                        child: _BudgetNumpadKey(
                          label: key,
                          onTap: () => onKey(key),
                          isDark: isDark,
                        ),
                      ),
                    )
                    .toList(),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _BudgetNumpadKey extends StatelessWidget {
  const _BudgetNumpadKey({
    required this.label,
    required this.onTap,
    required this.isDark,
  });
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        alignment: Alignment.center,
        child: label == 'del'
            ? Icon(Icons.backspace_outlined, size: 20, color: textColor)
            : Text(
                label,
                style: AppTextStyles.h3.copyWith(
                  fontSize: 20,
                  color: textColor,
                ),
              ),
      ),
    );
  }
}

// ── Cycle picker ──────────────────────────────────────────────────────────────

class _CyclePicker extends StatelessWidget {
  const _CyclePicker({
    required this.value,
    required this.onChanged,
    required this.isDark,
    required this.borderColor,
  });

  final BudgetCycle value;
  final void Function(BudgetCycle) onChanged;
  final bool isDark;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: BudgetCycle.values
          .map(
            (cycle) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: cycle != BudgetCycle.values.last ? AppSpacing.sm : 0,
                ),
                child: _PillOption(
                  label: cycle.pickerLabel,
                  sublabel: cycle.pickerSublabel,
                  isActive: value == cycle,
                  isDark: isDark,
                  borderColor: borderColor,
                  onTap: () => onChanged(cycle),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PillOption extends StatelessWidget {
  const _PillOption({
    required this.label,
    required this.sublabel,
    required this.isActive,
    required this.isDark,
    required this.borderColor,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final bool isActive;
  final bool isDark;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isActive ? AppColors.primary : borderColor,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: isActive ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: AppTextStyles.caption.copyWith(
                color: isActive ? Colors.white.withValues(alpha: 0.75) : muted,
                letterSpacing: 0,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
