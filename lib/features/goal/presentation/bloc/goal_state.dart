part of 'goal_bloc.dart';

sealed class GoalState extends Equatable {
  const GoalState();
}

final class GoalInitial extends GoalState {
  const GoalInitial();
  @override
  List<Object> get props => [];
}

final class GoalLoading extends GoalState {
  const GoalLoading();
  @override
  List<Object> get props => [];
}

final class GoalLoaded extends GoalState {
  const GoalLoaded({
    required this.goals,
    this.milestoneGoalId,
    this.milestoneThreshold,
  });

  final List<GoalEntity> goals;

  /// Non-null hanya setelah LinkTransaction crossing milestone — untuk trigger MilestoneToast.
  final int? milestoneGoalId;
  final double? milestoneThreshold;

  GoalLoaded clearMilestone() => GoalLoaded(goals: goals);

  @override
  List<Object?> get props => [goals, milestoneGoalId, milestoneThreshold];
}

final class GoalActionLoading extends GoalState {
  const GoalActionLoading(this.goals);
  final List<GoalEntity> goals;
  @override
  List<Object> get props => [goals];
}

final class GoalError extends GoalState {
  const GoalError(this.message);
  final String message;
  @override
  List<Object> get props => [message];
}
