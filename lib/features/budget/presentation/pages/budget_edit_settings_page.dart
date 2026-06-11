import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/core/utils/date_helper.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';
import 'package:penyintas_app/features/budget/presentation/bloc/budget_limits_bloc.dart';
import 'package:penyintas_app/features/budget/presentation/bloc/budget_settings_bloc.dart';
import 'package:penyintas_app/widgets/common/primary_button.dart';

/// #251 A1b: budget hanya boleh disimpan bila income > 0 dan memang ada
/// perubahan. Mencegah user menulis income=0 (yang akan menjebak app).
bool canSaveBudget({required int income, required bool hasChanges}) =>
    hasChanges && income > 0;

class BudgetEditSettingsPage extends StatefulWidget {
  const BudgetEditSettingsPage({super.key});

  @override
  State<BudgetEditSettingsPage> createState() =>
      _BudgetEditSettingsPageState();
}

class _BudgetEditSettingsPageState
    extends State<BudgetEditSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _incomeCtrl;
  late TextEditingController _rentCtrl;
  late TextEditingController _utilitiesCtrl;
  late TextEditingController _internetCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _otherCtrl;
  late int _paymentDate;
  late double _emergencyPct;
  BudgetSettingsEntity? _original;

  @override
  void initState() {
    super.initState();
    _incomeCtrl = TextEditingController();
    _rentCtrl = TextEditingController();
    _utilitiesCtrl = TextEditingController();
    _internetCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _otherCtrl = TextEditingController();
    _paymentDate = 25;
    _emergencyPct = 0.10;
  }

  @override
  void dispose() {
    _incomeCtrl.dispose();
    _rentCtrl.dispose();
    _utilitiesCtrl.dispose();
    _internetCtrl.dispose();
    _phoneCtrl.dispose();
    _otherCtrl.dispose();
    super.dispose();
  }

  void _populateFrom(BudgetSettingsEntity s) {
    if (_original != null) return;
    _original = s;
    _incomeCtrl.text = s.monthlyIncome.toString();
    _rentCtrl.text = s.rentExpense.toString();
    _utilitiesCtrl.text = s.utilitiesExpense.toString();
    _internetCtrl.text = s.internetExpense.toString();
    _phoneCtrl.text = s.phoneExpense.toString();
    _otherCtrl.text = s.otherFixedExpense.toString();
    setState(() {
      _paymentDate = s.paymentDate;
      _emergencyPct = s.emergencyFundPct;
    });
  }

  int _parseField(TextEditingController ctrl) =>
      int.tryParse(ctrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;

  BudgetSettingsEntity _buildEntity() => BudgetSettingsEntity(
        monthlyIncome: _parseField(_incomeCtrl),
        paymentDate: _paymentDate,
        emergencyFundPct: _emergencyPct,
        createdAt: _original?.createdAt ?? DateTime.now(),
        rentExpense: _parseField(_rentCtrl),
        utilitiesExpense: _parseField(_utilitiesCtrl),
        internetExpense: _parseField(_internetCtrl),
        phoneExpense: _parseField(_phoneCtrl),
        otherFixedExpense: _parseField(_otherCtrl),
      );

  bool get _hasChanges =>
      _original != null && _buildEntity() != _original;

  int get _totalFixed =>
      _parseField(_rentCtrl) +
      _parseField(_utilitiesCtrl) +
      _parseField(_internetCtrl) +
      _parseField(_phoneCtrl) +
      _parseField(_otherCtrl);

  int get _dailyPreview {
    final income = _parseField(_incomeCtrl);
    final emergency = (income * _emergencyPct).round();
    final spendable =
        (income - _totalFixed - emergency).clamp(0, income);
    if (spendable <= 0) return 0;
    // Pakai hari nyata dalam siklus (bukan hardcode 30)
    final cycleDays = daysInCycle(_paymentDate);
    return (spendable / cycleDays).floor();
  }

  // ── Money field — AppTextField-consistent styling with Rp prefix ─────────
  Widget _moneyField(
    TextEditingController ctrl,
    String label, {
    bool isDark = false,
    String? errorText,
  }) {
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor =
        isDark ? AppColors.textDark : AppColors.textLight;
    final hintColor =
        isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final fillColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: AppTextStyles.label.copyWith(color: textColor)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTextStyles.body.copyWith(color: textColor),
          decoration: InputDecoration(
            prefixText: 'Rp ',
            prefixStyle: AppTextStyles.body.copyWith(color: hintColor),
            hintText: '0',
            hintStyle: AppTextStyles.body.copyWith(color: hintColor),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 1),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(12)),
              borderSide:
                  BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.warn),
          ),
        ],
      ],
    );
  }

  // ── Section card container ────────────────────────────────────────────────
  Widget _sectionCard({
    required bool isDark,
    required String title,
    required List<Widget> children,
  }) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return BlocConsumer<BudgetSettingsBloc, BudgetSettingsState>(
      listener: (context, state) {
        if (state is BudgetSettingsLoaded) _populateFrom(state.settings);
        // Kirim `true` sebagai result agar caller tahu ada perubahan yang disimpan
        // (fix finding #6 — conditional reload di budget_overview_page).
        if (state is BudgetSettingsSaved) Navigator.of(context).pop(true);
        if (state is BudgetSettingsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final isSaving = state is BudgetSettingsSaving;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            title: Text('Atur Anggaran', style: AppTextStyles.h3),
            backgroundColor: bg,
            elevation: 0,
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              children: [
                // ── Section: Pendapatan ─────────────────────────────────
                _sectionCard(
                  isDark: isDark,
                  title: 'PENDAPATAN',
                  children: [
                    _moneyField(_incomeCtrl, 'Penghasilan bulanan',
                        isDark: isDark,
                        errorText: _parseField(_incomeCtrl) <= 0
                            ? 'Penghasilan harus diisi dulu, ya.'
                            : null),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Tanggal gajian',
                        style: AppTextStyles.label),
                    const SizedBox(height: AppSpacing.sm),
                    _PaymentDateGrid(
                      selected: _paymentDate,
                      isDark: isDark,
                      onSelected: (d) =>
                          setState(() => _paymentDate = d),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Section: Pengeluaran Tetap ───────────────────────────
                _sectionCard(
                  isDark: isDark,
                  title: 'PENGELUARAN TETAP',
                  children: [
                    _moneyField(_rentCtrl, 'Kos / kontrakan',
                        isDark: isDark),
                    const SizedBox(height: AppSpacing.md),
                    _moneyField(_utilitiesCtrl, 'Listrik & air',
                        isDark: isDark),
                    const SizedBox(height: AppSpacing.md),
                    _moneyField(_internetCtrl, 'Internet',
                        isDark: isDark),
                    const SizedBox(height: AppSpacing.md),
                    _moneyField(_phoneCtrl, 'Telepon',
                        isDark: isDark),
                    const SizedBox(height: AppSpacing.md),
                    _moneyField(_otherCtrl, 'Lainnya',
                        isDark: isDark),
                    const SizedBox(height: AppSpacing.md),
                    // Total line
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total tetap',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: muted)),
                        Text(
                          formatRupiah(_totalFixed),
                          style: AppTextStyles.numericSm
                              .copyWith(color: muted),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Section: Dana Darurat ────────────────────────────────
                _sectionCard(
                  isDark: isDark,
                  title: 'DANA DARURAT',
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(_emergencyPct * 100).toStringAsFixed(0)}%',
                          style: AppTextStyles.numericMd,
                        ),
                        Text(
                          formatRupiah((_parseField(_incomeCtrl) *
                                  _emergencyPct)
                              .round()),
                          style: AppTextStyles.body
                              .copyWith(color: muted),
                        ),
                      ],
                    ),
                    Slider(
                      value: _emergencyPct,
                      min: 0.05,
                      max: 0.25,
                      divisions: 4,
                      activeColor: AppColors.primary,
                      onChanged: (v) =>
                          setState(() => _emergencyPct = v),
                    ),
                    Text(
                      'Direkomendasikan 10–20% dari penghasilan.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: muted),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Preview card ─────────────────────────────────────────
                _PreviewCard(
                    dailyBudget: _dailyPreview, isDark: isDark),
                const SizedBox(height: AppSpacing.lg),

                // ── Kelola Kategori ───────────────────────────────────────
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Kelola Kategori'),
                  subtitle: Text(
                    'Tambah atau hapus kategori kustom',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await context.push('/budget/categories');
                    if (context.mounted) {
                      context
                          .read<BudgetLimitsBloc>()
                          .add(const LoadBudgetLimits());
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Save button ──────────────────────────────────────────
                PrimaryButton(
                  label: 'Simpan Perubahan',
                  isLoading: isSaving,
                  isEnabled: canSaveBudget(
                    income: _parseField(_incomeCtrl),
                    hasChanges: _hasChanges,
                  ),
                  onPressed: () => context
                      .read<BudgetSettingsBloc>()
                      .add(SaveBudgetSettings(_buildEntity())),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Payment date grid ────────────────────────────────────────────────────────

class _PaymentDateGrid extends StatelessWidget {
  const _PaymentDateGrid({
    required this.selected,
    required this.isDark,
    required this.onSelected,
  });

  final int selected;
  final bool isDark;
  final void Function(int) onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: List.generate(31, (i) {
        final day = i + 1;
        final isSelected = day == selected;
        return GestureDetector(
          onTap: () => onSelected(day),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight,
              borderRadius:
                  BorderRadius.circular(AppRadius.sm),
              border: isSelected
                  ? null
                  : Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                      width: 0.5,
                    ),
            ),
            child: Text(
              '$day',
              style: AppTextStyles.label.copyWith(
                color: isSelected ? Colors.white : null,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Preview card ─────────────────────────────────────────────────────────────

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.dailyBudget, required this.isDark});
  final int dailyBudget;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Text('ANGGARAN HARIAN', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.sm),
          Text(formatRupiah(dailyBudget),
              style: AppTextStyles.numericLg),
          const SizedBox(height: 2),
          Text(
            'per hari yang bisa kamu gunakan',
            style: AppTextStyles.bodySmall.copyWith(color: muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
