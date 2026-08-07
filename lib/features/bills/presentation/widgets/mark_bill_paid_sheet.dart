import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/category_metadata.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/core/utils/date_helper.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/domain/usecases/represented_by_fixed_expenses.dart';
import 'package:penyintas_app/features/bills/presentation/bloc/bills_bloc.dart';

/// Sheet konfirmasi "tandai lunas" (spec §6.3).
///
/// Pengguna mengonfirmasi berapa yang BENAR-BENAR dibayar (bisa beda dari
/// perkiraan), kapan dibayar, apakah dihitung sebagai kebutuhan tetap, dan
/// apakah transaksi perlu dibuat (opt-out untuk yang sudah mencatat manual).
///
/// Kategori sengaja READ-ONLY: kategori transaksi diturunkan dari tagihan
/// (decoupling §4.2 — hanya `isFixed` yang datang dari event).
class MarkBillPaidSheet extends StatefulWidget {
  const MarkBillPaidSheet({super.key, required this.bill, this.fixedExpenses});

  final BillEntity bill;

  /// Total kebutuhan tetap dari BudgetSettings saat sheet dibuka.
  /// `null` = fetch gagal → FAIL-OPEN, tapi HANYA pada paruh anggaran: bentuk
  /// tagihan dan flag-nya tetap ditegakkan karena keduanya diketahui tanpa
  /// fetch. Kalau anggaran ternyata nol, gerbang M1 di `AddTransactionUseCase`
  /// tetap jadi jaring terakhir.
  final int? fixedExpenses;

  @override
  State<MarkBillPaidSheet> createState() => _MarkBillPaidSheetState();
}

class _MarkBillPaidSheetState extends State<MarkBillPaidSheet> {
  final _amountController = TextEditingController();

  late DateTime _paidDate;
  late bool _includeAsFixed;

  /// "Sudah saya catat manual" — bill tetap di-advance, transaksi tidak dibuat.
  bool _optOutTransaction = false;

  /// Pesan validasi baru ditampilkan setelah percobaan konfirmasi pertama —
  /// jangan memarahi pengguna sebelum ia sempat mengubah isian.
  bool _showErrors = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Nominal aktual DIPREFILL dari perkiraan, tapi tetap boleh diubah —
    // tagihan listrik jarang persis sama tiap bulan.
    _amountController.text = '${widget.bill.estimatedAmount}';
    _paidDate = startOfDay(DateTime.now());
    // M1 (§4.2): saat kebutuhan tetap di anggaran masih 0, tak ada potongan di
    // muka yang menaungi tagihan ini — prefill DIPAKSA false supaya
    // pembayarannya benar-benar terhitung sebagai pengeluaran.
    // `null` = fetch gagal → fail-open HANYA pada paruh anggaran. Bentuk
    // tagihan dan flag-nya tetap ditegakkan karena keduanya diketahui tanpa
    // fetch — bukan kembali ke flag polos milik tagihan.
    final fe = widget.fixedExpenses;
    _includeAsFixed = fe == null
        // fail-open: HANYA paruh anggaran yang dilonggarkan. Bentuk tagihan dan
        // flag-nya diketahui tanpa fetch, jadi tak ada alasan melupakannya.
        ? representedByFixedExpenses(widget.bill)
        : coveredUpfront(widget.bill, fe);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // ── Turunan nilai & validasi ──────────────────────────────────────────────

  int get _amount =>
      int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
      0;

  bool get _amountInvalid => _amount <= 0;

  /// §4.3: hint hanya saat prefill DIPAKSA false padahal tagihan ini memang
  /// TERWAKILI jenisnya — kontradiksi butuh penjelasan di layar.
  /// Disempitkan ke predikat bersama: tanpa itu, `yearly + isFixedNeed + fe==0`
  /// menampilkan hint terkunci DAN hint ini sekaligus.
  bool get _showM1Hint =>
      representedByFixedExpenses(widget.bill) && widget.fixedExpenses == 0;

  /// Toggle tak berlaku untuk tagihan yang tak terwakili `fixedExpenses`.
  bool get _fixedLocked => !representedByFixedExpenses(widget.bill);

  /// Presedensi: alasan BENTUK menang atas alasan FLAG, karena
  /// `yearly && !isFixedNeed` memenuhi keduanya dan hanya alasan flag yang
  /// punya jalan keluar. Menampilkan yang bisa diperbaiki lebih dulu akan
  /// mengirim pengguna mengerjakan sesuatu yang tak menolongnya.
  String _lockedHint(AppLocalizations l10n) =>
      widget.bill.recurrence == Recurrence.monthly
      ? l10n.billsPaidFixedNotFlaggedHint
      : l10n.billsPaidFixedNonMonthlyHint;

  // ── Pemilih tanggal ───────────────────────────────────────────────────────

  Widget _datePickerTheme(BuildContext ctx, Widget? child) => Theme(
    data: Theme.of(ctx).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Theme.of(ctx).brightness,
      ),
    ),
    child: child!,
  );

  Future<void> _pickPaidDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidDate,
      // Pembayaran terlambat dicatat boleh mundur…
      firstDate: DateTime(now.year - 2),
      // …tapi tidak boleh dicatat di masa depan.
      lastDate: startOfDay(now),
      builder: _datePickerTheme,
    );
    if (picked != null) setState(() => _paidDate = picked);
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  void _submit() {
    if (_isSubmitting) return;
    if (_amountInvalid) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() {
      _showErrors = false;
      _isSubmitting = true;
    });
    context.read<BillsBloc>().add(
      BillMarkedPaid(
        billId: widget.bill.id,
        actualAmount: _amount,
        paidDate: _paidDate,
        includeAsFixed: _includeAsFixed,
        optOutTransaction: _optOutTransaction,
      ),
    );
    // Navigator.pop() dipanggil via BlocListener setelah pembayaran berhasil.
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final textSoftColor = isDark
        ? AppColors.textSoftDark
        : AppColors.textSoftLight;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    // Panel input pakai token khusus sheet — terasa lebih "bersih" saat
    // mengetik angka (lihat CLAUDE.md: surfaceAltLight/Dark).
    final panelColor = isDark
        ? AppColors.surfaceAltDark
        : AppColors.surfaceAltLight;

    final bottomPad = MediaQuery.of(context).padding.bottom;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final locale = Localizations.localeOf(context).languageCode;
    final dateFormat = DateFormat('d MMM yyyy', locale);

    return BlocListener<BillsBloc, BillsState>(
      listener: (context, state) {
        if (!_isSubmitting) return;
        if (state.status == BillsStatus.success) {
          // Sheet TIDAK menampilkan surface apa pun di sini. Perayaan +
          // tawaran "Urungkan" digabung jadi SATU snackbar milik halaman
          // daftar (Task 5.4): dua surface akan saling menggusur karena
          // `MilestoneToast.show` memanggil `hideCurrentSnackBar()`, dan yang
          // hilang justru undo — jaring pengaman pengguna.
          Navigator.of(context).pop();
        } else if (state.status == BillsStatus.failure) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.billsPaidFailed)));
        }
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // ── Header ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Text(
                      l10n.billsPaidTitle,
                      style: AppTextStyles.h3.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const Spacer(),
                    _CloseButton(surfaceColor: surfaceColor, color: mutedColor),
                  ],
                ),
              ),
              // ── Isi ───────────────────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ringkasan tagihan — kategori read-only ada di sini.
                      _BillSummary(
                        bill: widget.bill,
                        dueLabel: dateFormat.format(widget.bill.dueDate),
                        cardColor: cardColor,
                        surfaceColor: surfaceColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        mutedColor: mutedColor,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Nominal aktual
                      _FieldLabel(
                        l10n.billsPaidAmountLabel,
                        isDark: isDark,
                        required: true,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        key: const ValueKey('bill_paid_amount'),
                        controller: _amountController,
                        style: AppTextStyles.numericMd.copyWith(
                          fontSize: 20,
                          color: textColor,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _inputDecoration(
                          hint: l10n.billsFormAmountHint,
                          panelColor: panelColor,
                          borderColor: borderColor,
                          mutedColor: mutedColor,
                          hasError: _showErrors && _amountInvalid,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      _ErrorText(
                        show: _showErrors && _amountInvalid,
                        message: l10n.billsPaidErrorAmount,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          l10n.billsPaidAmountNote(
                            formatRupiah(widget.bill.estimatedAmount),
                          ),
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 12,
                            color: mutedColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Tanggal bayar
                      _FieldLabel(l10n.billsPaidDateLabel, isDark: isDark),
                      const SizedBox(height: AppSpacing.sm),
                      _DateField(
                        fieldKey: const ValueKey('bill_paid_date'),
                        value: dateFormat.format(_paidDate),
                        panelColor: panelColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        onTap: _pickPaidDate,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Kebutuhan tetap
                      _ToggleTile(
                        tileKey: const ValueKey('bill_paid_fixed_row'),
                        switchKey: const ValueKey('bill_paid_fixed'),
                        value: _includeAsFixed,
                        label: l10n.billsFormFixedLabel,
                        hint: _fixedLocked
                            ? _lockedHint(l10n)
                            : l10n.billsFormFixedHint,
                        panelColor: panelColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        hintColor: _fixedLocked ? textSoftColor : null,
                        enabled: !_fixedLocked,
                        onChanged: (v) => setState(() => _includeAsFixed = v),
                      ),
                      if (_showM1Hint) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.billsPaidFixedEmptyHint,
                          key: const ValueKey('bill_paid_m1_hint'),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: mutedColor,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),

                      // Opt-out transaksi
                      _ToggleTile(
                        tileKey: const ValueKey('bill_paid_optout_row'),
                        switchKey: const ValueKey('bill_paid_optout'),
                        value: _optOutTransaction,
                        label: l10n.billsPaidOptOutLabel,
                        hint: l10n.billsPaidOptOutHint,
                        panelColor: panelColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        onChanged: (v) =>
                            setState(() => _optOutTransaction = v),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Tombol konfirmasi ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    key: const ValueKey('bill_paid_submit'),
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withValues(
                        alpha: 0.4,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.billsPaidSubmit,
                            style: AppTextStyles.label.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md + bottomPad),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required Color panelColor,
    required Color borderColor,
    required Color mutedColor,
    required bool hasError,
  }) {
    final baseBorder = hasError ? AppColors.warn : borderColor;
    return InputDecoration(
      hintText: hint,
      prefixText: 'Rp ',
      hintStyle: AppTextStyles.body.copyWith(color: mutedColor),
      filled: true,
      fillColor: panelColor,
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: baseBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: baseBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(
          color: hasError ? AppColors.warn : AppColors.primary,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
    );
  }
}

// ── Sub-komponen ─────────────────────────────────────────────────────────────

/// Ringkasan tagihan yang sedang dilunasi. Semua READ-ONLY — termasuk
/// kategori, yang di sini hanya informasi.
class _BillSummary extends StatelessWidget {
  const _BillSummary({
    required this.bill,
    required this.dueLabel,
    required this.cardColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedColor,
  });

  final BillEntity bill;
  final String dueLabel;
  final Color cardColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    // `of()` — bukan `iconFromSlug()`: slug kategori built-in ada di `_map`,
    // sedangkan `iconFromSlug` melihat namespace ikon KUSTOM sehingga semua
    // kategori built-in jatuh ke ikon grid generik.
    final (icon, iconColor) = CategoryMetadata.of(bill.category);
    final categoryLabel = CategoryMetadata.resolveLabelFromSlug(
      bill.category,
      AppLocalizations.of(context),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderColor),
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
            child: Icon(icon, size: 18, color: iconColor),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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
                        categoryLabel,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 12,
                          color: mutedColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
                        dueLabel,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 12,
                          color: mutedColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.surfaceColor, required this.color});
  final Color surfaceColor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        style: IconButton.styleFrom(backgroundColor: surfaceColor),
        icon: Icon(Icons.close, size: 16, color: color),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {required this.isDark, this.required = false});

  final String text;
  final bool isDark;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.textSoftDark : AppColors.textSoftLight;

    return Semantics(
      label: required ? '$text, ${context.l10n.billsFormRequired}' : text,
      excludeSemantics: true,
      child: Row(
        children: [
          Text(
            text,
            style: AppTextStyles.label.copyWith(fontSize: 13, color: color),
          ),
          if (required)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: Text(
                '*',
                style: AppTextStyles.label.copyWith(
                  fontSize: 13,
                  color: AppColors.warn,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.show, required this.message});
  final bool show;
  final String message;

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: AppColors.warn,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 12,
                color: AppColors.warn,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.fieldKey,
    required this.value,
    required this.panelColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedColor,
    required this.onTap,
  });

  final Key fieldKey;
  final String value;
  final Color panelColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: fieldKey,
      color: panelColor,
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
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: mutedColor,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  value,
                  style: AppTextStyles.body.copyWith(color: textColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
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

  @override
  Widget build(BuildContext context) {
    // MergeSemantics TANPA SYARAT: label + hint + state switch diumumkan
    // sebagai satu node di SEMUA state. Memasangnya kondisional membuat bentuk
    // pengumuman screen-reader berubah-ubah untuk kontrol yang sama.
    return MergeSemantics(
      child: Material(
        key: tileKey,
        color: panelColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: enabled ? () => onChanged(!value) : null,
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
                    // Warna mati dipaksa lewat WidgetStatePropertyAll supaya
                    // state `disabled` Material tidak menimpanya dengan abu-abu
                    // default yang di luar palet.
                    thumbColor: enabled
                        ? null
                        : WidgetStatePropertyAll(mutedColor),
                    trackColor: enabled
                        ? null
                        : WidgetStatePropertyAll(borderColor),
                    // Outline WAJIB ikut dipaksa. `border*` di atas panel
                    // `surfaceAlt*` cuma 1,07:1 (dark) / 1,28:1 (light) — track
                    // sendirian LENYAP ke dalam panel dan yang tersisa di layar
                    // hanya titik thumb mengambang, bukan "switch yang mati".
                    // `muted*` mengembalikan bentuknya: 3,51:1 (dark) / 4,65:1
                    // (light), lulus ambang 3:1 komponen non-teks.
                    trackOutlineColor: enabled
                        ? null
                        : WidgetStatePropertyAll(mutedColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
