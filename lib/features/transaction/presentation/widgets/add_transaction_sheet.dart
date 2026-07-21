import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/category_metadata.dart';
import 'package:penyintas_app/features/goal/domain/entities/goal_entity.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/add_transaction_bloc.dart';

// ── Main Sheet ────────────────────────────────────────────────────────────

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({
    super.key,
    this.activeGoals = const [],
    this.initial,
  });

  /// Daftar goal aktif (belum selesai) untuk ditampilkan di goal picker.
  /// Dikirim dari caller (DashboardPage / TransactionListPage).
  final List<GoalEntity> activeGoals;

  /// Jika diisi, pre-fill form dengan data transaksi ini (mode duplikat).
  /// date selalu DateTime.now(), goalId selalu null.
  final TransactionEntity? initial;

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<AddTransactionBloc>();
      // Load categories for the current type first
      bloc.add(const LoadTransactionCategories());
      final init = widget.initial;
      if (init != null) {
        bloc.add(AmountChanged(init.amount));
        // Pre-fill category slug from existing transaction
        bloc.add(CategorySelected(init.category));
        bloc.add(TypeSet(init.type));
        if (init.note != null && init.note!.isNotEmpty) {
          _noteController.text = init.note!;
          bloc.add(NoteChanged(init.note!));
        }
        bloc.add(DateChanged(DateTime.now()));
        // goalId always stripped on duplicate
      }
      _openNumpad();
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _openNumpad() {
    final bloc = context.read<AddTransactionBloc>();
    final amount =
        widget.initial?.amount ??
        (bloc.state is AddTransactionInProgress
            ? (bloc.state as AddTransactionInProgress).amount
            : 0);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: _NumpadSheet(initialAmount: amount),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return BlocListener<AddTransactionBloc, AddTransactionState>(
      listener: (context, state) {
        if (state is AddTransactionSuccess) Navigator.of(context).pop(true);
        if (state is AddTransactionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
              ),
              backgroundColor: AppColors.warn,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Padding(
        // Sheet naik saat keyboard system (note field) muncul
        padding: EdgeInsets.only(bottom: viewInsets),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: max(screenHeight * 0.88 - viewInsets, 320),
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),
              _Handle(isDark: isDark),
              _SheetHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TypeToggle(isDark: isDark),
                      const SizedBox(height: AppSpacing.lg),
                      // Nominal card → ketuk untuk buka numpad
                      GestureDetector(
                        onTap: _openNumpad,
                        child: _NominalCard(isDark: isDark),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _SectionLabel(
                        context.l10n.txSectionCategory,
                        isDark: isDark,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _CategoryGrid(isDark: isDark),
                      const SizedBox(height: AppSpacing.xl),
                      _SectionLabel(context.l10n.txSectionNote, isDark: isDark),
                      const SizedBox(height: AppSpacing.sm),
                      _NoteField(controller: _noteController, isDark: isDark),
                      const SizedBox(height: AppSpacing.xl),
                      _SectionLabel(context.l10n.txSectionDate, isDark: isDark),
                      const SizedBox(height: AppSpacing.sm),
                      _DateField(isDark: isDark),
                      // Goal picker — hanya tampil untuk transaksi income dan ada goals aktif
                      if (widget.activeGoals.isNotEmpty)
                        BlocBuilder<AddTransactionBloc, AddTransactionState>(
                          builder: (context, state) {
                            final isIncome =
                                state is AddTransactionInProgress &&
                                state.type == TransactionType.income;
                            if (!isIncome) return const SizedBox.shrink();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: AppSpacing.xl),
                                _SectionLabel(
                                  context.l10n.goalLinkLabel,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                _GoalPicker(
                                  goals: widget.activeGoals,
                                  isDark: isDark,
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              _SubmitButton(),
              SizedBox(height: AppSpacing.sm + bottomPad),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Numpad Sub-Sheet ──────────────────────────────────────────────────────

class _NumpadSheet extends StatefulWidget {
  const _NumpadSheet({required this.initialAmount});
  final int initialAmount;

  @override
  State<_NumpadSheet> createState() => _NumpadSheetState();
}

class _NumpadSheetState extends State<_NumpadSheet> {
  late String _raw;

  @override
  void initState() {
    super.initState();
    _raw = widget.initialAmount == 0 ? '0' : widget.initialAmount.toString();
  }

  void _onDigit(String digit) {
    setState(() {
      if (digit == 'del') {
        _raw = _raw.length <= 1 ? '0' : _raw.substring(0, _raw.length - 1);
      } else if (_raw == '0') {
        _raw = digit == '000' ? '0' : digit;
      } else {
        final next = _raw + digit;
        if (int.tryParse(next) != null && int.parse(next) <= 100000000) {
          _raw = next;
        }
      }
    });
    context.read<AddTransactionBloc>().add(
      AmountChanged(int.tryParse(_raw) ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final amount = int.tryParse(_raw) ?? 0;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.sm),
          _Handle(isDark: isDark),
          const SizedBox(height: AppSpacing.lg),
          // Amount display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rp',
                  style: AppTextStyles.numericMd.copyWith(
                    color: mutedColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    NumberFormat.decimalPattern('id_ID').format(amount),
                    style: AppTextStyles.numericLg.copyWith(
                      fontSize: 38,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Numpad(onDigit: _onDigit, isDark: isDark),
          // Tombol Selesai
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: Text(
                  context.l10n.txDoneBtn,
                  style: AppTextStyles.label.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.sm + bottomPad),
        ],
      ),
    );
  }
}

// ── Handle ────────────────────────────────────────────────────────────────

class _Handle extends StatelessWidget {
  const _Handle({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ── Sheet Header ──────────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            context.l10n.txRecordTitle,
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
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.isDark});
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

// ── Type Toggle ───────────────────────────────────────────────────────────

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;

    return BlocBuilder<AddTransactionBloc, AddTransactionState>(
      builder: (context, state) {
        final isExpense = state is AddTransactionInProgress
            ? state.type == TransactionType.expense
            : true;

        return Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: _TypeButton(
                  label: context.l10n.txIncomeLabel,
                  isActive: !isExpense,
                  activeColor: AppColors.success,
                  isDark: isDark,
                  onTap: () {
                    if (isExpense) {
                      HapticFeedback.selectionClick();
                      context.read<AddTransactionBloc>().add(
                        const TypeToggled(),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _TypeButton(
                  label: context.l10n.txExpenseLabel,
                  isActive: isExpense,
                  activeColor: AppColors.warn,
                  isDark: isDark,
                  onTap: () {
                    if (!isExpense) {
                      HapticFeedback.selectionClick();
                      context.read<AddTransactionBloc>().add(
                        const TypeToggled(),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.isDark,
    required this.onTap,
  });
  final String label;
  final bool isActive;
  final Color activeColor;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: isActive ? Colors.white : mutedColor,
          ),
        ),
      ),
    );
  }
}

// ── Nominal Card ──────────────────────────────────────────────────────────

class _NominalCard extends StatelessWidget {
  const _NominalCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return BlocBuilder<AddTransactionBloc, AddTransactionState>(
      builder: (context, state) {
        final amount = state is AddTransactionInProgress ? state.amount : 0;
        final displayStr = NumberFormat.decimalPattern('id_ID').format(amount);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    context.l10n.txNominalLabel,
                    style: AppTextStyles.caption.copyWith(color: mutedColor),
                  ),
                  const Spacer(),
                  // Edit affordance
                  Icon(Icons.edit_outlined, size: 14, color: mutedColor),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rp',
                    style: AppTextStyles.numericMd.copyWith(
                      color: mutedColor,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      displayStr,
                      style: AppTextStyles.numericLg.copyWith(
                        fontSize: 38,
                        color: amount == 0 ? mutedColor : textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (amount == 0) ...[
                const SizedBox(height: 4),
                Text(
                  context.l10n.txNominalTap,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary.withValues(alpha: 0.7),
                    letterSpacing: 0,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── Category Grid ─────────────────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddTransactionBloc, AddTransactionState>(
      builder: (context, state) {
        if (state is! AddTransactionInProgress) {
          return const SizedBox.shrink();
        }
        final cats = state.availableCategories;
        final selectedSlug = state.selectedCategory;

        if (cats.isEmpty) {
          return const SizedBox(height: 48);
        }

        return GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: cats
              .map(
                (cat) => _CategoryCell(
                  category: cat,
                  isSelected: cat.slug == selectedSlug,
                  isDark: isDark,
                  onTap: () => context.read<AddTransactionBloc>().add(
                    CategorySelected(cat.slug),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _CategoryCell extends StatelessWidget {
  const _CategoryCell({
    required this.category,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });
  final CategoryEntity category;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final surfaceColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

    final (icon, _) = CategoryMetadata.of(category.slug);
    final label = CategoryMetadata.resolveLabel(category, context.l10n);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : borderColor,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: isSelected ? Colors.white : textColor),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                color: isSelected ? Colors.white : textColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Note Field ────────────────────────────────────────────────────────────

class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller, required this.isDark});
  final TextEditingController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return TextField(
      controller: controller,
      style: AppTextStyles.bodySmall.copyWith(color: textColor),
      maxLines: 1,
      maxLength: 100,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        hintText: context.l10n.txNoteHint,
        hintStyle: AppTextStyles.bodySmall.copyWith(color: mutedColor),
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
      ),
      onChanged: (v) => context.read<AddTransactionBloc>().add(NoteChanged(v)),
    );
  }
}

// ── Date Field ────────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  const _DateField({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddTransactionBloc, AddTransactionState>(
      builder: (context, state) {
        final date = state is AddTransactionInProgress
            ? state.date
            : DateTime.now();

        final label =
            '${DateFormat('d MMM yyyy', 'id_ID').format(date)} · ${DateFormat('HH:mm').format(date)}';

        final surfaceColor = isDark ? AppColors.cardDark : AppColors.cardLight;
        final borderColor = isDark
            ? AppColors.borderDark
            : AppColors.borderLight;
        final textColor = isDark ? AppColors.textDark : AppColors.textLight;
        final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

        return GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now(),
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
            if (picked == null || !context.mounted) return;

            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(date),
            );
            if (!context.mounted) return;

            context.read<AddTransactionBloc>().add(
              DateChanged(
                DateTime(
                  picked.year,
                  picked.month,
                  picked.day,
                  time?.hour ?? date.hour,
                  time?.minute ?? date.minute,
                ),
              ),
            );
          },
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
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
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

// ── Numpad ────────────────────────────────────────────────────────────────

class _Numpad extends StatelessWidget {
  const _Numpad({required this.onDigit, required this.isDark});
  final void Function(String) onDigit;
  final bool isDark;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['000', '0', 'del'],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: _rows
            .map(
              (row) => Row(
                children: row
                    .map(
                      (key) => Expanded(
                        child: _NumpadKey(
                          label: key,
                          onTap: () => onDigit(key),
                          isDark: isDark,
                        ),
                      ),
                    )
                    .toList(),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NumpadKey extends StatelessWidget {
  const _NumpadKey({
    required this.label,
    required this.onTap,
    required this.isDark,
  });
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        alignment: Alignment.center,
        child: label == 'del'
            ? Icon(Icons.backspace_outlined, size: 20, color: textColor)
            : Text(
                label,
                style: AppTextStyles.h3.copyWith(
                  fontSize: 18,
                  color: textColor,
                ),
              ),
      ),
    );
  }
}

// ── Goal Picker ───────────────────────────────────────────────────────────

class _GoalPicker extends StatelessWidget {
  const _GoalPicker({required this.goals, required this.isDark});
  final List<GoalEntity> goals;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return BlocBuilder<AddTransactionBloc, AddTransactionState>(
      builder: (context, state) {
        final selectedId = state is AddTransactionInProgress
            ? state.selectedGoalId
            : null;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selectedId != null ? AppColors.primary : borderColor,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              value: selectedId,
              isExpanded: true,
              dropdownColor: surfaceColor,
              style: AppTextStyles.body.copyWith(color: textColor),
              icon: Icon(Icons.expand_more, color: mutedColor),
              hint: Text(
                context.l10n.goalLinkNone,
                style: AppTextStyles.body.copyWith(color: mutedColor),
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(
                    context.l10n.goalLinkNone,
                    style: AppTextStyles.body.copyWith(color: mutedColor),
                  ),
                ),
                ...goals.map(
                  (g) => DropdownMenuItem<int?>(
                    value: g.id,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.flag_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            g.title,
                            style: AppTextStyles.body.copyWith(
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: (id) =>
                  context.read<AddTransactionBloc>().add(GoalSelected(id)),
            ),
          ),
        );
      },
    );
  }
}

// ── Submit Button ─────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddTransactionBloc, AddTransactionState>(
      builder: (context, state) {
        final isLoading = state is AddTransactionLoading;
        final isValid = state is AddTransactionInProgress && state.isValid;

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: isValid && !isLoading
                  ? () => context.read<AddTransactionBloc>().add(
                      const SubmitTransaction(),
                    )
                  : null,
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
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      context.l10n.btnSave,
                      style: AppTextStyles.label.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
