import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/add_transaction_bloc.dart';

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _noteController = TextEditingController();
  String _rawInput = '0';

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    setState(() {
      if (digit == 'del') {
        _rawInput =
            _rawInput.length <= 1 ? '0' : _rawInput.substring(0, _rawInput.length - 1);
      } else if (_rawInput == '0') {
        _rawInput = digit == '000' ? '0' : digit;
      } else {
        final next = _rawInput + digit;
        if (int.tryParse(next) != null && int.parse(next) <= 100000000) {
          _rawInput = next;
        }
      }
    });
    final amount = int.tryParse(_rawInput) ?? 0;
    context.read<AddTransactionBloc>().add(AmountChanged(amount));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return BlocListener<AddTransactionBloc, AddTransactionState>(
      listener: (context, state) {
        if (state is AddTransactionSuccess) Navigator.of(context).pop(true);
        if (state is AddTransactionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.xl)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),
              _Handle(borderColor: borderColor),
              const SizedBox(height: AppSpacing.lg),
              _AmountDisplay(rawInput: _rawInput),
              const SizedBox(height: AppSpacing.lg),
              _CategoryGrid(),
              const SizedBox(height: AppSpacing.md),
              _NoteField(controller: _noteController),
              const SizedBox(height: AppSpacing.sm),
              _DateChip(),
              const SizedBox(height: AppSpacing.md),
              _Numpad(onDigit: _onDigit),
              const SizedBox(height: AppSpacing.md),
              _SubmitButton(),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle({required this.borderColor});
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: borderColor,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
    );
  }
}

class _AmountDisplay extends StatelessWidget {
  const _AmountDisplay({required this.rawInput});
  final String rawInput;

  @override
  Widget build(BuildContext context) {
    final amount = int.tryParse(rawInput) ?? 0;
    return BlocBuilder<AddTransactionBloc, AddTransactionState>(
      builder: (context, state) {
        final isExpense = state is AddTransactionInProgress
            ? state.type == TransactionType.expense
            : true;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                formatRupiah(amount),
                style: AppTextStyles.h1.copyWith(
                  fontFamily: 'JetBrainsMono',
                  color: AppColors.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              GestureDetector(
                onTap: () =>
                    context.read<AddTransactionBloc>().add(const TypeToggled()),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: isExpense
                        ? AppColors.warn.withAlpha(30)
                        : AppColors.success.withAlpha(30),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    isExpense ? 'Keluar' : 'Masuk',
                    style: AppTextStyles.caption.copyWith(
                      color: isExpense ? AppColors.warn : AppColors.success,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}

class _CategoryGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddTransactionBloc, AddTransactionState>(
      builder: (context, state) {
        final selected = state is AddTransactionInProgress
            ? state.category
            : TransactionCategory.food;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: TransactionCategory.values
                .where((c) => c != TransactionCategory.income)
                .map((cat) => _CategoryChip(
                      category: cat,
                      isSelected: cat == selected,
                      onTap: () => context
                          .read<AddTransactionBloc>()
                          .add(CategorySelected(cat)),
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final TransactionCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(20)
              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
        child: Text(
          _label(category),
          style: AppTextStyles.caption.copyWith(
            color: isSelected ? AppColors.primary : null,
          ),
        ),
      ),
    );
  }

  String _label(TransactionCategory cat) {
    switch (cat) {
      case TransactionCategory.food: return 'Makan';
      case TransactionCategory.transport: return 'Transport';
      case TransactionCategory.campus: return 'Kampus';
      case TransactionCategory.data: return 'Internet';
      case TransactionCategory.shopping: return 'Belanja';
      case TransactionCategory.fixed: return 'Tetap';
      case TransactionCategory.other: return 'Lainnya';
      case TransactionCategory.income: return 'Masuk';
    }
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: TextField(
        controller: controller,
        style: AppTextStyles.body,
        keyboardType: TextInputType.none,
        decoration: InputDecoration(
          hintText: 'Catatan (opsional)',
          hintStyle: AppTextStyles.body.copyWith(
            color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.md),
            borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.md),
            borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          isDense: true,
        ),
        onChanged: (v) =>
            context.read<AddTransactionBloc>().add(NoteChanged(v)),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddTransactionBloc, AddTransactionState>(
      builder: (context, state) {
        final date = state is AddTransactionInProgress ? state.date : DateTime.now();
        final isToday = _isToday(date);
        final label = isToday
            ? 'Hari ini'
            : DateFormat('d MMM', 'id_ID').format(date);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (picked != null && context.mounted) {
                  context
                      .read<AddTransactionBloc>()
                      .add(DateChanged(picked));
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 12, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(label,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.primary)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

class _Numpad extends StatelessWidget {
  const _Numpad({required this.onDigit});
  final void Function(String) onDigit;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['000', '0', 'del'],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: _rows
            .map((row) => Row(
                  children: row
                      .map((key) => Expanded(
                            child: _NumpadKey(label: key, onTap: () => onDigit(key)),
                          ))
                      .toList(),
                ))
            .toList(),
      ),
    );
  }
}

class _NumpadKey extends StatelessWidget {
  const _NumpadKey({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
        alignment: Alignment.center,
        child: label == 'del'
            ? Icon(
                Icons.backspace_outlined,
                size: 20,
                color: isDark ? AppColors.textDark : AppColors.textLight,
              )
            : Text(
                label,
                style: AppTextStyles.h3.copyWith(
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddTransactionBloc, AddTransactionState>(
      builder: (context, state) {
        final isLoading = state is AddTransactionLoading;
        final isValid = state is AddTransactionInProgress && state.isValid;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isValid && !isLoading
                  ? () => context
                      .read<AddTransactionBloc>()
                      .add(const SubmitTransaction())
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withAlpha(80),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text('Simpan', style: AppTextStyles.label),
            ),
          ),
        );
      },
    );
  }
}
