import 'package:flutter/material.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/category_metadata.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_cycle.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_overview_entity.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';

/// Per-category budget limit card.
///
/// The whole card is tappable → [onEdit].
/// The trailing [PopupMenuButton] handles toggle-active and delete only
/// (edit is promoted to the card tap).
/// Dims to 0.5 opacity when disabled.
class BudgetLimitCard extends StatelessWidget {
  const BudgetLimitCard({
    super.key,
    required this.item,
    required this.isEnabled,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final CategoryBudgetItem item;
  final bool isEnabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(bool) onToggle;

  // Map BudgetStatus → progress-bar color
  Color _barColor(BudgetStatus? status) => switch (status) {
    BudgetStatus.danger => AppColors.warn,
    BudgetStatus.caution => AppColors.caution,
    _ => AppColors.primary,
  };

  // Map BudgetStatus → percent label color
  Color _pctColor(BudgetStatus? status, bool isDark) => switch (status) {
    BudgetStatus.danger => AppColors.warn,
    BudgetStatus.caution => AppColors.caution,
    _ => isDark ? AppColors.shoot : AppColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    final limit = item.limitAmount ?? 0;
    final remaining = (limit - item.spentAmount).clamp(0, limit);
    final usagePct = item.usagePct ?? 0.0;
    final cycleLabel = item.cycleType?.label ?? BudgetCycle.cycle.label;
    final barColor = _barColor(item.status);
    final pctColor = _pctColor(item.status, isDark);

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row ────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          CategoryMetadata.resolveLabel(item.category, l10n),
                          style: AppTextStyles.h3,
                        ),
                      ),
                      // Usage percentage
                      Text(
                        '${(usagePct * 100).round()}%',
                        style: AppTextStyles.numericSm.copyWith(
                          color: pctColor,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Menu: toggle + delete only (edit = card tap)
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          iconSize: 20,
                          tooltip: 'Opsi limit kategori',
                          onSelected: (v) {
                            if (v == 'toggle') onToggle(!isEnabled);
                            if (v == 'delete') onDelete();
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(
                                isEnabled ? 'Nonaktifkan' : 'Aktifkan',
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Hapus'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // ── Status-colored progress bar ────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: usagePct,
                      minHeight: 6,
                      backgroundColor: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // ── Footer row ─────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sisa ${formatRupiah(remaining)}',
                        style: AppTextStyles.bodySmall,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Pace hint — hanya tampil jika ada proyeksi
                          if (item.projectedDaysLeft != null) ...[
                            Text(
                              '~${item.projectedDaysLeft} hari · ',
                              style: AppTextStyles.caption.copyWith(
                                color: _pctColor(item.paceStatus, isDark),
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                          Text(
                            cycleLabel,
                            style: AppTextStyles.caption.copyWith(color: muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
