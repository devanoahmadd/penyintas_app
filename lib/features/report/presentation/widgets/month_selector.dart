import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';

class MonthSelector extends StatelessWidget {
  const MonthSelector({
    super.key,
    required this.selectedMonth,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime selectedMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final isCurrentMonth = _isSameMonth(selectedMonth, DateTime.now());
    final label = DateFormat('MMMM yyyy', 'id').format(selectedMonth);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
          color: textColor,
          iconSize: 24,
        ),
        Text(label, style: AppTextStyles.label.copyWith(color: textColor)),
        IconButton(
          onPressed: isCurrentMonth ? null : onNext,
          icon: Icon(
            Icons.chevron_right,
            color: isCurrentMonth ? mutedColor : textColor,
          ),
          iconSize: 24,
        ),
      ],
    );
  }

  bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;
}
