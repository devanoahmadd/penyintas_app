part of 'add_transaction_bloc.dart';

sealed class AddTransactionState extends Equatable {
  const AddTransactionState();
}

final class AddTransactionInProgress extends AddTransactionState {
  const AddTransactionInProgress({
    required this.amount,
    required this.category,
    required this.type,
    required this.note,
    required this.date,
    this.selectedGoalId,
  });

  final int amount;
  final TransactionCategory category;
  final TransactionType type;
  final String note;
  final DateTime date;

  /// null = tidak dikaitkan ke tujuan tabungan.
  final int? selectedGoalId;

  bool get isValid => amount > 0 && amount <= 100000000;

  AddTransactionInProgress copyWith({
    int? amount,
    TransactionCategory? category,
    TransactionType? type,
    String? note,
    DateTime? date,
    Object? selectedGoalId = _kSentinel,
  }) =>
      AddTransactionInProgress(
        amount: amount ?? this.amount,
        category: category ?? this.category,
        type: type ?? this.type,
        note: note ?? this.note,
        date: date ?? this.date,
        selectedGoalId: identical(selectedGoalId, _kSentinel)
            ? this.selectedGoalId
            : selectedGoalId as int?,
      );

  @override
  List<Object?> get props => [amount, category, type, note, date, selectedGoalId];
}

const _kSentinel = Object();

final class AddTransactionLoading extends AddTransactionState {
  const AddTransactionLoading();
  @override
  List<Object> get props => [];
}

final class AddTransactionSuccess extends AddTransactionState {
  const AddTransactionSuccess();
  @override
  List<Object> get props => [];
}

final class AddTransactionError extends AddTransactionState {
  const AddTransactionError(this.message);
  final String message;
  @override
  List<Object> get props => [message];
}
