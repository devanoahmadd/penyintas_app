part of 'budget_limits_bloc.dart';

abstract class BudgetLimitsEvent extends Equatable {
  const BudgetLimitsEvent();
  @override
  List<Object?> get props => [];
}

class LoadBudgetLimits extends BudgetLimitsEvent {
  const LoadBudgetLimits();
}

class SaveBudgetLimit extends BudgetLimitsEvent {
  const SaveBudgetLimit(this.limit);
  final BudgetLimitEntity limit;
  @override
  List<Object> get props => [limit];
}

class DeleteBudgetLimit extends BudgetLimitsEvent {
  const DeleteBudgetLimit({required this.id, required this.categoryName});
  final int id;
  final String categoryName;
  @override
  List<Object> get props => [id, categoryName];
}

class ToggleBudgetLimit extends BudgetLimitsEvent {
  const ToggleBudgetLimit({required this.id, required this.isEnabled});
  final int id;
  final bool isEnabled;
  @override
  List<Object> get props => [id, isEnabled];
}
