import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/bills/domain/usecases/calculate_bill_commitments.dart';

/// Baris "uang terikat / sisa aman" — dipasang DI DALAM kartu saldo.
///
/// Di sinilah pivot flag P1 terlihat oleh pengguna: tagihan ber-`isFixedNeed`
/// sudah dipotong di muka lewat `fixedExpenses` sehingga hanya DITAMPILKAN,
/// sedangkan tagihan bebas benar-benar MENGURANGI sisa saldo. Tanpa
/// pemisahan ini uang yang sama terhitung dua kali dan pengguna melihat
/// uangnya lenyap ganda.
///
/// ## Risiko tiga-nama (spec §6.1)
///
/// Kartu saldo sudah punya satu besaran bernama: "SALDO TERKINI"
/// (`numericLg`). Baris ini menambah satu lagi: "Aman dipakai"
/// (`numericMd`). Batasnya berhenti di situ — uang yang terikat TIDAK
/// pernah diberi nama sendiri; ia hanya muncul sebagai frasa di dalam
/// kalimat detail ("Rp 200.000 terikat tagihan"). Jadi di seluruh kartu
/// hanya ada DUA besaran bernama, dan yang kedua dibaca sebagai turunan
/// dari yang pertama lewat empat isyarat non-verbal:
///
/// 1. Tangga tipografi menurun `numericLg` → `numericMd`, font mono yang
///    sama, rata kiri optis yang sama → terbaca sebagai kolom buku besar.
/// 2. Satu kartu, dipisah garis rambut (bukan jarak kosong) → "subjek yang
///    sama, baris berikutnya".
/// 3. Baris detail persis di bawah nominal berperan sebagai operator: ia
///    menyebutkan apa yang dikeluarkan, sehingga "kenapa lebih kecil"
///    terjawab tanpa nama baru.
/// 4. Warna nominal SAMA dengan warna saldo (varian A & B). Warna berbeda
///    hanya dipakai saat sisa aman negatif — itu status, bukan identitas.
///
/// Eyebrow "SEBELUM GAJIAN" adalah keterangan HORIZON waktu, bukan nama
/// besaran ketiga.
class TiedMoneyRow extends StatelessWidget {
  const TiedMoneyRow({
    super.key,
    required this.commitments,
    required this.hidden,
  });

  final BillCommitments commitments;

  /// §6 aturan sembunyi #2: ikut toggle privasi saldo — nominal disamarkan,
  /// struktur baris tetap (status boleh terlihat, angkanya tidak).
  final bool hidden;

  static const _mainKey = ValueKey('tied_money_row_main');
  static const _nudgeKey = ValueKey('tied_nudge');
  static const _negativeIconKey = ValueKey('tied_negative_icon');

  /// Satu-satunya pintu nominal. Semua teks DAN label Semantics dibangun
  /// dari sini, jadi mode sembunyi mustahil bocor lewat salah satu saja.
  String _rp(BuildContext context, int v) => hidden
      ? context.l10n.dashboardBalanceHidden
      : (v < 0 ? '−${formatRupiah(-v)}' : formatRupiah(v));

  @override
  Widget build(BuildContext context) {
    // Aturan sembunyi #1: tak ada tagihan sebelum gajian → nol jejak, bukan
    // baris kosong. Kartu saldo tidak boleh menyisakan celah gantung.
    if (commitments.tiedTotal == 0) return const SizedBox.shrink();

    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final softColor = isDark ? AppColors.textSoftDark : AppColors.textSoftLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final alertColor = isDark ? AppColors.expenseDark : AppColors.warn;

    // Varian A = semua tagihan sudah dianggarkan → tak ada yang dikurangkan
    // dari saldo, jadi tak ada besaran turunan yang boleh dipamerkan.
    final isInfo = commitments.tiedFlexible == 0;
    final isNegative = commitments.safeRemaining < 0;

    final detailText = _detailText(context, l10n);
    final semanticLabel = _semanticLabel(context, l10n, isInfo, detailText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        // Garis rambut, bukan jarak kosong: menandai "masih kartu yang sama,
        // baris berikutnya" — pilar ke-2 penyelesaian risiko tiga-nama.
        Container(height: 1, width: double.infinity, color: borderColor),
        Semantics(
          key: _mainKey,
          container: true,
          button: true,
          excludeSemantics: true,
          label: semanticLabel,
          onTap: () => context.push('/bills'),
          child: InkWell(
            onTap: () => context.push('/bills'),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: isInfo
                          ? _infoBody(context, l10n, mutedColor, softColor)
                          : _safeBody(
                              context,
                              l10n,
                              detailText: detailText,
                              isNegative: isNegative,
                              mutedColor: mutedColor,
                              softColor: softColor,
                              textColor: textColor,
                              alertColor: alertColor,
                            ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: mutedColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (commitments.nudgeBudgetMismatch)
          _nudge(context, l10n, softColor: softColor),
      ],
    );
  }

  // ── Varian A — baris kesadaran, TANPA besaran turunan ──────────────────
  Widget _infoBody(
    BuildContext context,
    AppLocalizations l10n,
    Color mutedColor,
    Color softColor,
  ) {
    final nominal = _rp(context, commitments.tiedTotal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.dashboardTiedEyebrowInfo,
          style: AppTextStyles.caption.copyWith(color: mutedColor),
        ),
        const SizedBox(height: AppSpacing.xs),
        _animatedValue(
          context,
          valueKey: nominal,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: nominal,
                  style: AppTextStyles.numericSm.copyWith(color: softColor),
                ),
                TextSpan(
                  text: ' ${l10n.dashboardTiedInfoSuffix}',
                  style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Varian B & C — "Aman dipakai" sebagai turunan saldo ────────────────
  Widget _safeBody(
    BuildContext context,
    AppLocalizations l10n, {
    required String detailText,
    required bool isNegative,
    required Color mutedColor,
    required Color softColor,
    required Color textColor,
    required Color alertColor,
  }) {
    final nominal = _rp(context, commitments.safeRemaining);
    // Warna nominal sengaja SAMA dengan saldo saat sehat — beda warna hanya
    // menandai status negatif, bukan identitas besaran yang lain.
    final nominalColor = isNegative ? alertColor : textColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.dashboardTiedEyebrow,
          style: AppTextStyles.caption.copyWith(color: mutedColor),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                l10n.dashboardTiedSafeLabel,
                style: AppTextStyles.label.copyWith(color: softColor),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (isNegative) ...[
              // Penanda kedua di samping warna — jangan andalkan warna saja.
              Icon(
                Icons.trending_down_rounded,
                key: _negativeIconKey,
                size: 18,
                color: alertColor,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            _animatedValue(
              context,
              valueKey: nominal,
              child: Text(
                nominal,
                style: AppTextStyles.numericMd.copyWith(color: nominalColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        // Operator: menjelaskan apa yang dikeluarkan dari saldo, tepat di
        // bawah angkanya — pilar ke-3 penyelesaian risiko tiga-nama.
        Text(
          detailText,
          style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
        ),
        if (isNegative) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.dashboardTiedNegativeHint,
            style: AppTextStyles.bodySmall.copyWith(color: alertColor),
          ),
        ],
      ],
    );
  }

  /// §6.2 — tagihan tetap melebihi kebutuhan tetap yang dianggarkan.
  /// Baris tap terpisah supaya tujuannya (`/budget/edit-settings`) tidak
  /// bertabrakan dengan tujuan baris utama (`/bills`).
  Widget _nudge(
    BuildContext context,
    AppLocalizations l10n, {
    required Color softColor,
  }) {
    return InkWell(
      key: _nudgeKey,
      onTap: () => context.push('/budget/edit-settings'),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppColors.caution,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.dashboardTiedNudge,
                  style: AppTextStyles.bodySmall.copyWith(color: softColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Nominal berubah lewat crossfade singkat supaya perubahan angka terbaca
  /// sebagai peristiwa, bukan kedipan. Dimatikan total saat pengguna minta
  /// animasi dikurangi.
  Widget _animatedValue(
    BuildContext context, {
    required String valueKey,
    required Widget child,
  }) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 200),
      child: KeyedSubtree(key: ValueKey(valueKey), child: child),
    );
  }

  /// Detail varian B & C. Segmen "sudah dianggarkan" hanya muncul kalau
  /// porsinya memang ada — nol data palsu.
  String _detailText(BuildContext context, AppLocalizations l10n) {
    final flexible =
        '${_rp(context, commitments.tiedFlexible)} '
        '${l10n.dashboardTiedDetailFlexible}';
    if (commitments.tiedFixed == 0) return flexible;
    return '$flexible · ${_rp(context, commitments.tiedFixed)} '
        '${l10n.dashboardTiedDetailBudgeted}';
  }

  /// Satu label utuh per varian, dirakit dari string yang SAMA dengan yang
  /// dirender — sehingga mode sembunyi ikut berlaku di pembaca layar.
  String _semanticLabel(
    BuildContext context,
    AppLocalizations l10n,
    bool isInfo,
    String detailText,
  ) {
    if (isInfo) {
      return '${l10n.dashboardTiedEyebrowInfo}. '
          '${_rp(context, commitments.tiedTotal)} '
          '${l10n.dashboardTiedInfoSuffix}';
    }
    final base =
        '${l10n.dashboardTiedEyebrow}. '
        '${l10n.dashboardTiedSafeLabel} '
        '${_rp(context, commitments.safeRemaining)}. $detailText';
    if (commitments.safeRemaining < 0) {
      return '$base. ${l10n.dashboardTiedNegativeHint}';
    }
    return base;
  }
}
