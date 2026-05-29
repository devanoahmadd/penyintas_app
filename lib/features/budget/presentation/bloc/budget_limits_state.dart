part of 'budget_limits_bloc.dart';

abstract class BudgetLimitsState extends Equatable {
  const BudgetLimitsState();
  @override
  List<Object?> get props => [];
}

class BudgetLimitsInitial extends BudgetLimitsState {
  const BudgetLimitsInitial();
}

class BudgetLimitsLoading extends BudgetLimitsState {
  const BudgetLimitsLoading();
}

class BudgetLimitsLoaded extends BudgetLimitsState {
  const BudgetLimitsLoaded({required this.limits, required this.overview});
  final List<BudgetLimitEntity> limits;
  final BudgetOverviewEntity overview;
  @override
  List<Object> get props => [limits, overview];
}

class BudgetLimitsError extends BudgetLimitsState {
  const BudgetLimitsError(this.message);
  final String message;
  @override
  List<Object> get props => [message];
}
