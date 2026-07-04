import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/category_metadata.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/goal/domain/entities/goal_entity.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/transaction_list_bloc.dart';

const double _spineW = 2;
const double _spineOpacity = 0.3;
const double _dayNodeD = 38;

class TransactionDetailSheet extends StatelessWidget {
  const TransactionDetailSheet({
    super.key,
    required this.transaction,
    this.activeGoals = const [],
    this.onDuplicate,
    this.onEdit,
  });
  final TransactionEntity transaction;
  final List<GoalEntity> activeGoals;
  final void Function(TransactionEntity)? onDuplicate;
  final void Function(TransactionEntity)? onEdit;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = transaction.type == TransactionType.income;
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final amtColor = isIncome
        ? (isDark ? AppColors.incomeDark : AppColors.success)
        : (isDark ? AppColors.expenseDark : AppColors.warn);
    final amtBg = _amtBg(isDark, isIncome);
    final categoryLabel = CategoryMetadata.resolveLabelFromSlug(
      transaction.category,
      context.l10n,
    );

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(
                top: AppSpacing.md,
                bottom: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: _dayNodeD,
                  child: Column(
                    children: [
                      Container(
                        width: _spineW,
                        height: 16,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              // ignore: deprecated_member_use
                              AppColors.primary.withOpacity(_spineOpacity),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: _dayNodeD,
                        height: _dayNodeD,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isIncome
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    context.l10n.txDetailTitle,
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: mutedColor, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: amtBg,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      CategoryMetadata.of(transaction.category).$1,
                      size: 20,
                      color: amtColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.note ?? categoryLabel,
                          style: AppTextStyles.label.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          categoryLabel.toUpperCase(),
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            color: mutedColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${isIncome ? '+' : '−'} ${formatRupiah(transaction.amount)}',
                    style: AppTextStyles.numericMd.copyWith(
                      fontSize: 18,
                      color: amtColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                _MetaRow(
                  label: context.l10n.txDetailTime,
                  value: DateFormat(
                    'HH:mm · dd MMM yyyy',
                    Localizations.localeOf(context).languageCode,
                  ).format(transaction.date),
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.sm),
                _MetaRow(
                  label: context.l10n.txDetailType,
                  value: transaction.type == TransactionType.income
                      ? context.l10n.categoryIncome
                      : (transaction.isFixed
                            ? context.l10n.categoryFixed
                            : context.l10n.txDetailTypeVariable),
                  isDark: isDark,
                ),
                if (transaction.note != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _MetaRow(
                    label: context.l10n.txDetailNote,
                    value: transaction.note!,
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.edit_outlined,
                    label: context.l10n.txDetailEdit,
                    isDark: isDark,
                    variant: _ButtonVariant.primary,
                    onTap: () {
                      Navigator.pop(context);
                      onEdit?.call(transaction);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm2),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.copy_outlined,
                    label: context.l10n.txDetailDuplicate,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      onDuplicate?.call(transaction);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _ActionButton(
              icon: Icons.delete_outline_rounded,
              label: context.l10n.txDetailDelete,
              isDark: isDark,
              variant: _ButtonVariant.destructive,
              fullWidth: true,
              onTap: () {
                showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => BlocProvider.value(
                    value: context.read<TransactionListBloc>(),
                    child: _DeleteConfirmSheet(transaction: transaction),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom + AppSpacing.md,
          ),
        ],
      ),
    );
  }

  static Color _amtBg(bool isDark, bool isIncome) {
    if (isDark) {
      return isIncome
          // ignore: deprecated_member_use
          ? const Color(0xFF6EE7A0).withOpacity(0.12)
          // ignore: deprecated_member_use
          : const Color(0xFFFF8F70).withOpacity(0.10);
    }
    return isIncome
        // ignore: deprecated_member_use
        ? const Color(0xFF16A34A).withOpacity(0.10)
        // ignore: deprecated_member_use
        : const Color(0xFFE07A3C).withOpacity(0.08);
  }
}

// ── Delete Confirm Sheet ──────────────────────────────────────────────────

class _DeleteConfirmSheet extends StatefulWidget {
  const _DeleteConfirmSheet({required this.transaction});
  final TransactionEntity transaction;

  @override
  State<_DeleteConfirmSheet> createState() => _DeleteConfirmSheetState();
}

class _DeleteConfirmSheetState extends State<_DeleteConfirmSheet> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final isIncome = widget.transaction.type == TransactionType.income;
    final amtColor = isIncome
        ? (isDark ? AppColors.incomeDark : AppColors.success)
        : (isDark ? AppColors.expenseDark : AppColors.warn);

    return BlocListener<TransactionListBloc, TransactionListState>(
      listener: (context, state) {
        if (state is! TransactionListLoaded) return;
        if (state.deleteError != null && _isLoading) {
          setState(() => _isLoading = false);
          return;
        }
        final stillExists = state.transactions.any(
          (t) => t.id == widget.transaction.id,
        );
        if (!stillExists && _isLoading) {
          setState(() => _isLoading = false);
          int count = 0;
          Navigator.of(context).popUntil((_) => count++ >= 2);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                Text(
                  context.l10n.txDetailDeleteConfirmTitle,
                  style: AppTextStyles.h3.copyWith(color: textColor),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CategoryMetadata.of(widget.transaction.category).$1,
                        size: 18,
                        color: amtColor,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          widget.transaction.note ??
                              CategoryMetadata.resolveLabelFromSlug(
                                widget.transaction.category,
                                context.l10n,
                              ),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${isIncome ? '+' : '−'} ${formatRupiah(widget.transaction.amount)}',
                        style: AppTextStyles.numericSm.copyWith(
                          color: amtColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.l10n.txDetailDeleteConfirmBody,
                  style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
                ),
                const SizedBox(height: AppSpacing.lg),
                BlocBuilder<TransactionListBloc, TransactionListState>(
                  builder: (context, state) {
                    final errorMsg = state is TransactionListLoaded
                        ? state.deleteError
                        : null;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  side: BorderSide(color: borderColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  context.l10n.btnCancel,
                                  style: AppTextStyles.label.copyWith(
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm2),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        setState(() => _isLoading = true);
                                        context.read<TransactionListBloc>().add(
                                          DeleteTransactionRequested(
                                            widget.transaction.id,
                                          ),
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  backgroundColor: AppColors.warn.withValues(
                                    alpha: isDark ? 0.15 : 0.08,
                                  ),
                                  foregroundColor: AppColors.warn,
                                  elevation: 0,
                                  side: BorderSide(
                                    color: AppColors.warn.withValues(
                                      alpha: isDark ? 0.40 : 0.28,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                  ),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.warn,
                                        ),
                                      )
                                    : Text(
                                        context.l10n.commonDelete,
                                        style: AppTextStyles.label.copyWith(
                                          color: AppColors.warn,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        if (errorMsg != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            errorMsg.isNotEmpty
                                ? errorMsg
                                : context.l10n.txDetailDeleteFailed,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.warn,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    required this.isDark,
  });
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm2,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                color: mutedColor,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ButtonVariant { primary, secondary, destructive }

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.variant = _ButtonVariant.secondary,
    this.fullWidth = false,
  });
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  final _ButtonVariant variant;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color fgColor;
    final Color borderColor;

    switch (variant) {
      case _ButtonVariant.primary:
        // ignore: deprecated_member_use
        bgColor = AppColors.primary.withOpacity(isDark ? 0.18 : 0.10);
        fgColor = isDark ? AppColors.shoot : AppColors.primary;
        // ignore: deprecated_member_use
        borderColor = AppColors.primary.withOpacity(isDark ? 0.40 : 0.28);
      case _ButtonVariant.destructive:
        // ignore: deprecated_member_use
        bgColor = AppColors.warn.withOpacity(isDark ? 0.15 : 0.08);
        fgColor = AppColors.warn;
        // ignore: deprecated_member_use
        borderColor = AppColors.warn.withOpacity(isDark ? 0.40 : 0.28);
      case _ButtonVariant.secondary:
        bgColor = isDark ? AppColors.cardDark : AppColors.cardLight;
        fgColor = isDark ? AppColors.textSoftDark : AppColors.textSoftLight;
        borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    }

    final radius = BorderRadius.circular(AppRadius.md);

    final child = Ink(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: radius,
        border: Border.all(color: borderColor),
      ),
      child: SizedBox(
        height: 48,
        width: fullWidth ? double.infinity : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: fgColor),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.label.copyWith(color: fgColor, fontSize: 13),
            ),
          ],
        ),
      ),
    );

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        // ignore: deprecated_member_use
        splashColor: fgColor.withOpacity(0.10),
        // ignore: deprecated_member_use
        highlightColor: fgColor.withOpacity(0.06),
        child: child,
      ),
    );
  }
}
