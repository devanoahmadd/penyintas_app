import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/bills/presentation/widgets/tied_money_row.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';

/// Kartu "Saldo Terkini" — besaran utama dashboard.
///
/// Diekstrak dari `dashboard_page.dart` (semula `_SaldoCard` privat) supaya
/// pemasangan [TiedMoneyRow] di dalamnya bisa diuji tanpa mem-pump
/// `DashboardPage` penuh berikut lima BLoC yang tak relevan. Preseden sama
/// dengan `BillsBentoTile` (Task 7.1).
///
/// PEMINDAHAN MURNI — tidak ada perubahan perilaku dari versi privatnya.
class SaldoCard extends StatefulWidget {
  const SaldoCard({super.key, required this.entity, required this.onDetailTap});

  final DashboardEntity entity;
  final VoidCallback onDetailTap;

  @override
  State<SaldoCard> createState() => _SaldoCardState();
}

class _SaldoCardState extends State<SaldoCard> {
  bool _hidden = false;

  String _timestamp(BuildContext context, DateTime dt) {
    final locale = Localizations.localeOf(context).languageCode;
    final dateStr = DateFormat('d MMMM yyyy', locale).format(dt);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${context.l10n.dashboardBalanceAsOf} $dateStr · $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    // Today's income/expense delta dari transaksi hari ini
    final todayIncome = widget.entity.todayTransactions
        .where((t) => t.type == TransactionType.income)
        .fold<int>(0, (sum, t) => sum + t.amount);
    final todayExpense = widget.entity.todayTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold<int>(0, (sum, t) => sum + t.amount);
    final hasTodayActivity = widget.entity.todayTransactions.isNotEmpty;
    final incomeColor = isDark ? AppColors.incomeDark : AppColors.success;
    final expenseColor = isDark ? AppColors.expenseDark : AppColors.warn;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg2),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row + eye toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.dashboardSaldoLabel,
                style: AppTextStyles.caption.copyWith(color: mutedColor),
              ),
              GestureDetector(
                onTap: () => setState(() => _hidden = !_hidden),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Icon(
                      _hidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: mutedColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Balance amount
          Text(
            _hidden
                ? context.l10n.dashboardBalanceHidden
                : formatRupiah(widget.entity.totalRemaining),
            style: AppTextStyles.numericLg.copyWith(color: textColor),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Today's delta row (hanya tampil jika ada aktivitas & tidak hidden)
          if (hasTodayActivity && !_hidden) ...[
            Row(
              children: [
                Icon(Icons.arrow_upward_rounded, size: 12, color: incomeColor),
                const SizedBox(width: 3),
                Text(
                  formatRupiah(todayIncome),
                  style: AppTextStyles.caption.copyWith(
                    color: incomeColor,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Icon(
                  Icons.arrow_downward_rounded,
                  size: 12,
                  color: expenseColor,
                ),
                const SizedBox(width: 3),
                Text(
                  formatRupiah(todayExpense),
                  style: AppTextStyles.caption.copyWith(
                    color: expenseColor,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'hari ini',
                  style: AppTextStyles.caption.copyWith(
                    color: mutedColor,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Baris uang terikat / sisa aman (P1). Jarak atas & garis pemisah
          // dimiliki widget-nya sendiri supaya saat tak ada tagihan sebelum
          // gajian jejaknya benar-benar nol — tanpa celah gantung di kartu.
          //
          // `hidden: _hidden` WAJIB ikut toggle privasi: tanpa itu, menekan
          // tombol mata menyembunyikan saldo utama tapi membiarkan baris ini
          // memamerkan nominal. Dikunci `saldo_card_test.dart`.
          TiedMoneyRow(
            commitments: widget.entity.billCommitments,
            hidden: _hidden,
          ),

          // Timestamp + Detail link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _timestamp(context, widget.entity.lastUpdated),
                style: AppTextStyles.caption.copyWith(
                  color: mutedColor,
                  letterSpacing: 0,
                ),
              ),
              GestureDetector(
                onTap: widget.onDetailTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.dashboardBalanceDetail,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
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
