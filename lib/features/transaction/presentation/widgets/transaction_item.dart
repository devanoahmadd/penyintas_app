import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final isIncome = transaction.type == TransactionType.income;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.warn,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: borderColor),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            if (isIncome) Container(width: 3, color: AppColors.success),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Row(
                  children: [
                    _IconContainer(
                      icon: _categoryIcon(transaction.category),
                      isIncome: isIncome,
                      isDark: isDark,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            transaction.note ??
                                _categoryLabel(transaction.category),
                            style: AppTextStyles.h3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_categoryLabel(transaction.category).toUpperCase()}   ${DateFormat('HH:mm').format(transaction.date)}',
                            style: AppTextStyles.caption.copyWith(
                              color: isDark
                                  ? AppColors.mutedDark
                                  : AppColors.mutedLight,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${isIncome ? '+' : '–'} ${formatRupiah(transaction.amount)}',
                          style: AppTextStyles.label.copyWith(
                            color: isIncome
                                ? AppColors.success
                                : (isDark
                                    ? AppColors.textDark
                                    : AppColors.textLight),
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
            ),
          ],
        ),
      ),
    ),
    );
  }

  static IconData _categoryIcon(TransactionCategory cat) {
    switch (cat) {
      case TransactionCategory.food:
        return Icons.restaurant_outlined;
      case TransactionCategory.transport:
        return Icons.directions_bus_outlined;
      case TransactionCategory.shopping:
        return Icons.shopping_bag_outlined;
      case TransactionCategory.health:
        return Icons.favorite_border;
      case TransactionCategory.internet:
        return Icons.wifi_outlined;
      case TransactionCategory.fixed:
        return Icons.home_outlined;
      case TransactionCategory.income:
        return Icons.arrow_downward_rounded;
      case TransactionCategory.other:
        return Icons.more_horiz_rounded;
    }
  }

  static String _categoryLabel(TransactionCategory cat) {
    switch (cat) {
      case TransactionCategory.food:
        return 'Makan';
      case TransactionCategory.transport:
        return 'Transport';
      case TransactionCategory.shopping:
        return 'Belanja';
      case TransactionCategory.health:
        return 'Kesehatan';
      case TransactionCategory.internet:
        return 'Internet';
      case TransactionCategory.fixed:
        return 'Kos';
      case TransactionCategory.income:
        return 'Pemasukan';
      case TransactionCategory.other:
        return 'Lainnya';
    }
  }
}

class _IconContainer extends StatelessWidget {
  const _IconContainer({
    required this.icon,
    required this.isIncome,
    required this.isDark,
  });

  final IconData icon;
  final bool isIncome;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bgColor = isIncome
        // ignore: deprecated_member_use
        ? AppColors.success.withOpacity(0.15)
        : (isDark ? AppColors.bgDark : AppColors.bgLight);
    final iconColor = isIncome ? AppColors.success : AppColors.primary;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }
}
