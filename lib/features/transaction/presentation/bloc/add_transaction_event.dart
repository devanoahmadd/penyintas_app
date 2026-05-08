part of 'add_transaction_bloc.dart';

sealed class AddTransactionEvent extends Equatable {
  const AddTransactionEvent();
}

final class AmountChanged extends AddTransactionEvent {
  const AmountChanged(this.amount);
  final int amount;
  @override
  List<Object> get props => [amount];
}

final class CategorySelected extends AddTransactionEvent {
  const CategorySelected(this.category);
  final TransactionCategory category;
  @override
  List<Object> get props => [category];
}

final class TypeToggled extends AddTransactionEvent {
  const TypeToggled();
  @override
  List<Object> get props => [];
}

final class NoteChanged extends AddTransactionEvent {
  const NoteChanged(this.note);
  final String note;
  @override
  List<Object> get props => [note];
}

final class DateChanged extends AddTransactionEvent {
  const DateChanged(this.date);
  final DateTime date;
  @override
  List<Object> get props => [date];
}

final class SubmitTransaction extends AddTransactionEvent {
  const SubmitTransaction();
  @override
  List<Object> get props => [];
}
