part of 'survival_bloc.dart';

abstract class SurvivalState extends Equatable {
  const SurvivalState();
}

class SurvivalInitial extends SurvivalState {
  const SurvivalInitial();

  @override
  List<Object> get props => [];
}

class SurvivalInactive extends SurvivalState {
  const SurvivalInactive();

  @override
  List<Object> get props => [];
}

class SurvivalActive extends SurvivalState {
  const SurvivalActive(this.entity);
  final SurvivalModeEntity entity;

  @override
  List<Object> get props => [entity];
}

class SurvivalTipsLoading extends SurvivalState {
  const SurvivalTipsLoading(this.entity);
  final SurvivalModeEntity entity;

  @override
  List<Object> get props => [entity];
}

class SurvivalTipsLoaded extends SurvivalState {
  const SurvivalTipsLoaded(this.entity);
  final SurvivalModeEntity entity;

  @override
  List<Object> get props => [entity];
}

class SurvivalError extends SurvivalState {
  const SurvivalError(this.message, [this.entity]);
  final String message;
  final SurvivalModeEntity? entity;

  @override
  List<Object?> get props => [message, entity];
}
