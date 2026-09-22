import 'package:flutter/material.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/category_metadata.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/challenge/domain/challenge_constants.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_week.dart';
import 'package:penyintas_app/features/challenge/presentation/utils/challenge_week_range.dart';

/// Riwayat tantangan mingguan (spec §7.8) — daftar POLOS, tanpa kartu, tanpa
/// hiasan. Menerima `List<ChallengeWeek>` (S-C) langsung dari
/// `ChallengeSnapshot.history` — TIDAK PERNAH baris Drift mentah, jadi
/// berkas ini tidak pernah butuh mengimpor modul database Drift-nya
/// (S-C, dikunci test grep di berkas test pasangannya).
///
/// **Kegagalan tidak diwarnai merah.** Status memakai ikon + teks, tidak
/// pernah warna saja: `✓` (achieved) memakai `primary`/`shoot`, `✗` (missed)
/// dan `•` (held/skipped) memakai `muted*` — BUKAN `warn`. Riwayat yang
/// berdarah-darah membuat orang berhenti membukanya (brief Task 16).
///
/// Baris duduk langsung di atas `bg*` (bukan `card*`/`surface*`), jadi
/// `muted*` DIPILIH SENGAJA untuk teks sekunder di sini — kebalikan aturan
/// U86 yang berlaku untuk teks DI DALAM kartu. `mutedLight`/`bgLight` =
/// 4,77:1 dan `mutedDark`/`bgDark` = 4,82:1, keduanya lolos AA teks normal
/// (lihat tabel kontras laporan Task 16).
///
/// Maksimal [kChallengeHistoryWeeks] baris dirender — `history` yang dikirim
/// BLoC memang sudah dibatasi jumlah itu (Task 13), tapi `.take()` di sini
/// membuat batasnya terkunci DI SINI juga, bukan cuma dipercaya dari
/// pemanggil.
///
/// I2 (review Task 16 ronde 2) — TEMUAN: `ChallengeLocalDatasourceImpl.
/// watchHistory` (data layer) tidak punya `where` sama sekali — baris
/// minggu YANG SEDANG BERJALAN ikut terbawa `history` selama ia sudah
/// pernah ditulis (`active`, dibuat Senin/Selasa). Karena baris itu JUGA
/// yang dirender `ActiveChallengeCard` di kartu utama, tanpa penyaringan
/// di sini user Senin pertama melihat baris RIWAYAT pertama sama persis
/// dengan kartu utama di atasnya — kategori sama, tapi kolom nominal "—"
/// (status `active` tidak match cabang manapun di `_HistoryRow`, lihat
/// switch di bawah). Itu bukan riwayat, itu duplikat kosong-makna. Mock
/// spec §7.8 hanya menggambar minggu yang SUDAH TUNTAS (✓/✗/•) — nol
/// baris "active". Disaring DI SINI (bukan di data layer — di luar scope
/// berkas yang boleh diubah task ini) SEBELUM `.take()`, supaya minggu
/// aktif tidak pernah memakan salah satu dari 12 slot riwayat.
class ChallengeHistoryList extends StatelessWidget {
  const ChallengeHistoryList({super.key, required this.history});

  final List<ChallengeWeek> history;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final rows = history
        .where((w) => w.status != ChallengeStatus.active)
        .take(kChallengeHistoryWeeks)
        .toList();

    return Column(
      key: const Key('challenge-history-list'),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) Divider(height: 1, thickness: 1, color: borderColor),
          _HistoryRow(week: rows[i], index: i),
        ],
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.week, required this.index});

  final ChallengeWeek week;
  final int index;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    // U91 — TIDAK ADA `shoot` yang di-hardcode terpisah dari token yang sudah
    // terdaftar; ini sekadar pemilihan token sesuai tema, bukan literal
    // locale. `shoot` dipakai (bukan `primary` polos) karena `primary` di
    // atas `bgDark` cuma 3,17:1 — lolos ambang non-teks (3:1) tapi tipis;
    // `shoot`/`bgDark` = 12,01:1, jauh lebih aman untuk ikon kecil.
    final checkColor = isDark ? AppColors.shoot : AppColors.primary;

    final rangeLabel = challengeWeekRange(context, week.weekKey);
    final categoryLabel = week.category == null
        ? '—'
        : CategoryMetadata.resolveLabelFromSlug(week.category!, l10n);

    final IconData? icon;
    final Color iconColor;
    final String trailing;
    switch (week.status) {
      case ChallengeStatus.achieved:
        icon = Icons.check_rounded;
        iconColor = checkColor;
        trailing = formatRupiah(week.finalSpent ?? 0);
      case ChallengeStatus.missed:
        icon = Icons.close_rounded;
        iconColor = mutedColor;
        trailing = formatRupiah(week.finalSpent ?? 0);
      case ChallengeStatus.held:
        icon = Icons.fiber_manual_record;
        iconColor = mutedColor;
        trailing = l10n.challengeHistoryHeld;
      case ChallengeStatus.skipped:
        icon = Icons.fiber_manual_record;
        iconColor = mutedColor;
        trailing = l10n.challengeHistorySkipped;
      // U85 — `unknown` TIDAK PERNAH diberi ikon ✓/✗ (atau ikon apa pun):
      // app tidak menebak hasil yang tak ia pahami. `active` masuk cabang
      // yang sama sebagai PENJAGA GANDA — `ChallengeHistoryList.build` di
      // atas SUDAH menyaring `status == active` sebelum baris ini pernah
      // dibangun (I2, review ronde 2), tapi switch atas `ChallengeStatus`
      // (enam nilai) tetap wajib exhaustive lewat compiler; kalau penyaring
      // di atas suatu saat lolos/dihapus, cabang ini tetap merender "—"
      // polos alih-alih mengklaim hasil yang belum ada.
      case ChallengeStatus.unknown:
      case ChallengeStatus.active:
        icon = null;
        iconColor = mutedColor;
        trailing = '—';
    }

    return Container(
      key: Key('challenge-history-row-$index'),
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      alignment: Alignment.center,
      child: Row(
        children: [
          // I3 (review ronde 2) — TEMUAN via `RenderParagraph.
          // didExceedMaxLines` (test yang sebelumnya cuma `takeException()`
          // tak bisa menangkap ini, sebab `overflow: ellipsis` tak pernah
          // melempar): pembagian flex LAMA (3:4:4) memotong rentang tanggal
          // di 320dp ("31 Agu–6 Sep" butuh ±100px, cuma dapat ±74px).
          // Dilonggarkan jadi 5:3:6 — kategori (paling aman dipotong; nama
          // kategori tetap terbaca dari beberapa huruf pertama + ikon di
          // kartu utama) menyusut, rentang tanggal & trailing finansial
          // melebar. Diverifikasi ULANG lewat `didExceedMaxLines` di test
          // — bukan tebakan lebar piksel.
          Expanded(
            flex: 5,
            child: Text(
              rangeLabel,
              key: Key('challenge-history-range-$index'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(color: mutedColor),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 3,
            child: Text(
              categoryLabel,
              key: Key('challenge-history-category-$index'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(color: textColor),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            flex: 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    key: Key('challenge-history-icon-$index'),
                    size: 16,
                    color: iconColor,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    trailing,
                    key: Key('challenge-history-trailing-$index'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: AppTextStyles.numericSm.copyWith(color: mutedColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
