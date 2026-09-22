import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/category_metadata.dart';
import 'package:penyintas_app/core/utils/currency_config.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_phase.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_week.dart';
import 'package:penyintas_app/features/challenge/presentation/widgets/challenge_progress_bar.dart';
import 'package:penyintas_app/widgets/common/count_up_text.dart';

/// Pecah [ChallengePhase] jadi bahan mentah kartu. HANYA [PhaseActive] dan
/// [PhaseOver] valid di sini — keduanya sama-sama "minggu ini masih
/// berjalan" (status Drift tetap `active`), beda hanya `spent` sudah lewat
/// `targetAmount` atau belum (lihat `resolveChallengePhase`, Task 5).
({ChallengeWeek week, int spent, bool isOver}) _unwrapPhase(
  ChallengePhase phase,
) {
  return switch (phase) {
    PhaseActive(week: final w, spent: final s) => (
      week: w,
      spent: s,
      isOver: false,
    ),
    PhaseOver(week: final w, spent: final s) => (
      week: w,
      spent: s,
      isOver: true,
    ),
    _ => throw ArgumentError(
      'ActiveChallengeCard hanya menerima PhaseActive atau PhaseOver, '
      'dapat ${phase.runtimeType}',
    ),
  };
}

// Task 16 (U91) — TEMUAN: sebelumnya `NumberFormat.decimalPattern` dipanggil
// dengan locale Indonesia yang di-hardcode LANGSUNG di sini — literal yang
// persis dilarang U91 di seluruh `lib/features/challenge/` (preseden
// pelanggaran yang sama: `date_helper.dart:56,60`, lihat literalnya di
// sana). BUKAN diganti locale-dari-context: format Rupiah SENGAJA tidak
// mengikuti bahasa UI (`CurrencyConfig.idr.locale`, dipakai `formatRupiah`
// di seluruh app) — nominal Rupiah selalu berkelompok titik, baik UI-nya
// Indonesia maupun Inggris, supaya angka di kartu ini (mis. "34.000" dari
// baris ini) tidak pernah berselisih format dengan `mainAmount` di atasnya
// yang dirender lewat `formatRupiah`. Locale-nya diambil dari SATU sumber
// kanonik (`CurrencyConfig.idr.locale`), bukan literal yang diduplikasi.
String _plainNumber(int amount) =>
    NumberFormat.decimalPattern(CurrencyConfig.idr.locale).format(amount);

/// Kartu utama tantangan mingguan saat MASIH BERJALAN — baik masih di bawah
/// target (aktif) maupun sudah lewat (over). Task 15+ menambah kartu untuk
/// keadaan lain (held, settled, dst).
///
/// Aturan visual mengikat (spec §7, dipegang oleh test U86–U93/U111/U113):
/// - Teks sekunder DI DALAM kartu selalu `textSoft*`, tidak pernah `muted*`
///   (`muted*` gagal AA 4,5 di atas `card*`).
/// - Nominal "lewat target" selalu `text*`, TIDAK PERNAH `warn` (`warn` di
///   atas `cardLight` cuma 2,63:1, gagal bahkan ambang teks besar).
/// - Ketiga ambang bar (aman/mendekati/lewat) WAJIB membawa kata + ikon —
///   tema terang tak bisa lolos kontras 3:1 lewat warna saja.
/// - Baris pengecualian tagihan hanya muncul bila `excludedSpent > 0`.
///
/// PENTING (temuan review Task 14, ronde 2): warna FUNGSIONAL
/// (`caution`/`warn`/`primaryBright`) dipakai HANYA untuk isi bar
/// ([ChallengeProgressBar], lewat `challengeBarFillColor`) — elemen grafis
/// yang brief terima secara sadar dengan mitigasi kata+ikon terpisah.
/// Teks DAN ikon baris ambang, serta ikon 16dp di sub-teks "over", memakai
/// `textSoft*` — BUKAN warna fungsional. Memakai warna fungsional di sana
/// membuat mitigasi kontras ikut gagal kontras (`warn`/`cardLight` =
/// 2,63:1, `caution`/`cardLight` = 1,94:1 — persis angka yang aturan di
/// atas larang untuk teks/ikon di atas kartu). `textSoft*` lolos AA di
/// KEDUA tema (`textSoftLight`/`cardLight` = 11,82:1,
/// `textSoftDark`/`cardDark` = 8,38:1).
class ActiveChallengeCard extends StatelessWidget {
  const ActiveChallengeCard({
    super.key,
    required this.phase,
    required this.excludedSpent,
    required this.daysLeft,
    required this.showChangeCategory,
    required this.onChangeCategory,
  });

  final ChallengePhase phase;

  /// Nominal tagihan & kebutuhan tetap yang TIDAK ikut dihitung ke angka
  /// tantangan. Baris penjelas hanya dirender kalau ini > 0 — menyebut
  /// keduanya ("tagihan & kebutuhan tetap") karena ia melaporkan keduanya.
  final int excludedSpent;
  final int daysLeft;
  final bool showChangeCategory;
  final VoidCallback onChangeCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unwrapped = _unwrapPhase(phase);
    final week = unwrapped.week;
    final spent = unwrapped.spent;
    final isOver = unwrapped.isOver;

    final target = week.targetAmount ?? 0;
    final categorySlug = week.category ?? 'other';
    final categoryLabel = CategoryMetadata.resolveLabelFromSlug(
      categorySlug,
      l10n,
    );
    final mainAmount = isOver ? spent - target : target - spent;

    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final textSoftColor = isDark
        ? AppColors.textSoftDark
        : AppColors.textSoftLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final accentColor = isDark ? AppColors.shoot : AppColors.primary;

    final targetFmt = _plainNumber(target);
    final subText = isOver
        ? l10n.challengeCardOverOf(targetFmt)
        : l10n.challengeCardRemainingOf(targetFmt);

    final rawPct = target > 0 ? spent / target : 0.0;
    final barState = challengeBarStateFor(rawPct);
    final stateLabel = switch (barState) {
      ChallengeBarState.safe => l10n.challengeBarStateSafe,
      ChallengeBarState.caution => l10n.challengeBarStateCaution,
      ChallengeBarState.over => l10n.challengeBarStateOver,
    };
    final stateIcon = switch (barState) {
      ChallengeBarState.safe => Icons.eco_outlined,
      ChallengeBarState.caution => Icons.bolt_outlined,
      ChallengeBarState.over => Icons.warning_amber_rounded,
    };

    final daysLeftPhrase = l10n.daysLeft(daysLeft);
    final eyebrow =
        '${categoryLabel.toUpperCase()} · '
        '${daysLeftPhrase.toUpperCase()}';

    final mainAmountFmt = formatRupiah(mainAmount);
    // Satu label utuh untuk pembaca layar — memuat nominal sisa, target
    // (lewat `subText`), kategori, dan sisa hari SEKALIGUS (U93). Bar dan
    // baris "Ganti pos" tetap punya semantics sendiri di luar blok ini.
    final semanticsLabel =
        '$categoryLabel. $mainAmountFmt. $subText $daysLeftPhrase.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: semanticsLabel,
            container: true,
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  eyebrow,
                  style: AppTextStyles.caption.copyWith(color: textSoftColor),
                ),
                const SizedBox(height: AppSpacing.sm),
                CountUpText(
                  value: mainAmount,
                  style: AppTextStyles.numericLg.copyWith(color: textColor),
                  format: formatRupiah,
                ),
                const SizedBox(height: AppSpacing.xs),
                if (isOver)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        key: const Key('challenge-over-subtext-icon'),
                        size: 16,
                        color: textSoftColor,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          subText,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: textSoftColor,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    subText,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: textSoftColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ChallengeProgressBar(spent: spent, target: target, isDark: isDark),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                stateIcon,
                key: const Key('challenge-ambang-icon'),
                size: 16,
                color: textSoftColor,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  stateLabel,
                  key: const Key('challenge-ambang-label'),
                  style: AppTextStyles.caption.copyWith(color: textSoftColor),
                ),
              ),
            ],
          ),
          if (isOver) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.challengeCardOverHint,
              style: AppTextStyles.bodySmall.copyWith(color: textSoftColor),
            ),
          ] else if (daysLeft > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.challengeCardDailyHint(
                _plainNumber((mainAmount / daysLeft).round()),
              ),
              style: AppTextStyles.bodySmall.copyWith(color: textSoftColor),
            ),
          ],
          if (excludedSpent > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.challengeCardExcluded(_plainNumber(excludedSpent)),
              style: AppTextStyles.bodySmall.copyWith(color: textSoftColor),
            ),
          ],
          if (showChangeCategory) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Divider(height: 1, color: borderColor),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                key: const Key('challenge-change-category-row'),
                onTap: onChangeCategory,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          l10n.challengeCardChangeCategory,
                          style: AppTextStyles.label.copyWith(
                            color: accentColor,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: mutedColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
