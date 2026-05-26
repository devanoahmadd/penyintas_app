import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/transaction_list_bloc.dart';

const double _spineW = 2;
const double _spineOpacity = 0.3;
const double _dayNodeD = 38;

class TransactionDetailSheet extends StatelessWidget {
  const TransactionDetailSheet({super.key, required this.transaction});
  final TransactionEntity transaction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = transaction.type == TransactionType.income;
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
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
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(
                  top: AppSpacing.md, bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.xs, AppSpacing.sm, AppSpacing.md),
            child: Row(
              children: [
                SizedBox(
                  width: _dayNodeD,
                  child: Column(
                    children: [
                      Container(
                        width: _spineW,
                        height: 16,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              // ignore: deprecated_member_use
                              AppColors.primary.withOpacity(_spineOpacity),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: _dayNodeD,
                        height: _dayNodeD,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isIncome
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Detail Transaksi',
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: mutedColor, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: amtBg,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(_categoryIcon(transaction.category),
                        size: 20, color: amtColor),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.note ?? transaction.category.label,
                          style: AppTextStyles.label.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          transaction.category.label.toUpperCase(),
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            color: mutedColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${isIncome ? '+' : '−'} ${formatRupiah(transaction.amount)}',
                    style: AppTextStyles.numericSm.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: amtColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                _MetaRow(
                  label: 'Waktu',
                  value: DateFormat('HH:mm · dd MMM yyyy', 'id_ID')
                      .format(transaction.date),
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.sm),
                _MetaRow(
                  label: 'Jenis',
                  value: transaction.type == TransactionType.income
                      ? 'Pemasukan'
                      : (transaction.isFixed
                          ? 'Pengeluaran Tetap'
                          : 'Pengeluaran Variabel'),
                  isDark: isDark,
                ),
                if (transaction.note != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _MetaRow(
                    label: 'Catatan',
                    value: transaction.note!,
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    isDark: isDark,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm2),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.copy_outlined,
                    label: 'Duplikat',
                    isDark: isDark,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  context
                      .read<TransactionListBloc>()
                      .add(DeleteTransactionRequested(transaction.id));
                  Navigator.pop(context);
                },
                child: Text(
                  'Hapus Transaksi',
                  style:
                      AppTextStyles.label.copyWith(color: AppColors.warn),
                ),
              ),
            ),
          ),
          SizedBox(
              height: MediaQuery.of(context).padding.bottom + AppSpacing.md),
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
      TransactionCategory.food      => Icons.restaurant_outlined,
      TransactionCategory.transport => Icons.directions_bus_outlined,
      TransactionCategory.shopping  => Icons.shopping_bag_outlined,
      TransactionCategory.health    => Icons.favorite_border,
      TransactionCategory.internet  => Icons.wifi_outlined,
      TransactionCategory.fixed     => Icons.home_outlined,
      TransactionCategory.income    => Icons.arrow_downward_rounded,
      TransactionCategory.other     => Icons.more_horiz_rounded,
    };
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow(
      {required this.label, required this.value, required this.isDark});
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm2),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                color: mutedColor,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.label
                  .copyWith(color: textColor, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
