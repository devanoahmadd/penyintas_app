import 'package:flutter/material.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';

/// Aksi yang dipilih dari [BillActionsSheet].
enum BillAction { edit, delete }

/// Sheet dua aksi untuk satu baris tagihan (spec §4.4, keputusan D6).
///
/// Sheet, bukan `PopupMenuButton`: bahasa sheet sudah dominan di aplikasi ini,
/// dan tiap aksi dapat target 48dp penuh. `PopupMenuButton` memberi baris yang
/// lebih rapat dan menu melayang yang tak konsisten dengan sisa aplikasi.
class BillActionsSheet {
  const BillActionsSheet._();

  static Future<BillAction?> show(
    BuildContext context, {
    required BillEntity bill,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<BillAction>(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => _Body(bill: bill, isDark: isDark),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.bill, required this.isDark});

  final BillEntity bill;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Grabber — satu-satunya penanda KASATMATA bahwa sheet bisa ditarik
          // turun. Bentuk & ukurannya menyalin sheet lain di aplikasi ini
          // (`mark_bill_paid_sheet.dart`), jadi isyaratnya sudah dikenal.
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
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            // Nama tagihan, bukan judul generik: sheet ini muncul dari baris
            // mana pun, jadi namanya satu-satunya penanda "yang mana". Dua
            // baris sebelum dipotong — nama tagihan di aplikasi ini kerap
            // panjang ("Cicilan motor Honda Beat").
            child: Text(
              bill.name,
              style: AppTextStyles.h3.copyWith(color: textColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Divider(height: 1, color: borderColor),
          _ActionRow(
            rowKey: const ValueKey('bill_action_edit'),
            icon: Icons.edit_outlined,
            label: l10n.billsActionEdit,
            color: textColor,
            onTap: () => Navigator.of(context).pop(BillAction.edit),
          ),
          // Pemisah SEBELUM aksi merusak — bukan hiasan: tanpa jeda, "Hapus"
          // cuma satu ketukan meleset dari "Ubah". Aksi merusak harus
          // terpisah, bukan sekadar berbeda warna.
          Divider(height: 1, color: borderColor),
          _ActionRow(
            rowKey: const ValueKey('bill_action_delete'),
            // Ikon DAN warna sama-sama membedakan aksi merusak — dua pembeda,
            // supaya pengguna yang tak membedakan warna tetap terbantu.
            icon: Icons.delete_outline_rounded,
            label: l10n.billsActionDelete,
            color: AppColors.warn,
            onTap: () => Navigator.of(context).pop(BillAction.delete),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.rowKey,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final Key rowKey;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: rowKey,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.md),
            Text(label, style: AppTextStyles.body.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
