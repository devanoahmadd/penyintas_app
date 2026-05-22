part of 'goal_bloc.dart';

sealed class GoalEvent extends Equatable {
  const GoalEvent();
}

final class LoadGoals extends GoalEvent {
  const LoadGoals();
  @override
  List<Object> get props => [];
}

final class CreateGoal extends GoalEvent {
  const CreateGoal({
    required this.title,
    required this.targetAmount,
    required this.targetDate,
  });
  final String title;
  final int targetAmount;
  final DateTime targetDate;
  @override
  List<Object> get props => [title, targetAmount, targetDate];
}

final class LinkTransaction extends GoalEvent {
  const LinkTransaction({required this.txId, required this.goalId});
  final String txId;
  final int goalId;
  @override
  List<Object> get props => [txId, goalId];
}

final class UnlinkTransaction extends GoalEvent {
  const UnlinkTransaction(this.txId);
  final String txId;
  @override
  List<Object> get props => [txId];
}

final class CompleteGoal extends GoalEvent {
  const CompleteGoal(this.goalId);
  final int goalId;
  @override
  List<Object> get props => [goalId];
}

final class DeleteGoal extends GoalEvent {
  const DeleteGoal(this.goalId);
  final int goalId;
  @override
  List<Object> get props => [goalId];
}

final class MilestoneAcknowledged extends GoalEvent {
  const MilestoneAcknowledged();
  @override
  List<Object> get props => [];
}
