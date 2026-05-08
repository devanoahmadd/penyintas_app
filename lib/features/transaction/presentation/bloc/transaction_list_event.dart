part of 'transaction_list_bloc.dart';

sealed class TransactionListEvent extends Equatable {
  const TransactionListEvent();
}

final class LoadTransactions extends TransactionListEvent {
  const LoadTransactions({required this.from, required this.to});
  final DateTime from;
  final DateTime to;
  @override
  List<Object> get props => [from, to];
}

final class RefreshTransactions extends TransactionListEvent {
  const RefreshTransactions();
  @override
  List<Object> get props => [];
}

final class FilterChanged extends TransactionListEvent {
  const FilterChanged(this.category);
  final TransactionCategory? category;
  @override
  List<Object?> get props => [category];
}

final class DeleteTransactionRequested extends TransactionListEvent {
  const DeleteTransactionRequested(this.id);
  final String id;
  @override
  List<Object> get props => [id];
}
