import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_limit_entity.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';

class CategoryLimitSheet extends StatefulWidget {
  const CategoryLimitSheet({
    super.key,
    required this.category,
    this.existing,
    required this.onSave,
    this.onDelete,
  });

  final TransactionCategory category;
  final BudgetLimitEntity? existing;
  final void Function(BudgetLimitEntity) onSave;
  final void Function(int id, String categoryName)? onDelete;

  @override
  State<CategoryLimitSheet> createState() => _CategoryLimitSheetState();
}

class _CategoryLimitSheetState extends State<CategoryLimitSheet> {
  late TextEditingController _amountCtrl;
  late String _cycleType;
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _amountCtrl = TextEditingController(text: e?.limitAmount.toString() ?? '');
    _cycleType = e?.cycleType ?? 'cycle';
    _isEnabled = e?.isEnabled ?? true;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final amount = int.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal batas yang valid.')),
      );
      return;
    }
    final entity = BudgetLimitEntity(
      id: widget.existing?.id ?? 0,
      category: widget.category,
      limitAmount: amount,
      cycleType: _cycleType,
      isEnabled: _isEnabled,
      updatedAt: DateTime.now(),
    );
    widget.onSave(entity);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final isEdit = widget.existing != null;

    return Container(
      color: surfaceColor,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEdit
                ? 'Edit Batas ${widget.category.label}'
                : 'Tambah Batas ${widget.category.label}',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
            style: AppTextStyles.numericMd,
            decoration: const InputDecoration(
              labelText: 'Batas nominal',
              prefixText: 'Rp ',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Periode hitung', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          _CycleRadio(
            value: _cycleType,
            onChanged: (v) => setState(() => _cycleType = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Text('Aktif', style: AppTextStyles.body),
              const Spacer(),
              Switch(
                value: _isEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _isEnabled = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              if (isEdit && widget.onDelete != null)
                TextButton(
                  onPressed: () {
                    widget.onDelete!(
                        widget.existing!.id, widget.category.name);
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Hapus',
                    style:
                        AppTextStyles.label.copyWith(color: AppColors.warn),
                  ),
                ),
              const Spacer(),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary),
                  child: Text(
                    'Simpan',
                    style:
                        AppTextStyles.label.copyWith(color: Colors.white),
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

class _CycleRadio extends StatelessWidget {
  const _CycleRadio({required this.value, required this.onChanged});
  final String value;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<String>(
      groupValue: value,
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      child: Column(
        children: [
          RadioListTile<String>(
            title: Text('Per siklus gajian', style: AppTextStyles.body),
            subtitle: Text(
              'Reset tiap tanggal gajian',
              style: AppTextStyles.bodySmall,
            ),
            value: 'cycle',
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<String>(
            title: Text('Per bulan kalender', style: AppTextStyles.body),
            subtitle: Text(
              'Reset tiap 1 bulan',
              style: AppTextStyles.bodySmall,
            ),
            value: 'monthly',
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
