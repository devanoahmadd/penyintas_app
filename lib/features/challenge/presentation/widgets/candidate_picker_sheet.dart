import 'package:flutter/material.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/category_metadata.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_candidate.dart';

/// Sheet "Ganti pos" (spec §7.9, T7/T14) — dipanggil dari baris "Ganti pos"
/// milik `ActiveChallengeCard` (Task 14), hanya Senin–Selasa (T7).
///
/// **Target ditampilkan SEBELUM user memilih** — meminta orang berkomitmen
/// pada angka yang baru muncul setelah komitmennya adalah pola gelap kecil
/// yang gampang lolos (brief Task 16). Karena itu widget ini murni
/// PRESENTASIONAL: [candidates] datang APA ADANYA dari
/// `ChallengeRepository.getCandidates(weekKey)` (dipanggil pemanggil sheet,
/// bukan di sini — lihat catatan di `challenge_page.dart`), lengkap dengan
/// `target`/`baseline` yang SUDAH dihitung `computeTarget` (T4). Sheet ini
/// tidak pernah menghitung ulang angka — persis alasan Rev 5 desain
/// mewajibkan "test yang menghitung, bukan mencocokkan string" untuk baris
/// kandidat: tiga pasangan contoh di mock lama (141→120, 96→81, 74→62)
/// SEMUANYA salah karena ditulis tangan tanpa menjalankan rumusnya.
///
/// `spentThisWeek` HANYA relevan untuk kandidat yang kategorinya SAMA dengan
/// [currentCategory] (kategori yang sedang aktif minggu ini) — baris
/// "sudah terpakai" (U111) memakai `ChallengeSnapshot.spentThisWeek` yang
/// BLoC sudah punya, bukan query per-kategori baru.
class CandidatePickerSheet extends StatefulWidget {
  const CandidatePickerSheet({
    super.key,
    required this.candidates,
    required this.currentCategory,
    required this.spentThisWeek,
    required this.onPakai,
  });

  final List<ChallengeCandidate> candidates;
  final String? currentCategory;
  final int spentThisWeek;
  final ValueChanged<String> onPakai;

  static Future<void> show(
    BuildContext context, {
    required List<ChallengeCandidate> candidates,
    required String? currentCategory,
    required int spentThisWeek,
    required ValueChanged<String> onPakai,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => CandidatePickerSheet(
        candidates: candidates,
        currentCategory: currentCategory,
        spentThisWeek: spentThisWeek,
        onPakai: onPakai,
      ),
    );
  }

  @override
  State<CandidatePickerSheet> createState() => _CandidatePickerSheetState();
}

class _CandidatePickerSheetState extends State<CandidatePickerSheet> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    final adaDiKandidat = widget.candidates.any(
      (c) => c.category == widget.currentCategory,
    );
    _selected = adaDiKandidat
        ? widget.currentCategory
        : (widget.candidates.isNotEmpty
              ? widget.candidates.first.category
              : null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final textSoftColor = isDark
        ? AppColors.textSoftDark
        : AppColors.textSoftLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Container(
              key: const Key('challenge-candidate-handle'),
              width: 32,
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
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.challengeCandidateTitle,
                  style: AppTextStyles.h3.copyWith(color: textColor),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.challengeCandidateSubtitle,
                  style: AppTextStyles.bodySmall.copyWith(color: textSoftColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final c in widget.candidates)
                    _CandidateRow(
                      key: Key('challenge-candidate-row-${c.category}'),
                      candidate: c,
                      selected: _selected == c.category,
                      showSpent:
                          c.category == widget.currentCategory &&
                          widget.spentThisWeek > 0,
                      spentThisWeek: widget.spentThisWeek,
                      onTap: () => setState(() => _selected = c.category),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('challenge-candidate-submit'),
                onPressed: _selected == null
                    ? null
                    : () {
                        final dipilih = _selected!;
                        Navigator.of(context).pop();
                        widget.onPakai(dipilih);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withValues(
                    alpha: 0.4,
                  ),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
                child: Text(
                  l10n.challengeCandidateSubmit,
                  style: AppTextStyles.label.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateRow extends StatelessWidget {
  const _CandidateRow({
    super.key,
    required this.candidate,
    required this.selected,
    required this.showSpent,
    required this.spentThisWeek,
    required this.onTap,
  });

  final ChallengeCandidate candidate;
  final bool selected;
  final bool showSpent;
  final int spentThisWeek;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    // Radio & label sekunder di sini di atas SURFACE, bukan bg — U86-style:
    // `textSoft*` untuk teks sekunder, `muted*` HANYA untuk elemen non-teks
    // (outline radio yang tak terpilih) karena `muted*` gagal AA teks di atas
    // `surface*` (mutedLight/surfaceLight = 3,85:1, mutedDark/surfaceDark =
    // 3,99:1 — keduanya < 4,5, lihat tabel kontras laporan Task 16).
    final textSoftColor = isDark
        ? AppColors.textSoftDark
        : AppColors.textSoftLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final accentColor = isDark ? AppColors.shoot : AppColors.primary;
    final (categoryIcon, categoryIconColor) = CategoryMetadata.of(
      candidate.category,
    );
    final categoryLabel = CategoryMetadata.resolveLabelFromSlug(
      candidate.category,
      l10n,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                key: Key('challenge-candidate-radio-${candidate.category}'),
                size: 20,
                color: selected ? accentColor : mutedColor,
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(categoryIcon, size: 20, color: categoryIconColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      categoryLabel,
                      style: AppTextStyles.body.copyWith(color: textColor),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      key: Key(
                        'challenge-candidate-target-${candidate.category}',
                      ),
                      l10n.challengeCandidateAverageToTarget(
                        _plain(candidate.baseline),
                        _plain(candidate.target),
                      ),
                      style: AppTextStyles.numericSm.copyWith(
                        color: textSoftColor,
                      ),
                    ),
                    if (showSpent) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        key: Key(
                          'challenge-candidate-spent-${candidate.category}',
                        ),
                        l10n.challengeCandidateAlreadySpent(
                          _plain(spentThisWeek),
                        ),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: textSoftColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nominal polos berkelompok titik untuk disisipkan ke template l10n — sama
/// persis konvensi `_plainNumber` di `active_challenge_card.dart` (Rupiah
/// SENGAJA tidak mengikuti bahasa UI, lihat catatan di sana).
String _plain(int amount) => formatRupiah(amount).replaceFirst('Rp ', '');
