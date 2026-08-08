import 'package:flutter/material.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';

/// Tile toggle berlabel + hint, dengan tombol bantuan (?) opsional.
///
/// Diekstrak dari `_ToggleTile` milik `mark_bill_paid_sheet.dart` (spec §6.4)
/// supaya form tagihan dan sheet tandai-lunas memakai satu affordance yang
/// sama. Perilakunya identik dengan asalnya — ekstraksi ini nol perubahan.
class FixedNeedToggleTile extends StatelessWidget {
  const FixedNeedToggleTile({
    super.key,
    required this.tileKey,
    required this.switchKey,
    required this.value,
    required this.label,
    required this.hint,
    required this.panelColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedColor,
    required this.onChanged,
    this.enabled = true,
    this.hintColor,
    this.onHelpTap,
    this.helpSemanticLabel,
  });

  final Key tileKey;
  final Key switchKey;
  final bool value;
  final String label;
  final String hint;
  final Color panelColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedColor;
  final ValueChanged<bool> onChanged;

  /// `false` = kontrol TAK BERLAKU untuk tagihan ini — bukan "mati sementara".
  /// Read-only, bukan disabled: label sengaja TIDAK dipudarkan. Memudarkannya
  /// menjatuhkan kontras label di bawah AA pada KEDUA tema (light lebih dulu:
  /// 16,05:1 → 3,28:1 pada alpha 0,5). Yang dipudarkan hanya switch-nya.
  final bool enabled;

  /// Warna baris hint. Default `mutedColor`. Tile terkunci mengirim `textSoft*`
  /// karena hint-nya jadi SATU-SATUNYA penjelasan kenapa kontrol itu mati —
  /// `mutedDark` di atas `surfaceAltDark` hanya 3,51:1 (gagal AA teks kecil).
  final Color? hintColor;

  /// null → tak ada tombol (?). Non-null → tombol bantuan digambar di antara
  /// label dan switch, dengan hit target 48dp sendiri.
  final VoidCallback? onHelpTap;

  /// Label pembaca layar untuk tombol (?). Ikon tanpa teks tak terbaca tanpa
  /// ini. Wajib diisi kalau [onHelpTap] non-null.
  final String? helpSemanticLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: tileKey,
      color: panelColor,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: borderColor),
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              // ── NODE 1 — tile itu sendiri ────────────────────────────────
              // MergeSemantics TANPA SYARAT: label + hint + state switch
              // diumumkan sebagai satu node di SEMUA state. Memasangnya
              // kondisional membuat bentuk pengumuman screen-reader
              // berubah-ubah untuk kontrol yang sama.
              //
              // Cakupannya BERHENTI DI SINI, dan itu bukan gaya penulisan:
              // MergeSemantics menelan SELURUH keturunannya jadi satu node.
              // Tombol (?) yang ikut masuk akan (a) tak bisa difokus pembaca
              // layar sama sekali, dan (b) menimpa/tertimpa aksi tap tile,
              // sehingga "double-tap" bisa membalik toggle padahal pengguna
              // bermaksud membuka penjelasan. Karena itu (?) berdiri sebagai
              // saudara di bawah, BUKAN sebagai anak.
              Expanded(
                child: MergeSemantics(
                  child: InkWell(
                    onTap: enabled ? () => onChanged(!value) : null,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                label,
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 13,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hint,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 12,
                                  height: 1.35,
                                  color: hintColor ?? mutedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Switch(
                          key: switchKey,
                          value: value,
                          onChanged: enabled ? onChanged : null,
                          activeThumbColor: Colors.white,
                          activeTrackColor: AppColors.primary,
                          // Warna mati dipaksa lewat WidgetStatePropertyAll
                          // supaya state `disabled` Material tidak menimpanya
                          // dengan abu-abu default yang di luar palet.
                          thumbColor: enabled
                              ? null
                              : WidgetStatePropertyAll(mutedColor),
                          trackColor: enabled
                              ? null
                              : WidgetStatePropertyAll(borderColor),
                          // Outline WAJIB ikut dipaksa. `border*` di atas panel
                          // `surfaceAlt*` cuma 1,07:1 (dark) / 1,28:1 (light) —
                          // track sendirian LENYAP ke dalam panel dan yang
                          // tersisa di layar hanya titik thumb mengambang,
                          // bukan "switch yang mati". `muted*` mengembalikan
                          // bentuknya: 3,51:1 (dark) / 4,65:1 (light), lulus
                          // ambang 3:1 komponen non-teks.
                          trackOutlineColor: enabled
                              ? null
                              : WidgetStatePropertyAll(mutedColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // ── NODE 2 — tombol bantuan, DI LUAR merge ───────────────────
              // Posisinya di ujung kanan (bukan di antara label dan switch)
              // justru karena switch wajib tetap satu node dengan label.
              if (onHelpTap != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Semantics(
                  button: true,
                  label: helpSemanticLabel,
                  child: InkResponse(
                    onTap: onHelpTap,
                    radius: 24,
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.help_outline_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
