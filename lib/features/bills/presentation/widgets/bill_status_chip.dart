import 'package:flutter/material.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';

/// Status TAMPILAN tagihan (turunan spec §5) — beda dari [BillStatus] yang
/// hanya mengenal active/completed. "Terlambat" bukan status tersimpan,
/// melainkan hasil banding `dueDate` dengan awal hari ini.
enum BillDisplayStatus { overdue, upcoming, done }

/// Awal hari (00:00) dari [now] — pembanding bebas komponen jam.
DateTime startOfDay(DateTime now) => DateTime(now.year, now.month, now.day);

/// Derivasi status tampilan. [todayStart] wajib awal-hari (lihat [startOfDay]).
BillDisplayStatus billDisplayStatusOf(BillEntity bill, DateTime todayStart) {
  if (bill.status == BillStatus.completed) return BillDisplayStatus.done;
  if (bill.isOverdue(todayStart)) return BillDisplayStatus.overdue;
  return BillDisplayStatus.upcoming;
}

/// Chip status tagihan — SELALU berteks, warna hanya penguat.
/// Pengguna dengan buta warna tetap bisa membedakan "Terlambat".
class BillStatusChip extends StatelessWidget {
  const BillStatusChip({super.key, required this.status});

  final BillDisplayStatus status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    final (String label, Color fg, Color bg) = switch (status) {
      BillDisplayStatus.overdue => (
        l10n.billsStatusOverdue,
        AppColors.warn,
        AppColors.warn.withValues(alpha: isDark ? 0.22 : 0.14),
      ),
      BillDisplayStatus.done => (
        l10n.billsStatusDone,
        isDark ? AppColors.shoot : AppColors.primary,
        (isDark ? AppColors.shoot : AppColors.primary).withValues(
          alpha: isDark ? 0.18 : 0.12,
        ),
      ),
      BillDisplayStatus.upcoming => (
        l10n.billsStatusUpcoming,
        isDark ? AppColors.mutedDark : AppColors.mutedLight,
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.caption.copyWith(fontSize: 9, color: fg),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
