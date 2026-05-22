import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/currency_config.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/survival/domain/entities/survival_mode_entity.dart';
import 'package:penyintas_app/features/survival/domain/entities/survival_tip_entity.dart';
import 'package:penyintas_app/features/survival/presentation/bloc/survival_bloc.dart';

class SurvivalTipsPage extends StatefulWidget {
  const SurvivalTipsPage({super.key});

  @override
  State<SurvivalTipsPage> createState() => _SurvivalTipsPageState();
}

class _SurvivalTipsPageState extends State<SurvivalTipsPage> {
  @override
  void initState() {
    super.initState();
    final lang = Localizations.localeOf(context).languageCode;
    context.read<SurvivalBloc>().add(FetchSurvivalTips(language: lang));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final l10n = AppLocalizations.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            l10n.survivalTipsPageTitle,
            style: AppTextStyles.h3.copyWith(color: textColor),
          ),
          iconTheme: IconThemeData(color: textColor),
        ),
        body: BlocBuilder<SurvivalBloc, SurvivalState>(
          builder: (context, state) {
            if (state is SurvivalTipsLoading) {
              return _TipsBody(
                entity: state.entity,
                isLoading: true,
                isDark: isDark,
              );
            }
            if (state is SurvivalActive) {
              return _TipsBody(
                entity: state.entity,
                isLoading: true,
                isDark: isDark,
              );
            }
            if (state is SurvivalTipsLoaded) {
              return _TipsBody(
                entity: state.entity,
                isLoading: false,
                isDark: isDark,
              );
            }
            if (state is SurvivalError) {
              return _ErrorBody(
                message: state.message,
                entity: state.entity,
                isDark: isDark,
                onRetry: () => context.read<SurvivalBloc>().add(
                      FetchSurvivalTips(
                        language:
                            Localizations.localeOf(context).languageCode,
                      ),
                    ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────

class _TipsBody extends StatelessWidget {
  const _TipsBody({
    required this.entity,
    required this.isLoading,
    required this.isDark,
  });

  final SurvivalModeEntity entity;
  final bool isLoading;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _SummaryCard(entity: entity),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.survivalTipsEyebrow,
          style: AppTextStyles.caption.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.md),
        if (isLoading)
          ..._skeletonCards(isDark)
        else if (entity.tips.isEmpty)
          _EmptyTipsState(isDark: isDark)
        else
          ...entity.tips.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _TipCard(
                    tip: e.value,
                    index: e.key + 1,
                    isDark: isDark,
                  ),
                ),
              ),
      ],
    );
  }

  List<Widget> _skeletonCards(bool isDark) {
    final skeletonColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return List.generate(
      3,
      (i) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 16,
                width: 160,
                decoration: BoxDecoration(
                  color: skeletonColor,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: skeletonColor,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 12,
                width: 200,
                decoration: BoxDecoration(
                  color: skeletonColor,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                height: 28,
                width: 120,
                decoration: BoxDecoration(
                  color: skeletonColor,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────

class _EmptyTipsState extends StatelessWidget {
  const _EmptyTipsState({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
      child: Center(
        child: Text(
          l10n.survivalTipsEmpty,
          style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── Summary card ─────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.entity});
  final SurvivalModeEntity entity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final amountStr = formatCurrency(entity.remainingAmount, CurrencyConfig.idr);
    final suggestedStr =
        formatCurrencyCompact(entity.suggestedDailyBudget, CurrencyConfig.idr);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warn,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.survivalBudgetLabel,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withAlpha(200),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            amountStr,
            style: AppTextStyles.h2.copyWith(
              color: Colors.white,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.survivalBudgetDaysSuggested(entity.remainingDays, suggestedStr),
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withAlpha(220),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tip card ─────────────────────────────────────────────────────────────

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.tip,
    required this.index,
    required this.isDark,
  });

  final SurvivalTip tip;
  final int index;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final savingStr =
        formatCurrencyCompact(tip.estimatedSaving, CurrencyConfig.idr);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$index',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  tip.title,
                  style: AppTextStyles.label.copyWith(color: textColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            tip.description,
            style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              l10n.survivalTipsSavingChip(savingStr),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.success,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error body ────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.entity,
    required this.isDark,
    required this.onRetry,
  });

  final String message;
  final SurvivalModeEntity? entity;
  final bool isDark;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (entity != null) ...[
          _SummaryCard(entity: entity!),
          const SizedBox(height: AppSpacing.xl),
        ],
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.xxxl),
              Text(
                message,
                style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: onRetry,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
