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
    this.categoryFilter,
    this.minAmount,
    this.maxAmount,
    this.deleteError,
  });

  final List<TransactionEntity> transactions;
  final List<TransactionEntity> filtered;
  final int totalSpent;
  final TransactionType? typeFilter;
  final DateTime from;
  final DateTime to;
  final Set<TransactionCategory>? categoryFilter; // null = all
  final int? minAmount;
  final int? maxAmount;
  final String? deleteError;

  TransactionListLoaded copyWith({
    List<TransactionEntity>? transactions,
    List<TransactionEntity>? filtered,
    int? totalSpent,
    TransactionType? Function()? typeFilter,
    Set<TransactionCategory>? Function()? categoryFilter,
    int? Function()? minAmount,
    int? Function()? maxAmount,
    String? Function()? deleteError,
  }) =>
      TransactionListLoaded(
        transactions: transactions ?? this.transactions,
        filtered: filtered ?? this.filtered,
        totalSpent: totalSpent ?? this.totalSpent,
        typeFilter: typeFilter != null ? typeFilter() : this.typeFilter,
        categoryFilter:
            categoryFilter != null ? categoryFilter() : this.categoryFilter,
        minAmount: minAmount != null ? minAmount() : this.minAmount,
        maxAmount: maxAmount != null ? maxAmount() : this.maxAmount,
        deleteError: deleteError != null ? deleteError() : this.deleteError,
        from: from,
        to: to,
      );

  @override
  List<Object?> get props => [
        transactions,
        filtered,
        totalSpent,
        typeFilter,
        categoryFilter,
        minAmount,
        maxAmount,
        from,
        to,
        deleteError,
      ];
}

final class TransactionListError extends TransactionListState {
  const TransactionListError(this.message);
  final String message;
  @override
  List<Object> get props => [message];
}
