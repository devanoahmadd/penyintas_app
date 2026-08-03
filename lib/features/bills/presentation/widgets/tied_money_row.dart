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
/// (`caption` mono UPPERCASE + `numericLg`). Baris ini menambah satu lagi:
/// "Aman dipakai" (`numericMd`). Batasnya berhenti di situ — uang yang
/// terikat TIDAK pernah diberi nama sendiri; ia hanya muncul sebagai frasa
/// di dalam kalimat detail ("Rp 200.000 terikat tagihan"). Jadi di seluruh
/// kartu hanya ada DUA besaran bernama, dan yang kedua dibaca sebagai
/// turunan dari yang pertama lewat empat isyarat non-verbal:
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
/// Frasa horizon ("Sebelum gajian") sengaja TIDAK memakai register eyebrow
/// mono-UPPERCASE-tracked. Di aplikasi ini register itu adalah penanda
/// kanonik "nama besaran" (SALDO TERKINI, HARI TERSISA, PENGELUARAN BULAN
/// INI). Kalau frasa horizon ikut memakainya, dalam satu kartu ada dua
/// eyebrow tak terbedakan dan horizon terbaca sebagai besaran ketiga.
/// Karena itu ia turun ke `bodySmall` muted sentence-case — beda keluarga
/// font (Inter Tight, bukan JetBrains Mono), beda kapitalisasi, tanpa
/// letter-spacing → jelas keterangan, bukan nama.
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
    // Emisi dashboard pertama sering datang dengan `BillCommitments.empty`
    // (data tagihan menyusul beberapa frame kemudian) → baris ini melompat
    // dari nol ke ~70dp dan mendorong isi kartu ke bawah secara mendadak.
    // `AnimatedSize` mengubah lompatan itu jadi pertumbuhan yang terbaca.
    // Saat istirahat ukurannya tetap persis ukuran anak, jadi aturan
    // sembunyi #1 (jejak nol) tidak melunak.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedSize(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: _content(context),
    );
  }

  Widget _content(BuildContext context) {
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
    final balanceClamped = _balanceClamped;

    final detailText = _detailText(context, l10n);
    final semanticLabel = _semanticLabel(
      context,
      l10n,
      isInfo: isInfo,
      balanceClamped: balanceClamped,
      detailText: detailText,
    );

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
                              balanceClamped: balanceClamped,
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

  /// Apakah saldo yang DIRENDER kartu sudah di-clamp ke 0?
  ///
  /// Kartu menampilkan `DashboardEntity.totalRemaining` yang sudah di-clamp,
  /// sementara `safeRemaining` dihitung dari nilai PRA-clamp. Saat pengguna
  /// over-spend keduanya berdampingan sebagai "Rp 0" dan "−Rp 400.000" —
  /// pengurangannya harfiah salah dan janji "besaran turunan" (spec §6.1)
  /// bohong. Di kondisi itu baris ini berhenti mengklaim turunan.
  ///
  /// KETERGANTUNGAN INTERNAL — `calculateBillCommitments` menyusun
  /// `safeRemaining = totalRemaining (pra-clamp) − tiedFlexible`
  /// (`calculateTiedMoney` mengembalikan `safe: balance - tied`, dipanggil
  /// dengan `balance: totalRemaining`). Maka saldo pra-clamp bisa
  /// direkonstruksi tanpa parameter konstruktor baru:
  ///
  ///     totalRemaining_pra-clamp = safeRemaining + tiedFlexible
  ///
  /// Kalau relasi itu berubah di usecase, deteksi ini rusak diam-diam.
  /// Test `varian C ter-clamp` di `tied_money_row_test.dart` adalah
  /// penguncinya — jangan hapus tanpa menggantinya dengan sumber saldo
  /// pra-clamp yang eksplisit.
  bool get _balanceClamped =>
      commitments.safeRemaining + commitments.tiedFlexible < 0;

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
        _horizonLine(l10n.dashboardTiedEyebrowInfo, mutedColor),
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
    required bool balanceClamped,
    required Color mutedColor,
    required Color softColor,
    required Color textColor,
    required Color alertColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _horizonLine(l10n.dashboardTiedEyebrow, mutedColor),
        const SizedBox(height: AppSpacing.xs),
        // Saldo kartu ter-clamp → nominal "Aman dipakai" dihilangkan supaya
        // tidak ada pengurangan yang tak bisa dibaca ulang oleh pengguna.
        if (!balanceClamped) ...[
          _safeValueLine(
            context,
            l10n,
            isNegative: isNegative,
            softColor: softColor,
            textColor: textColor,
            alertColor: alertColor,
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        // Operator: menjelaskan apa yang dikeluarkan dari saldo, tepat di
        // bawah angkanya — pilar ke-3 penyelesaian risiko tiga-nama.
        Text(
          detailText,
          style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
        ),
        if (isNegative) ...[
          const SizedBox(height: AppSpacing.xs),
          _negativeHint(
            l10n,
            alertColor: alertColor,
            // Ikon peringatan selalu ada persis sekali. Saat nominal tampil
            // ia menempel di nominal; saat nominal ditahan ia pindah ke hint
            // supaya status tetap punya penanda non-warna.
            withIcon: balanceClamped,
          ),
        ],
      ],
    );
  }

  /// Frasa horizon ("Sebelum gajian" / "Tagihan sebelum gajian"). Register
  /// sengaja DI BAWAH eyebrow mono-UPPERCASE — lihat catatan kelas.
  Widget _horizonLine(String text, Color mutedColor) =>
      Text(text, style: AppTextStyles.bodySmall.copyWith(color: mutedColor));

  /// Baris `Aman dipakai <nominal>`.
  ///
  /// `Wrap` + `spaceBetween`, bukan `Row` + `Expanded`: pada `Row`, nominal
  /// `numericMd` (24sp mono) tidak fleksibel sehingga selalu mengambil lebar
  /// intrinsiknya — di skala teks besar label tergencet lalu `RenderFlex`
  /// overflow di kartu paling utama. `Wrap` menaruh keduanya sebaris selama
  /// muat, dan menjatuhkan nominal ke baris berikutnya saat tidak — tanpa
  /// ambang skala yang ditebak-tebak. `FittedBox` menutup sisa kasus ekstrem
  /// (nominal sendirian lebih lebar dari kartu) tanpa ellipsis.
  Widget _safeValueLine(
    BuildContext context,
    AppLocalizations l10n, {
    required bool isNegative,
    required Color softColor,
    required Color textColor,
    required Color alertColor,
  }) {
    final nominal = _rp(context, commitments.safeRemaining);
    // Warna nominal sengaja SAMA dengan saldo saat sehat — beda warna hanya
    // menandai status negatif, bukan identitas besaran yang lain.
    final nominalColor = isNegative ? alertColor : textColor;

    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          Text(
            l10n.dashboardTiedSafeLabel,
            style: AppTextStyles.label.copyWith(color: softColor),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: _animatedValue(
                    context,
                    valueKey: nominal,
                    child: Text(
                      nominal,
                      style: AppTextStyles.numericMd.copyWith(
                        color: nominalColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _negativeHint(
    AppLocalizations l10n, {
    required Color alertColor,
    required bool withIcon,
  }) {
    final text = Text(
      l10n.dashboardTiedNegativeHint,
      style: AppTextStyles.bodySmall.copyWith(color: alertColor),
    );
    if (!withIcon) return text;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.trending_down_rounded,
          key: _negativeIconKey,
          size: 18,
          color: alertColor,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: text),
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
  ///
  /// MENYEMBUNYIKAN HARUS INSTAN. `AnimatedSwitcher` menahan child lama di
  /// tree dan mem-fade-out-nya; durasi fade-out itu terkunci di controller
  /// milik entry lama SAAT ENTRY ITU DIBUAT, jadi menurunkan `duration` di
  /// build yang menyembunyikan tidak menghapusnya lebih cepat. Satu-satunya
  /// cara yang benar-benar instan adalah mengeluarkan `AnimatedSwitcher`
  /// dari tree saat [hidden] — elemennya di-unmount berikut child lamanya.
  /// Saldo utama kartu hilang seketika saat tombol mata ditekan; kalau baris
  /// ini masih menampilkan nominal ~200 ms setelahnya, janji privasinya bocor.
  Widget _animatedValue(
    BuildContext context, {
    required String valueKey,
    required Widget child,
  }) {
    if (hidden || MediaQuery.disableAnimationsOf(context)) return child;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
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
    AppLocalizations l10n, {
    required bool isInfo,
    required bool balanceClamped,
    required String detailText,
  }) {
    if (isInfo) {
      return '${l10n.dashboardTiedEyebrowInfo}. '
          '${_rp(context, commitments.tiedTotal)} '
          '${l10n.dashboardTiedInfoSuffix}';
    }
    if (balanceClamped) {
      // Nominal turunan tidak dirender → pembaca layar pun tidak boleh
      // mendengarnya, kalau tidak klaim yang salah itu balik lewat pintu
      // belakang.
      return '${l10n.dashboardTiedEyebrow}. $detailText. '
          '${l10n.dashboardTiedNegativeHint}';
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
