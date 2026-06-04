import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/core/utils/category_metadata.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/get_categories_usecase.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/transaction_list_bloc.dart';

enum _Period { thisWeek, thisMonth, threeMonths, custom }

class TransactionFilterSheet extends StatefulWidget {
  const TransactionFilterSheet({super.key, required this.currentState});
  final TransactionListLoaded currentState;

  @override
  State<TransactionFilterSheet> createState() =>
      _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<TransactionFilterSheet> {
  static const double _maxNominal = 5000000;

  late Set<String> _selectedCategories;
  late _Period _selectedPeriod;
  late DateTime _customFrom;
  late DateTime _customTo;
  late RangeValues _nominalRange;
  List<CategoryEntity> _allCategories = [];

  @override
  void initState() {
    super.initState();
    final s = widget.currentState;
    _selectedCategories =
        s.categoryFilter != null ? Set.from(s.categoryFilter!) : {};
    _customFrom = s.from;
    _customTo = s.to;
    _nominalRange = RangeValues(
      (s.minAmount ?? 0).toDouble(),
      (s.maxAmount ?? _maxNominal).toDouble(),
    );
    _selectedPeriod = _inferPeriod(s.from, s.to);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final result = await sl<GetCategoriesUseCase>().call(const NoParams());
    result.fold(
      (_) {},
      (cats) {
        if (mounted) setState(() => _allCategories = cats);
      },
    );
  }

  _Period _inferPeriod(DateTime from, DateTime to) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    if (from.year == monthStart.year &&
        from.month == monthStart.month &&
        from.day == monthStart.day) { return _Period.thisMonth; }
    final weekAgo = now.subtract(const Duration(days: 7));
    if (from.year == weekAgo.year &&
        from.month == weekAgo.month &&
        from.day == weekAgo.day) { return _Period.thisWeek; }
    final threeMonthsStart = DateTime(now.year, now.month - 2, 1);
    if (from.year == threeMonthsStart.year &&
        from.month == threeMonthsStart.month &&
        from.day == 1) { return _Period.threeMonths; }
    return _Period.custom;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kategori',
                      style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w700,
                          color: textColor)),
                  const SizedBox(height: AppSpacing.sm),
                  if (_allCategories.isEmpty)
                    const SizedBox(height: 32)
                  else
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _allCategories.map((cat) {
                        final isSelected =
                            _selectedCategories.contains(cat.slug);
                        final label =
                            CategoryMetadata.resolveLabel(cat, context.l10n);
                        return GestureDetector(
                          onTap: () => setState(() {
                            if (isSelected) {
                              _selectedCategories.remove(cat.slug);
                            } else {
                              _selectedCategories.add(cat.slug);
                            }
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : borderColor),
                            ),
                            child: Text(
                              label,
                              style: AppTextStyles.label.copyWith(
                                fontSize: 12,
                                color: isSelected ? Colors.white : textColor,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Periode',
                      style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w700,
                          color: textColor)),
                  const SizedBox(height: AppSpacing.sm),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 3.2,
                    children: [
                      _PeriodButton(
                          label: 'Minggu Ini',
                          selected: _selectedPeriod == _Period.thisWeek,
                          isDark: isDark,
                          onTap: () => setState(
                              () => _selectedPeriod = _Period.thisWeek)),
                      _PeriodButton(
                          label: 'Bulan Ini',
                          selected: _selectedPeriod == _Period.thisMonth,
                          isDark: isDark,
                          onTap: () => setState(
                              () => _selectedPeriod = _Period.thisMonth)),
                      _PeriodButton(
                          label: '3 Bulan',
                          selected: _selectedPeriod == _Period.threeMonths,
                          isDark: isDark,
                          onTap: () => setState(
                              () => _selectedPeriod = _Period.threeMonths)),
                      _PeriodButton(
                          label: 'Custom',
                          selected: _selectedPeriod == _Period.custom,
                          isDark: isDark,
                          onTap: () => setState(
                              () => _selectedPeriod = _Period.custom)),
                    ],
                  ),
                  if (_selectedPeriod == _Period.custom) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _DateBox(
                            label: 'Dari',
                            date: _customFrom,
                            isDark: isDark,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _customFrom,
                                firstDate: DateTime(2020),
                                lastDate: _customTo,
                              );
                              if (picked != null) {
                                setState(() => _customFrom = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _DateBox(
                            label: 'Sampai',
                            date: _customTo,
                            isDark: isDark,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _customTo,
                                firstDate: _customFrom,
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _customTo = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Nominal',
                          style: AppTextStyles.label.copyWith(
                              fontWeight: FontWeight.w700,
                              color: textColor)),
                      Text(
                        '${formatRupiah(_nominalRange.start.toInt())} — '
                        '${formatRupiah(_nominalRange.end.toInt())}',
                        style: AppTextStyles.numericSm.copyWith(
                          fontSize: 11,
                          color: mutedColor,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: borderColor,
                      thumbColor: AppColors.primary,
                      // ignore: deprecated_member_use
                      overlayColor: AppColors.primary.withOpacity(0.12),
                    ),
                    child: RangeSlider(
                      values: _nominalRange,
                      min: 0,
                      max: _maxNominal,
                      divisions: 100,
                      onChanged: (v) => setState(() => _nominalRange = v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              MediaQuery.of(context).padding.bottom + AppSpacing.lg,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reset,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill)),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md),
                    ),
                    child: Text('Reset',
                        style:
                            AppTextStyles.label.copyWith(color: textColor)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm2),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _apply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill)),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md),
                    ),
                    child: Text('Terapkan',
                        style: AppTextStyles.label
                            .copyWith(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _reset() {
    setState(() {
      _selectedCategories.clear();
      _selectedPeriod = _Period.thisMonth;
      _nominalRange = const RangeValues(0, _maxNominal);
    });
  }

  void _apply() {
    final bloc = context.read<TransactionListBloc>();
    final now = DateTime.now();

    final (from, to) = switch (_selectedPeriod) {
      _Period.thisWeek => (now.subtract(const Duration(days: 7)), now),
      _Period.thisMonth => (DateTime(now.year, now.month, 1), now),
      _Period.threeMonths => (DateTime(now.year, now.month - 2, 1), now),
      _Period.custom => (_customFrom, _customTo),
    };

    final cur = widget.currentState;
    final sameRange = from.year == cur.from.year &&
        from.month == cur.from.month &&
        from.day == cur.from.day &&
        to.year == cur.to.year &&
        to.month == cur.to.month &&
        to.day == cur.to.day;
    if (!sameRange) {
      bloc.add(LoadTransactions(from: from, to: to));
    }

    bloc.add(FilterSheetApplied(
      categories:
          _selectedCategories.isEmpty ? null : Set.from(_selectedCategories),
      minAmount:
          _nominalRange.start > 0 ? _nominalRange.start.toInt() : null,
      maxAmount: _nominalRange.end < _maxNominal
          ? _nominalRange.end.toInt()
          : null,
    ));

    Navigator.pop(context);
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border:
              Border.all(color: selected ? AppColors.primary : borderColor),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            fontSize: 12,
            color: selected ? Colors.white : textColor,
          ),
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({
    required this.label,
    required this.date,
    required this.isDark,
    required this.onTap,
  });
  final String label;
  final DateTime date;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                color: mutedColor,
                letterSpacing: 0.4,
              ),
            ),
            Text(
              DateFormat('d MMM yyyy', 'id_ID').format(date),
              style: AppTextStyles.bodySmall
                  .copyWith(color: textColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
