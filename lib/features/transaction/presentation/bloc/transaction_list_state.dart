part of 'transaction_list_bloc.dart';

sealed class TransactionListState extends Equatable {
  const TransactionListState();
}

final class TransactionListLoading extends TransactionListState {
  const TransactionListLoading();
  @override
  List<Object> get props => [];
}

final class TransactionListLoaded extends TransactionListState {
  const TransactionListLoaded({
    required this.transactions,
    required this.filtered,
    required this.totalSpent,
    required this.typeFilter,
    required this.from,
    required this.to,
  });

  final List<TransactionEntity> transactions;
  final List<TransactionEntity> filtered;
  final int totalSpent;
  final TransactionType? typeFilter;
  final DateTime from;
  final DateTime to;

  TransactionListLoaded copyWith({
    List<TransactionEntity>? transactions,
    List<TransactionEntity>? filtered,
    int? totalSpent,
    TransactionType? Function()? typeFilter,
  }) =>
      TransactionListLoaded(
        transactions: transactions ?? this.transactions,
        filtered: filtered ?? this.filtered,
        totalSpent: totalSpent ?? this.totalSpent,
        typeFilter: typeFilter != null ? typeFilter() : this.typeFilter,
        from: from,
        to: to,
      );

  @override
  List<Object?> get props =>
      [transactions, filtered, totalSpent, typeFilter, from, to];
}

final class TransactionListError extends TransactionListState {
  const TransactionListError(this.message);
  final String message;
  @override
  List<Object> get props => [message];
}
