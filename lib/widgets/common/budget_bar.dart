import 'package:flutter/material.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';

class BudgetBar extends StatefulWidget {
  const BudgetBar({
    super.key,
    required this.spent,
    required this.total,
  });

  final int spent;
  final int total;

  @override
  State<BudgetBar> createState() => _BudgetBarState();
}

class _BudgetBarState extends State<BudgetBar> {
  double _prevPct = 0;

  double _currentPct() =>
      widget.total > 0 ? (widget.spent / widget.total).clamp(0.0, 1.0) : 0.0;

  @override
  void didUpdateWidget(BudgetBar old) {
    super.didUpdateWidget(old);
    // Tangkap nilai lama sebelum rebuild sehingga animasi mulai dari sana
    final oldPct =
        old.total > 0 ? (old.spent / old.total).clamp(0.0, 1.0) : 0.0;
    _prevPct = oldPct;
  }

  Color _barColor(double pct) {
    if (pct <= 0.50) return AppColors.primary;
    if (pct <= 0.80) return AppColors.caution;
    return AppColors.warn;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final pct = _currentPct();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ANGGARAN BULAN INI', style: AppTextStyles.caption),
            Text(
              '${formatRupiah(widget.spent)} / ${formatRupiah(widget.total)}',
              style: AppTextStyles.caption.copyWith(
                color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          tween: Tween(begin: _prevPct, end: pct),
          builder: (context, value, child) => ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: borderColor,
              valueColor: AlwaysStoppedAnimation(_barColor(value)),
              minHeight: 8,
            ),
          ),
        ),
      ],
    );
  }
}
