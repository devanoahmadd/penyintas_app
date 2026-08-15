import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/category_metadata.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/presentation/widgets/bill_status_chip.dart';

/// Satu baris tagihan di daftar Tagihan.
///
/// Anatomi mengikuti `TransactionItem`: ikon kategori 36×36 · nama + caption
/// · nominal + chip status · pintu menu ⋮ (Task 13).
class BillItem extends StatelessWidget {
  const BillItem({
    super.key,
    required this.bill,
    this.onTap,
    this.onMenuTap,
    this.todayStart,
    this.categoryIconSlug,
    this.categoryResolved = false,
  });

  final BillEntity bill;
  final VoidCallback? onTap;

  /// null → ⋮ tidak digambar. Baris tanpa pintu aksi tetap sah (mis. saat
  /// dipakai di layar lain kelak).
  ///
  /// SENGAJA tidak bergantung pada bisa-tidaknya tagihan ditandai lunas
  /// (`onTap`) — tagihan yang sudah tamat tetap harus bisa diubah/dihapus.
  final VoidCallback? onMenuTap;

  /// Awal hari acuan untuk derivasi "Terlambat". Null → dihitung dari
  /// `DateTime.now()`. Halaman daftar mengirim nilai tunggal agar semua baris
  /// memakai acuan yang sama.
  final DateTime? todayStart;

  /// `iconSlug` kategori bill ini, dipetakan oleh pemanggil dari CategoryBloc.
  ///
  /// null punya DUA arti yang sengaja tak dibedakan di sini: kategori
  /// built-in (ikonnya dari `CategoryMetadata`), atau CategoryBloc belum
  /// siap. Yang membedakan keduanya adalah [categoryResolved].
  final String? categoryIconSlug;

  /// `true` bila [categoryIconSlug] datang dari daftar kategori yang sudah
  /// dimuat — bukan sekadar "belum ada nilai". Selama `false`, baris memakai
  /// ikon tagihan lama sebagai antara.
  final bool categoryResolved;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;

    final today = todayStart ?? startOfDay(DateTime.now());
    final status = billDisplayStatusOf(bill, today);

    final locale = Localizations.localeOf(context).languageCode;
    final dueLabel = DateFormat('d MMM', locale).format(bill.dueDate);

    final total = bill.installmentTotal;
    // Bill lunas: chip "Selesai" sudah mengomunikasikan status, dan
    // `installmentsPaid + 1` akan melewati total (mis. "Cicilan ke-13 dari 12").
    // Jadi progres cicilan hanya ditampilkan selama bill masih berjalan.
    final installmentLabel =
        (total == null || bill.status == BillStatus.completed)
        ? null
        : context.l10n.billsInstallmentProgress(
            bill.installmentsPaid + 1,
            total,
          );

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: borderColor),
          ),
          child: Container(
            // Hit target minimum Android 48dp.
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm2,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Icon(
                    // `of()` — BUKAN `iconFromSlug(bill.category)`.
                    // `iconFromSlug` melihat namespace ikon KUSTOM
                    // (`restaurant`/`coffee`/…), bukan slug kategori.
                    categoryResolved
                        ? CategoryMetadata.of(
                            bill.category,
                            iconSlug: categoryIconSlug,
                          ).$1
                        // Antara saat CategoryBloc belum siap: ikon tagihan
                        // lama. Ia netral dan tak pernah salah — berbeda dari
                        // ikon grid generik yang berarti "kategori tak
                        // dikenal".
                        : Icons.receipt_long_outlined,
                    size: 18,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        bill.name,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              dueLabel.toUpperCase(),
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 10,
                                color: mutedColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (installmentLabel != null) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                              ),
                              child: Text(
                                '·',
                                style: TextStyle(
                                  color: mutedColor.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                installmentLabel.toUpperCase(),
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 10,
                                  color: mutedColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // `Flexible` (bukan biarkan lebar intrinsik) — nominal 8
                // digit di layar sempit (320dp) sudah cukup lebar sendiri
                // untuk membuat `Row` overflow kalau kolom ini kaku [Audit
                // S8]. Nama tagihan (Expanded di atas) sudah punya ellipsis;
                // nominal & chip diberi jaring pengaman yang sama supaya
                // baris tak pernah melempar RenderFlex overflow.
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatRupiah(bill.estimatedAmount),
                        style: AppTextStyles.numericSm.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      BillStatusChip(status: status),
                    ],
                  ),
                ),
                if (onMenuTap != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  // Node semantik SENDIRI — bukan turunan yang bisa tertelan
                  // `MergeSemantics`. Berdiri lepas dari `canMarkPaid`: pintu
                  // ubah/hapus wajib tetap ada walau baris tak lagi bisa
                  // ditandai lunas.
                  Semantics(
                    button: true,
                    label: context.l10n.billsActionsMenuA11y,
                    child: InkResponse(
                      key: ValueKey('bill_item_menu_${bill.id}'),
                      onTap: onMenuTap,
                      radius: 24,
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.more_vert_rounded,
                          size: 20,
                          color: mutedColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
