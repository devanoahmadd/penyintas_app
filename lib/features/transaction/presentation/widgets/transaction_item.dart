import 'package:flutter/material.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';

class TransactionItem extends StatelessWidget {
  const TransactionItem({
    super.key,
    required this.transaction,
    this.onDelete,
  });

  final TransactionEntity transaction;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpense = transaction.type == TransactionType.expense;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        color: AppColors.warn,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppSpacing.md),
              ),
              child: Icon(
                _categoryIcon(transaction.category),
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.note ??
                        _categoryLabel(transaction.category),
                    style: AppTextStyles.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _categoryLabel(transaction.category).toUpperCase(),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isExpense ? '−' : '+'} ${formatRupiah(transaction.amount)}',
                  style: AppTextStyles.label.copyWith(
                    color: isExpense ? AppColors.warn : AppColors.success,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (!transaction.isSynced)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 3),
                    decoration: const BoxDecoration(
                      color: AppColors.caution,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static IconData _categoryIcon(TransactionCategory cat) {
    switch (cat) {
      case TransactionCategory.food: return Icons.restaurant_outlined;
      case TransactionCategory.transport: return Icons.directions_bus_outlined;
      case TransactionCategory.campus: return Icons.school_outlined;
      case TransactionCategory.data: return Icons.wifi_outlined;
      case TransactionCategory.shopping: return Icons.shopping_bag_outlined;
      case TransactionCategory.fixed: return Icons.home_outlined;
      case TransactionCategory.income: return Icons.arrow_downward_rounded;
      case TransactionCategory.other: return Icons.more_horiz_rounded;
    }
  }

  static String _categoryLabel(TransactionCategory cat) {
    switch (cat) {
      case TransactionCategory.food: return 'Makan';
      case TransactionCategory.transport: return 'Transport';
      case TransactionCategory.campus: return 'Kampus';
      case TransactionCategory.data: return 'Data/Internet';
      case TransactionCategory.shopping: return 'Belanja';
      case TransactionCategory.fixed: return 'Tetap';
      case TransactionCategory.income: return 'Pemasukan';
      case TransactionCategory.other: return 'Lainnya';
    }
  }
}
