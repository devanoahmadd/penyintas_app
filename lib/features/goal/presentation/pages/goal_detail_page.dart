import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/currency_config.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/goal/domain/entities/goal_entity.dart';
import 'package:penyintas_app/features/goal/presentation/bloc/goal_bloc.dart';

class GoalDetailPage extends StatelessWidget {
  const GoalDetailPage({super.key, required this.goal});
  final GoalEntity goal;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    // Resolve live goal from bloc — falls back to constructor snapshot if not loaded
    final goalState = context.watch<GoalBloc>().state;
    final current = goalState is GoalLoaded
        ? goalState.goals.firstWhere((g) => g.id == goal.id,
            orElse: () => goal)
        : goal;

    final savedFmt = formatCurrency(current.savedAmount, CurrencyConfig.idr);
    final targetFmt = formatCurrency(current.targetAmount, CurrencyConfig.idr);
    final dateStr =
        DateFormat('d MMMM yyyy', 'id_ID').format(current.targetDate);
    final pct = (current.progressPercent * 100).toStringAsFixed(0);

    return BlocListener<GoalBloc, GoalState>(
      listener: (context, state) {
        // Tutup halaman setelah delete berhasil
        if (state is GoalLoaded) {
          final stillExists = state.goals.any((g) => g.id == goal.id);
          if (!stillExists) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          title: Text(
            current.title,
            style: AppTextStyles.h3.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: false,
          actions: [
            if (!current.isCompleted)
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                color: AppColors.success,
                tooltip: context.l10n.goalDetailMarkDone,
                onPressed: () =>
                    context.read<GoalBloc>().add(CompleteGoal(current.id)),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppColors.warn,
              tooltip: context.l10n.goalDetailDeleteTooltip,
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Column(
                  children: [
                    // Percentage big display
                    Text(
                      '$pct%',
                      style: AppTextStyles.h1.copyWith(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        color: _progressColor(current.progressPercent),
                        height: 1.0,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      context.l10n.goalProgressLabel(savedFmt, targetFmt),
                      style: AppTextStyles.body.copyWith(color: mutedColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: current.progressPercent,
                        backgroundColor: borderColor,
                        valueColor: AlwaysStoppedAnimation(
                            _progressColor(current.progressPercent)),
                        minHeight: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Info rows
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      label: context.l10n.goalDateLabel,
                      value: dateStr,
                      icon: Icons.calendar_today_outlined,
                      textColor: textColor,
                      mutedColor: mutedColor,
                    ),
                    Divider(color: borderColor, height: AppSpacing.xl),
                    _InfoRow(
                      label: context.l10n.goalDetailStatusLabel,
                      value: current.isCompleted
                          ? context.l10n.goalCompleted
                          : current.isOverdue
                              ? context.l10n.goalOverdue
                              : context.l10n.goalDetailStatusActive,
                      valueColor: current.isCompleted
                          ? AppColors.success
                          : current.isOverdue
                              ? AppColors.warn
                              : null,
                      icon: Icons.info_outline,
                      textColor: textColor,
                      mutedColor: mutedColor,
                    ),
                  ],
                ),
              ),
              if (!current.isCompleted) ...[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  context.l10n.goalDetailTip,
                  style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _progressColor(double pct) {
    if (pct >= 1.0) return AppColors.success;
    if (pct >= 0.5) return AppColors.primaryBright;
    return AppColors.caution;
  }

  void _confirmDelete(BuildContext context) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.goalDetailDeleteTitle),
        content: Text(l10n.goalDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.btnCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<GoalBloc>().add(DeleteGoal(goal.id));
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.warn),
            child: Text(l10n.goalDetailDeleteBtn),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.textColor,
    required this.mutedColor,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color textColor;
  final Color mutedColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: mutedColor),
        const SizedBox(width: AppSpacing.md),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: valueColor ?? textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
