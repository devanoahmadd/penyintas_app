part of 'edit_transaction_bloc.dart';

sealed class EditTransactionEvent extends Equatable {
  const EditTransactionEvent();
}

final class EditAmountChanged extends EditTransactionEvent {
  const EditAmountChanged(this.amount);
  final int amount;
  @override
  List<Object> get props => [amount];
}

final class EditCategorySelected extends EditTransactionEvent {
  const EditCategorySelected(this.category);
  final String category;
  @override
  List<Object> get props => [category];
}

final class EditTypeSet extends EditTransactionEvent {
  const EditTypeSet(this.type);
  final TransactionType type;
  @override
  List<Object> get props => [type];
}

final class EditNoteChanged extends EditTransactionEvent {
  const EditNoteChanged(this.note);
  final String note;
  @override
  List<Object> get props => [note];
}

final class EditDateChanged extends EditTransactionEvent {
  const EditDateChanged(this.date);
  final DateTime date;
  @override
  List<Object> get props => [date];
}

final class EditGoalSelected extends EditTransactionEvent {
  const EditGoalSelected(this.goalId);
  final int? goalId;
  @override
  List<Object?> get props => [goalId];
}

final class SubmitEdit extends EditTransactionEvent {
  const SubmitEdit();
  @override
  List<Object> get props => [];
}
