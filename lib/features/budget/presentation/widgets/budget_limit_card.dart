import 'package:flutter/material.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_overview_entity.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/widgets/common/budget_bar.dart';

class BudgetLimitCard extends StatelessWidget {
  const BudgetLimitCard({
    super.key,
    required this.item,
    required this.isEnabled,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final CategoryBudgetItem item;
  final bool isEnabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(bool) onToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final limit = item.limitAmount ?? 0;
    final remaining = (limit - item.spentAmount).clamp(0, limit);
    final cycleLabel =
        item.cycleType == 'monthly' ? 'per bulan' : 'per siklus';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(item.category.label, style: AppTextStyles.h3),
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                  if (v == 'toggle') onToggle(!isEnabled);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(isEnabled ? 'Nonaktifkan' : 'Aktifkan'),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          BudgetBar(spent: item.spentAmount, total: limit),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sisa ${formatRupiah(remaining)}',
                style: AppTextStyles.bodySmall,
              ),
              Text(
                cycleLabel,
                style: AppTextStyles.caption.copyWith(color: muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
