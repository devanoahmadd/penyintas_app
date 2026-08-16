import 'package:flutter/material.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';

/// Sheet penjelasan "Apa itu kebutuhan tetap?" (spec §6.4).
///
/// SATU-SATUNYA bantuan-yang-dipanggil di gelombang ini, dan itu disengaja.
/// Teks yang selalu tampil di sembilan kontrol akan berhenti dibaca
/// seluruhnya, termasuk kalimat yang paling penting. Setiap kalimat yang
/// ditambahkan menurunkan nilai kalimat yang sudah ada.
///
/// Lahir di `widgets/common/` supaya Anggaran & Dashboard bisa memakainya
/// kelak — tapi di gelombang ini HANYA disambung ke Tagihan.
class FixedNeedHelpSheet {
  const FixedNeedHelpSheet._();

  static Future<void> show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final softColor = isDark ? AppColors.textSoftDark : AppColors.textSoftLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    Widget judul(String teks) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(teks, style: AppTextStyles.h3.copyWith(color: textColor)),
    );

    Widget paragraf(String teks) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Text(teks, style: AppTextStyles.body.copyWith(color: softColor)),
    );

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grabber — penanda KASATMATA sheet bisa ditarik turun, menyalin
          // bentuk & ukuran sheet lain di aplikasi ini (mark_bill_paid_sheet,
          // bill_actions_sheet) supaya isyaratnya sudah dikenal pengguna.
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // ── Jalan keluar EKSPLISIT (gerbang ui-ux-pro-max: `modal-escape`,
          // severity High — "modals/sheets must have clear close actions").
          // Sheet ini BACAAN pasif dengan lima blok teks; mengandalkan
          // swipe-down/tap-scrim saja mengubur satu-satunya jalan keluar di
          // balik gestur yang tak semua orang tahu. TIDAK ada judul di baris
          // ini — judul aslinya ([l10n.billsFixedHelpTitle]) sudah jadi
          // heading PERTAMA isi di bawah; menaruhnya juga di sini akan
          // membuatnya tampil dua kali di layar yang sama.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: [
                const Spacer(),
                // Tanpa label semantik eksplisit — menyalin `_CloseButton`
                // milik `mark_bill_paid_sheet.dart` apa adanya. Menambah
                // label di sini butuh kunci l10n baru yang di luar cakupan
                // task ini (enam kunci `bills_fixed_help_*` sudah cukup).
                InkResponse(
                  onTap: () => Navigator.of(context).pop(),
                  radius: 24,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.close, size: 18, color: mutedColor),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  judul(l10n.billsFixedHelpTitle),
                  paragraf(l10n.billsFixedHelpBody1),
                  paragraf(l10n.billsFixedHelpBody2),
                  // Pemisah antar DUA topik berbeda dalam satu sheet (gerbang
                  // ui-ux-pro-max: `whitespace-balance` — pisahkan bagian
                  // lewat spasi/garis, bukan gaya teks baru). Token warna
                  // saja (`borderColor`), tanpa token baru.
                  Divider(height: AppSpacing.xl, color: borderColor),
                  // Blok ini menjelaskan penguncian yang terjadi di sheet
                  // bayar. Ia TETAP ditampilkan di form meski toggle form tak
                  // pernah dikunci (I4), karena ia menjelaskan ATURAN
                  // aplikasi, bukan keadaan layar saat itu.
                  judul(l10n.billsFixedHelpLockedTitle),
                  Text(
                    l10n.billsFixedHelpLockedBody,
                    style: AppTextStyles.body.copyWith(color: softColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
