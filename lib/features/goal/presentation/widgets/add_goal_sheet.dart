import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/features/goal/presentation/bloc/goal_bloc.dart';

class AddGoalSheet extends StatefulWidget {
  const AddGoalSheet({super.key});

  @override
  State<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<AddGoalSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _targetDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final amount =
        int.tryParse(
          _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    return _titleController.text.trim().isNotEmpty &&
        amount > 0 &&
        _targetDate != null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Theme.of(ctx).brightness,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  void _submit() {
    if (!_isValid || _isSubmitting) return;
    final amount = int.parse(
      _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    setState(() => _isSubmitting = true);
    context.read<GoalBloc>().add(
      CreateGoal(
        title: _titleController.text.trim(),
        targetAmount: amount,
        targetDate: _targetDate!,
      ),
    );
    // Navigator.pop() dipanggil via BlocListener setelah CreateGoal berhasil
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    final dateStr = _targetDate != null
        ? DateFormat('d MMM yyyy', 'id_ID').format(_targetDate!)
        : null;

    return BlocListener<GoalBloc, GoalState>(
      listener: (context, state) {
        if (!_isSubmitting) return;
        if (state is GoalLoaded) {
          Navigator.of(context).pop();
        } else if (state is GoalError) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
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
              // Handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
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
                      context.l10n.goalAddTitle,
                      style: AppTextStyles.h3.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, size: 16, color: mutedColor),
                      ),
                    ),
                  ],
                ),
              ),
              // Form fields
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title field
                    _FieldLabel(context.l10n.goalTitleLabel, isDark: isDark),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _titleController,
                      style: AppTextStyles.body.copyWith(color: textColor),
                      maxLength: 50,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _inputDecoration(
                        hint: context.l10n.goalTitleHint,
                        surfaceColor: surfaceColor,
                        borderColor: borderColor,
                        mutedColor: mutedColor,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Amount field
                    _FieldLabel(context.l10n.goalAmountLabel, isDark: isDark),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _amountController,
                      style: AppTextStyles.body.copyWith(
                        color: textColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _inputDecoration(
                        hint: 'Rp 500.000',
                        prefixText: 'Rp ',
                        surfaceColor: surfaceColor,
                        borderColor: borderColor,
                        mutedColor: mutedColor,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Date picker
                    _FieldLabel(context.l10n.goalDateLabel, isDark: isDark),
                    const SizedBox(height: AppSpacing.sm),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_month_outlined,
                              size: 18,
                              color: mutedColor,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              dateStr ?? context.l10n.goalDatePickerHint,
                              style: AppTextStyles.body.copyWith(
                                color: dateStr != null ? textColor : mutedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Submit button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isValid ? _submit : null,
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
                    child: Text(
                      context.l10n.btnSave,
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
    required Color surfaceColor,
    required Color borderColor,
    required Color mutedColor,
  }) => InputDecoration(
    hintText: hint,
    prefixText: prefixText,
    hintStyle: AppTextStyles.body.copyWith(color: mutedColor),
    filled: true,
    fillColor: surfaceColor,
    counterText: '',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.primary),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.md,
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {required this.isDark});
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.label.copyWith(
        fontSize: 13,
        color: isDark ? AppColors.textSoftDark : AppColors.textSoftLight,
      ),
    );
  }
}
