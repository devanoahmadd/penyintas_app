import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/category_metadata.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';

// V2 card — no Dismissible/connector here; parent (_V2TxRow) owns those.
class TransactionItem extends StatelessWidget {
  const TransactionItem({super.key, required this.transaction});

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
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;

    final (icon, _) = CategoryMetadata.of(transaction.category);
    final categoryLabel = CategoryMetadata.resolveLabelFromSlug(
      transaction.category,
      context.l10n,
    );

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Icon(icon, size: 18, color: textColor),
          ),
          const SizedBox(width: AppSpacing.sm2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  transaction.note ?? categoryLabel,
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
                      categoryLabel.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10,
                        color: mutedColor,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      child: Text(
                        '·',
                        // ignore: deprecated_member_use
                        style: TextStyle(color: mutedColor.withOpacity(0.5)),
                      ),
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
}
