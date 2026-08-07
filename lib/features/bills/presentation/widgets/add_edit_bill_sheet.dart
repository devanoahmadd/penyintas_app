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
import 'package:penyintas_app/features/bills/data/models/bill_model.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/presentation/bloc/bills_bloc.dart';

/// Kategori yang boleh dipilih untuk tagihan.
///
/// `income` SENGAJA dikecualikan — tagihan selalu pengeluaran, jadi memilih
/// kategori pemasukan akan mengotori laporan saat "tandai lunas" mencatat
/// transaksi (spec §4.2).
const kBillCategorySlugs = <String>[
  'fixed',
  'food',
  'transport',
  'shopping',
  'health',
  'internet',
  'other',
];

/// Batas akhir perulangan — spec §4.1 mewajibkan MAKSIMAL SATU yang non-null.
enum _TenorMode { unlimited, count, endDate }

/// Pilihan pengingat di form. Pemetaan ke payload lihat [_reminderPayload].
enum _ReminderMode { followSettings, d3, d1, dayOf, off }

/// Sheet tambah/ubah tagihan.
///
/// [initial] null → mode tambah (emit [BillAdded]); selain itu mode ubah
/// (emit [BillUpdated] dengan `cloudId`, progres cicilan, status, dan
/// `createdAt` milik tagihan lama dipertahankan).
class AddEditBillSheet extends StatefulWidget {
  const AddEditBillSheet({super.key, this.initial});

  final BillEntity? initial;

  @override
  State<AddEditBillSheet> createState() => _AddEditBillSheetState();
}

class _AddEditBillSheetState extends State<AddEditBillSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _installmentController = TextEditingController();

  String? _category;
  DateTime? _dueDate;
  Recurrence _recurrence = Recurrence.monthly;
  _TenorMode _tenorMode = _TenorMode.unlimited;
  DateTime? _recurrenceEndDate;
  bool _isFixedNeed = false;
  _ReminderMode _reminder = _ReminderMode.followSettings;

  /// Pesan validasi baru ditampilkan setelah percobaan simpan pertama —
  /// jangan memarahi pengguna sebelum ia sempat mengisi.
  bool _showErrors = false;
  bool _isSubmitting = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial == null) return;

    _nameController.text = initial.name;
    _amountController.text = '${initial.estimatedAmount}';
    _notesController.text = initial.notes ?? '';
    _category = initial.category;
    _dueDate = initial.dueDate;
    _recurrence = initial.recurrence;
    _isFixedNeed = initial.isFixedNeed;
    _recurrenceEndDate = initial.recurrenceEndDate;
    if (initial.installmentTotal != null) {
      _tenorMode = _TenorMode.count;
      _installmentController.text = '${initial.installmentTotal}';
    } else if (initial.recurrenceEndDate != null) {
      _tenorMode = _TenorMode.endDate;
    }
    _reminder = _reminderModeOf(
      enabled: initial.reminderEnabled,
      daysBefore: initial.reminderDaysBefore,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _installmentController.dispose();
    super.dispose();
  }

  // ── Turunan nilai ─────────────────────────────────────────────────────────

  int get _amount =>
      int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
      0;

  int? get _installmentTotal => int.tryParse(
    _installmentController.text.replaceAll(RegExp(r'[^0-9]'), ''),
  );

  bool get _isRecurring => _recurrence != Recurrence.none;

  /// Pemetaan pilihan pengingat → payload.
  ///
  /// `daysBefore == null` saat aktif berarti "warisi default global" —
  /// diresolusi oleh scheduler (Task 6.1), BUKAN dibaca dari DB di sini.
  (bool enabled, int? daysBefore) get _reminderPayload => switch (_reminder) {
    _ReminderMode.off => (false, null),
    _ReminderMode.followSettings => (true, null),
    _ReminderMode.d3 => (true, 3),
    _ReminderMode.d1 => (true, 1),
    _ReminderMode.dayOf => (true, 0),
  };

  /// Kebalikan [_reminderPayload] untuk prefill mode ubah. Nilai `daysBefore`
  /// di luar {0,1,3} (mis. dari versi lama) jatuh ke "ikut pengaturan".
  static _ReminderMode _reminderModeOf({
    required bool enabled,
    required int? daysBefore,
  }) {
    if (!enabled) return _ReminderMode.off;
    return switch (daysBefore) {
      3 => _ReminderMode.d3,
      1 => _ReminderMode.d1,
      0 => _ReminderMode.dayOf,
      _ => _ReminderMode.followSettings,
    };
  }

  // ── Validasi ──────────────────────────────────────────────────────────────

  bool get _nameInvalid => _nameController.text.trim().isEmpty;
  bool get _amountInvalid => _amount <= 0;
  bool get _categoryInvalid => _category == null;
  bool get _dueDateInvalid => _dueDate == null;
  bool get _tenorCountInvalid =>
      _isRecurring &&
      _tenorMode == _TenorMode.count &&
      (_installmentTotal == null || _installmentTotal! <= 0);
  bool get _tenorEndDateInvalid =>
      _isRecurring &&
      _tenorMode == _TenorMode.endDate &&
      _recurrenceEndDate == null;

  bool get _isValid =>
      !_nameInvalid &&
      !_amountInvalid &&
      !_categoryInvalid &&
      !_dueDateInvalid &&
      !_tenorCountInvalid &&
      !_tenorEndDateInvalid;

  // ── Mutasi state (penjaga invariant) ──────────────────────────────────────

  void _selectCategory(String slug) {
    setState(() {
      _category = slug;
      // Default cerdas: kategori "kebutuhan tetap" menyalakan toggle sekali.
      // Pengguna tetap bebas mematikannya lagi — tidak ditimpa tiap rebuild.
      if (slug == 'fixed') _isFixedNeed = true;
    });
  }

  void _selectRecurrence(Recurrence value) {
    setState(() {
      _recurrence = value;
      if (value == Recurrence.none) {
        // Spec §4.1: tagihan sekali-jalan tidak punya tenor sama sekali.
        _tenorMode = _TenorMode.unlimited;
        _installmentController.clear();
        _recurrenceEndDate = null;
      }
    });
  }

  /// INVARIANT §4.1 (maks 1 batas tenor non-null) ditegakkan DI SINI:
  /// berpindah mode WAJIB mengosongkan field mode lain — bukan sekadar
  /// menyembunyikannya, supaya payload tidak pernah membawa dua batas.
  void _selectTenorMode(_TenorMode mode) {
    setState(() {
      _tenorMode = mode;
      if (mode != _TenorMode.count) _installmentController.clear();
      if (mode != _TenorMode.endDate) _recurrenceEndDate = null;
    });
  }

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

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      // Tagihan terlambat boleh dicatat mundur.
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 10),
      builder: _datePickerTheme,
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickRecurrenceEndDate() async {
    final base = _dueDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _recurrenceEndDate ?? DateTime(base.year + 1, base.month, base.day),
      firstDate: base,
      lastDate: DateTime(base.year + 20),
      builder: _datePickerTheme,
    );
    if (picked != null) setState(() => _recurrenceEndDate = picked);
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  BillModel _buildModel() {
    final now = DateTime.now();
    final initial = widget.initial;
    final notes = _notesController.text.trim();
    final (reminderEnabled, reminderDaysBefore) = _reminderPayload;

    return BillModel(
      cloudId: initial?.cloudId,
      name: _nameController.text.trim(),
      estimatedAmount: _amount,
      category: _category!,
      isFixedNeed: _isFixedNeed,
      notes: notes.isEmpty ? null : notes,
      dueDate: _dueDate!,
      recurrence: _recurrence,
      // Kedua batas tenor dibaca APA ADANYA — invariant "maks 1 non-null"
      // sudah dijaga di _selectTenorMode. Non-recurring → keduanya null.
      installmentTotal: _isRecurring ? _installmentTotal : null,
      recurrenceEndDate: _isRecurring ? _recurrenceEndDate : null,
      // Anchor roll-forward diambil dari tanggal jatuh tempo awal.
      dueDayOfMonth: _isRecurring ? _dueDate!.day : null,
      installmentsPaid: initial?.installmentsPaid ?? 0,
      reminderDaysBefore: reminderDaysBefore,
      reminderEnabled: reminderEnabled,
      status: initial?.status ?? BillStatus.active,
      createdAt: initial?.createdAt ?? now,
      updatedAt: now,
    );
  }

  void _submit() {
    if (_isSubmitting) return;
    if (!_isValid) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() {
      _showErrors = false;
      _isSubmitting = true;
    });
    final model = _buildModel();
    final bloc = context.read<BillsBloc>();
    bloc.add(_isEdit ? BillUpdated(model) : BillAdded(model));
    // Navigator.pop() dipanggil via BlocListener setelah simpan berhasil.
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
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
          Navigator.of(context).pop();
        } else if (state.status == BillsStatus.failure) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.billsFormSaveFailed)));
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
                      _isEdit
                          ? l10n.billsFormEditTitle
                          : l10n.billsFormAddTitle,
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
              // ── Isi form ──────────────────────────────────────────────────
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
                      // Nama
                      _FieldLabel(
                        l10n.billsFormNameLabel,
                        isDark: isDark,
                        required: true,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        key: const ValueKey('bill_form_name'),
                        controller: _nameController,
                        style: AppTextStyles.body.copyWith(color: textColor),
                        maxLength: 50,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _inputDecoration(
                          hint: l10n.billsFormNameHint,
                          panelColor: panelColor,
                          borderColor: borderColor,
                          mutedColor: mutedColor,
                          hasError: _showErrors && _nameInvalid,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      _ErrorText(
                        show: _showErrors && _nameInvalid,
                        message: l10n.billsFormErrorName,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Nominal
                      _FieldLabel(
                        l10n.billsFormAmountLabel,
                        isDark: isDark,
                        required: true,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        key: const ValueKey('bill_form_amount'),
                        controller: _amountController,
                        style: AppTextStyles.numericSm.copyWith(
                          fontSize: 16,
                          color: textColor,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _inputDecoration(
                          hint: l10n.billsFormAmountHint,
                          prefixText: 'Rp ',
                          panelColor: panelColor,
                          borderColor: borderColor,
                          mutedColor: mutedColor,
                          hasError: _showErrors && _amountInvalid,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      _ErrorText(
                        show: _showErrors && _amountInvalid,
                        message: l10n.billsFormErrorAmount,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Kategori
                      _FieldLabel(
                        l10n.billsFormCategoryLabel,
                        isDark: isDark,
                        required: true,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final slug in kBillCategorySlugs)
                            _ChoicePill(
                              label: CategoryMetadata.resolveLabelFromSlug(
                                slug,
                                AppLocalizations.of(context),
                              ),
                              // `of()` — bukan `iconFromSlug()`: slug kategori
                              // built-in ada di `_map`, sedangkan
                              // `iconFromSlug` melihat namespace ikon KUSTOM
                              // (`restaurant`/`coffee`/…) sehingga semua
                              // kategori jatuh ke ikon grid generik.
                              icon: CategoryMetadata.of(slug).$1,
                              selected: _category == slug,
                              panelColor: panelColor,
                              borderColor: borderColor,
                              textColor: textColor,
                              onTap: () => _selectCategory(slug),
                            ),
                        ],
                      ),
                      _ErrorText(
                        show: _showErrors && _categoryInvalid,
                        message: l10n.billsFormErrorCategory,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Jatuh tempo
                      _FieldLabel(
                        l10n.billsFormDueDateLabel,
                        isDark: isDark,
                        required: true,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _DateField(
                        fieldKey: const ValueKey('bill_form_due_date'),
                        value: _dueDate != null
                            ? dateFormat.format(_dueDate!)
                            : null,
                        hint: l10n.billsFormDueDateHint,
                        panelColor: panelColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        hasError: _showErrors && _dueDateInvalid,
                        onTap: _pickDueDate,
                      ),
                      _ErrorText(
                        show: _showErrors && _dueDateInvalid,
                        message: l10n.billsFormErrorDueDate,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Pengulangan
                      _FieldLabel(
                        l10n.billsFormRecurrenceLabel,
                        isDark: isDark,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final (value, label) in <(Recurrence, String)>[
                            (Recurrence.none, l10n.billsRecurrenceNone),
                            (Recurrence.monthly, l10n.billsRecurrenceMonthly),
                            (Recurrence.yearly, l10n.billsRecurrenceYearly),
                          ])
                            _ChoicePill(
                              label: label,
                              selected: _recurrence == value,
                              panelColor: panelColor,
                              borderColor: borderColor,
                              textColor: textColor,
                              onTap: () => _selectRecurrence(value),
                            ),
                        ],
                      ),

                      // Tenor — hanya relevan saat tagihan berulang.
                      if (_isRecurring) ...[
                        const SizedBox(height: AppSpacing.md),
                        _FieldLabel(l10n.billsFormTenorLabel, isDark: isDark),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final (value, label) in <(_TenorMode, String)>[
                              (_TenorMode.unlimited, l10n.billsTenorUnlimited),
                              (_TenorMode.count, l10n.billsTenorCount),
                              (_TenorMode.endDate, l10n.billsTenorEndDate),
                            ])
                              _ChoicePill(
                                label: label,
                                selected: _tenorMode == value,
                                panelColor: panelColor,
                                borderColor: borderColor,
                                textColor: textColor,
                                onTap: () => _selectTenorMode(value),
                              ),
                          ],
                        ),
                        if (_tenorMode == _TenorMode.count) ...[
                          const SizedBox(height: AppSpacing.md),
                          _FieldLabel(
                            l10n.billsFormTenorCountLabel,
                            isDark: isDark,
                            required: true,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            key: const ValueKey('bill_form_installment'),
                            controller: _installmentController,
                            style: AppTextStyles.numericSm.copyWith(
                              fontSize: 16,
                              color: textColor,
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 3,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: _inputDecoration(
                              hint: l10n.billsFormTenorCountHint,
                              panelColor: panelColor,
                              borderColor: borderColor,
                              mutedColor: mutedColor,
                              hasError: _showErrors && _tenorCountInvalid,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          _ErrorText(
                            show: _showErrors && _tenorCountInvalid,
                            message: l10n.billsFormErrorTenorCount,
                          ),
                        ],
                        if (_tenorMode == _TenorMode.endDate) ...[
                          const SizedBox(height: AppSpacing.md),
                          _FieldLabel(
                            l10n.billsFormTenorEndDateLabel,
                            isDark: isDark,
                            required: true,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _DateField(
                            fieldKey: const ValueKey('bill_form_end_date'),
                            value: _recurrenceEndDate != null
                                ? dateFormat.format(_recurrenceEndDate!)
                                : null,
                            hint: l10n.billsFormTenorEndDateHint,
                            panelColor: panelColor,
                            borderColor: borderColor,
                            textColor: textColor,
                            mutedColor: mutedColor,
                            hasError: _showErrors && _tenorEndDateInvalid,
                            onTap: _pickRecurrenceEndDate,
                          ),
                          _ErrorText(
                            show: _showErrors && _tenorEndDateInvalid,
                            message: l10n.billsFormErrorTenorEndDate,
                          ),
                        ],
                      ],
                      const SizedBox(height: AppSpacing.md),

                      // Kebutuhan tetap
                      _FixedNeedToggle(
                        value: _isFixedNeed,
                        label: l10n.billsFormFixedLabel,
                        // Hint lama menjanjikan "bukan potong jatah harian
                        // kamu" — tidak benar untuk tagihan non-bulanan, yang
                        // sejak gelombang ini SELALU dihitung sebagai
                        // pengeluaran saat dibayar. Toggle-nya tetap hidup:
                        // `isFixedNeed` adalah pernyataan NIAT pengguna,
                        // penyempitannya terjadi di titik pakai.
                        hint: _recurrence == Recurrence.monthly
                            ? l10n.billsFormFixedHint
                            : l10n.billsFormFixedHintNonMonthly,
                        panelColor: panelColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        onChanged: (v) => setState(() => _isFixedNeed = v),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Pengingat
                      _FieldLabel(l10n.billsFormReminderLabel, isDark: isDark),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final (value, label)
                              in <(_ReminderMode, String)>[
                                (
                                  _ReminderMode.followSettings,
                                  l10n.billsReminderDefault,
                                ),
                                (_ReminderMode.d3, l10n.billsReminderD3),
                                (_ReminderMode.d1, l10n.billsReminderD1),
                                (_ReminderMode.dayOf, l10n.billsReminderDayOf),
                                (_ReminderMode.off, l10n.billsReminderOff),
                              ])
                            _ChoicePill(
                              label: label,
                              selected: _reminder == value,
                              panelColor: panelColor,
                              borderColor: borderColor,
                              textColor: textColor,
                              onTap: () => setState(() => _reminder = value),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Catatan
                      _FieldLabel(
                        l10n.billsFormNotesLabel,
                        isDark: isDark,
                        optionalNote: l10n.billsFormNotesOptional,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        key: const ValueKey('bill_form_notes'),
                        controller: _notesController,
                        style: AppTextStyles.body.copyWith(color: textColor),
                        maxLength: 120,
                        maxLines: 2,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _inputDecoration(
                          hint: l10n.billsFormNotesHint,
                          panelColor: panelColor,
                          borderColor: borderColor,
                          mutedColor: mutedColor,
                          hasError: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Tombol simpan ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    key: const ValueKey('bill_form_submit'),
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
                            l10n.btnSave,
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
    String? prefixText,
    required Color panelColor,
    required Color borderColor,
    required Color mutedColor,
    required bool hasError,
  }) {
    final baseBorder = hasError ? AppColors.warn : borderColor;
    return InputDecoration(
      hintText: hint,
      prefixText: prefixText,
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
  const _FieldLabel(
    this.text, {
    required this.isDark,
    this.required = false,
    this.optionalNote,
  });

  final String text;
  final bool isDark;
  final bool required;

  /// Ditampilkan sebagai "(opsional)" untuk field yang boleh dikosongkan.
  final String? optionalNote;

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.textSoftDark : AppColors.textSoftLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Semantics(
      label: required
          ? '$text, ${context.l10n.billsFormRequired}'
          : (optionalNote != null ? '$text, $optionalNote' : text),
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
          if (optionalNote != null)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: Text(
                '($optionalNote)',
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  color: mutedColor,
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

/// Chip pilihan tunggal. Selalu berteks — warna hanya penguat.
class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.panelColor,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final Color panelColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : textColor;

    return Material(
      color: selected ? AppColors.primary : panelColor,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? AppColors.primary : borderColor,
            ),
          ),
          child: Container(
            // Hit target minimum Android 48dp.
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md2),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: fg),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 13,
                    color: fg,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.fieldKey,
    required this.value,
    required this.hint,
    required this.panelColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedColor,
    required this.hasError,
    required this.onTap,
  });

  final Key fieldKey;
  final String? value;
  final String hint;
  final Color panelColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedColor;
  final bool hasError;
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
            border: Border.all(color: hasError ? AppColors.warn : borderColor),
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
                  value ?? hint,
                  style: AppTextStyles.body.copyWith(
                    color: value != null ? textColor : mutedColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FixedNeedToggle extends StatelessWidget {
  const _FixedNeedToggle({
    required this.value,
    required this.label,
    required this.hint,
    required this.panelColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedColor,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final String hint;
  final Color panelColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedColor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: panelColor,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: () => onChanged(!value),
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
                          color: mutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
