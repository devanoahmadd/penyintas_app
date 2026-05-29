import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';
import 'package:penyintas_app/features/budget/presentation/bloc/budget_settings_bloc.dart';

class BudgetEditSettingsPage extends StatefulWidget {
  const BudgetEditSettingsPage({super.key});

  @override
  State<BudgetEditSettingsPage> createState() => _BudgetEditSettingsPageState();
}

class _BudgetEditSettingsPageState extends State<BudgetEditSettingsPage> {
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

  bool get _hasChanges => _original != null && _buildEntity() != _original;

  int get _totalFixed =>
      _parseField(_rentCtrl) +
      _parseField(_utilitiesCtrl) +
      _parseField(_internetCtrl) +
      _parseField(_phoneCtrl) +
      _parseField(_otherCtrl);

  int get _dailyPreview {
    final income = _parseField(_incomeCtrl);
    final emergency = (income * _emergencyPct).round();
    final spendable = (income - _totalFixed - emergency).clamp(0, income);
    return spendable > 0 ? (spendable / 30).floor() : 0;
  }

  Widget _numField(TextEditingController ctrl, String label) => TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: AppTextStyles.body,
        decoration: InputDecoration(
          labelText: label,
          prefixText: 'Rp ',
          labelStyle: AppTextStyles.label,
        ),
        onChanged: (_) => setState(() {}),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return BlocConsumer<BudgetSettingsBloc, BudgetSettingsState>(
      listener: (context, state) {
        if (state is BudgetSettingsLoaded) _populateFrom(state.settings);
        if (state is BudgetSettingsSaved) Navigator.of(context).pop();
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
            title: Text('Edit Anggaran', style: AppTextStyles.h3),
            backgroundColor: bg,
            elevation: 0,
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text('PENDAPATAN', style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.sm),
                _numField(_incomeCtrl, 'Penghasilan bulanan'),
                const SizedBox(height: AppSpacing.md),
                Text('Tanggal gajian', style: AppTextStyles.label),
                const SizedBox(height: AppSpacing.sm),
                _PaymentDateGrid(
                  selected: _paymentDate,
                  onSelected: (d) => setState(() => _paymentDate = d),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('PENGELUARAN TETAP', style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.sm),
                _numField(_rentCtrl, 'Kos / kontrakan'),
                const SizedBox(height: AppSpacing.md),
                _numField(_utilitiesCtrl, 'Listrik & air'),
                const SizedBox(height: AppSpacing.md),
                _numField(_internetCtrl, 'Internet'),
                const SizedBox(height: AppSpacing.md),
                _numField(_phoneCtrl, 'Telepon'),
                const SizedBox(height: AppSpacing.md),
                _numField(_otherCtrl, 'Lainnya'),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Total: ${formatRupiah(_totalFixed)}',
                  style: AppTextStyles.label.copyWith(color: muted),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('DANA DARURAT', style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(_emergencyPct * 100).toStringAsFixed(0)}%',
                      style: AppTextStyles.numericMd,
                    ),
                    Text(
                      formatRupiah(
                          (_parseField(_incomeCtrl) * _emergencyPct).round()),
                      style: AppTextStyles.body.copyWith(color: muted),
                    ),
                  ],
                ),
                Slider(
                  value: _emergencyPct,
                  min: 0.05,
                  max: 0.25,
                  divisions: 4,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _emergencyPct = v),
                ),
                const SizedBox(height: AppSpacing.xl),
                _PreviewCard(dailyBudget: _dailyPreview, isDark: isDark),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_hasChanges && !isSaving)
                        ? () => context
                            .read<BudgetSettingsBloc>()
                            .add(SaveBudgetSettings(_buildEntity()))
                        : null,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary),
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Simpan Perubahan',
                            style: AppTextStyles.label
                                .copyWith(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PaymentDateGrid extends StatelessWidget {
  const _PaymentDateGrid(
      {required this.selected, required this.onSelected});
  final int selected;
  final void Function(int) onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                      ? AppColors.cardDark
                      : AppColors.cardLight,
              borderRadius: BorderRadius.circular(AppRadius.sm),
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

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.dailyBudget, required this.isDark});
  final int dailyBudget;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
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
          Text(formatRupiah(dailyBudget), style: AppTextStyles.numericLg),
          Text('per hari', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
