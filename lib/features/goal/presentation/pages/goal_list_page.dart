import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/features/goal/domain/entities/goal_entity.dart';
import 'package:penyintas_app/features/goal/presentation/bloc/goal_bloc.dart';
import 'package:penyintas_app/features/goal/presentation/widgets/add_goal_sheet.dart';
import 'package:penyintas_app/features/goal/presentation/widgets/goal_card.dart';
import 'package:penyintas_app/widgets/common/milestone_toast.dart';

class GoalListPage extends StatefulWidget {
  const GoalListPage({super.key});

  @override
  State<GoalListPage> createState() => _GoalListPageState();
}

class _GoalListPageState extends State<GoalListPage> {
  @override
  void initState() {
    super.initState();
    context.read<GoalBloc>().add(const LoadGoals());
  }

  void _openAddSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<GoalBloc>(),
        child: const AddGoalSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

    return BlocListener<GoalBloc, GoalState>(
      listener: (context, state) {
        if (state is GoalLoaded &&
            state.milestoneGoalId != null &&
            state.milestoneThreshold != null) {
          final pct = (state.milestoneThreshold! * 100).toInt();
          MilestoneToast.show(context, context.l10n.goalMilestonePct(pct));
          context.read<GoalBloc>().add(const MilestoneAcknowledged());
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: bgColor,
              title: Text(
                context.l10n.goalsTitle,
                style: AppTextStyles.h3.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              centerTitle: false,
            ),
            BlocBuilder<GoalBloc, GoalState>(
              builder: (context, state) {
                if (state is GoalLoading) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }

                if (state is GoalError) {
                  return SliverFillRemaining(
                    child: _ErrorBody(
                      message: state.message,
                      onRetry: () =>
                          context.read<GoalBloc>().add(const LoadGoals()),
                    ),
                  );
                }

                final goals = _goalsFromState(state);

                if (goals.isEmpty) {
                  return SliverFillRemaining(child: _EmptyBody(isDark: isDark));
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                  ),
                  sliver: SliverList.separated(
                    itemCount: goals.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (_, i) => GoalCard(
                      goal: goals[i],
                      onTap: () => context.push(
                        '/goals/${goals[i].id}',
                        extra: goals[i],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddSheet,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: Text(
            context.l10n.goalsAdd,
            style: AppTextStyles.label.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }

  List<GoalEntity> _goalsFromState(GoalState state) {
    if (state is GoalLoaded) return state.goals;
    if (state is GoalActionLoading) return state.goals;
    return const [];
  }
}

// ── Error state ─────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: AppTextStyles.body.copyWith(color: mutedColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(onPressed: onRetry, child: Text(context.l10n.retry)),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_outlined, size: 48, color: mutedColor),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.goalsEmpty,
              style: AppTextStyles.body.copyWith(color: mutedColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
