import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';

// V2 card — no Dismissible/connector here; parent (_V2TxRow) owns those.
class TransactionItem extends StatelessWidget {
  const TransactionItem({
    super.key,
    required this.transaction,
  });

  final TransactionEntity transaction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = transaction.type == TransactionType.income;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final amtColor = isIncome
        ? (isDark ? AppColors.incomeDark : AppColors.success)
        : (isDark ? AppColors.expenseDark : AppColors.warn);
    final amtBg = _amtBg(isDark, isIncome);

    return Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            bottom: BorderSide(color: borderColor, width: 0.8),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: amtBg,
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Icon(_categoryIcon(transaction.category),
                  size: 15, color: amtColor),
            ),
            const SizedBox(width: AppSpacing.sm2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    transaction.note ?? transaction.category.label,
                    style: AppTextStyles.label.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Text(
                        transaction.category.label.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          color: mutedColor,
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                        child: Text('·',
                            // ignore: deprecated_member_use
                            style: TextStyle(color: mutedColor.withOpacity(0.5))),
                      ),
                      Text(
                        DateFormat('HH:mm').format(transaction.date),
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          color: mutedColor,
                        ),
                      ),
                    ],
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
                  '${isIncome ? '+' : '−'} ${formatRupiah(transaction.amount)}',
                  style: AppTextStyles.numericSm.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: amtColor,
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
    );
  }

  static Color _amtBg(bool isDark, bool isIncome) {
    if (isDark) {
      return isIncome
          // ignore: deprecated_member_use
          ? const Color(0xFF6EE7A0).withOpacity(0.12)
          // ignore: deprecated_member_use
          : const Color(0xFFFF8F70).withOpacity(0.10);
    }
    return isIncome
        // ignore: deprecated_member_use
        ? const Color(0xFF16A34A).withOpacity(0.10)
        // ignore: deprecated_member_use
        : const Color(0xFFE07A3C).withOpacity(0.08);
  }

  static IconData _categoryIcon(TransactionCategory cat) {
    return switch (cat) {
      TransactionCategory.food => Icons.restaurant_outlined,
      TransactionCategory.transport => Icons.directions_bus_outlined,
      TransactionCategory.shopping => Icons.shopping_bag_outlined,
      TransactionCategory.health => Icons.favorite_border,
      TransactionCategory.internet => Icons.wifi_outlined,
      TransactionCategory.fixed => Icons.home_outlined,
      TransactionCategory.income => Icons.arrow_downward_rounded,
      TransactionCategory.other => Icons.more_horiz_rounded,
    };
  }

}
