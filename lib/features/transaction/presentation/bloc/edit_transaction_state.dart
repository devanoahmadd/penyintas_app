part of 'edit_transaction_bloc.dart';

sealed class EditTransactionState extends Equatable {
  const EditTransactionState();
}

final class EditTransactionInProgress extends EditTransactionState {
  const EditTransactionInProgress({
    required this.originalId,
    required this.originalCreatedAt,
    required this.amount,
    required this.category,
    required this.type,
    required this.note,
    required this.date,
    this.selectedGoalId,
  });

  final String originalId;
  final DateTime originalCreatedAt;
  final int amount;
  final TransactionCategory category;
  final TransactionType type;
  final String note;
  final DateTime date;
  final int? selectedGoalId;

  bool get isValid => amount > 0 && amount <= 100000000;

  EditTransactionInProgress copyWith({
    int? amount,
    TransactionCategory? category,
    TransactionType? type,
    String? note,
    DateTime? date,
    Object? selectedGoalId = _kEditSentinel,
  }) =>
      EditTransactionInProgress(
        originalId: originalId,
        originalCreatedAt: originalCreatedAt,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        type: type ?? this.type,
        note: note ?? this.note,
        date: date ?? this.date,
        selectedGoalId: identical(selectedGoalId, _kEditSentinel)
            ? this.selectedGoalId
            : selectedGoalId as int?,
      );

  @override
  List<Object?> get props => [
        originalId,
        originalCreatedAt,
        amount,
        category,
        type,
        note,
        date,
        selectedGoalId,
      ];
}

const _kEditSentinel = Object();

final class EditTransactionLoading extends EditTransactionState {
  const EditTransactionLoading();
  @override
  List<Object> get props => [];
}

final class EditTransactionSuccess extends EditTransactionState {
  const EditTransactionSuccess();
  @override
  List<Object> get props => [];
}

final class EditTransactionError extends EditTransactionState {
  const EditTransactionError(this.message);
  final String message;
  @override
  List<Object> get props => [message];
}
