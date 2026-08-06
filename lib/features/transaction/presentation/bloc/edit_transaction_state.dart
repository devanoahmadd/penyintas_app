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
    required this.isFixed,
    required this.sourceBillId,
    this.selectedGoalId,
  });

  final String originalId;
  final DateTime originalCreatedAt;
  final int amount;
  final String category;
  final TransactionType type;
  final String note;
  final DateTime date;
  final int? selectedGoalId;

  /// C1 — dibawa apa adanya dari entity awal, TIDAK pernah diturunkan ulang
  /// dari kategori dan TIDAK bisa diubah event apa pun. `isFixed` adalah
  /// pernyataan akuntansi ("sudah diwakili fixedExpenses di muka"), bukan
  /// label kategori; tidak ada UI untuk menyatakannya saat mengedit.
  final bool isFixed;

  /// C1 — link balik ke tagihan asal (undo K1/K2). Hilang dari state berarti
  /// hilang dari DB, karena updateTransaction menulis companion PENUH.
  final int? sourceBillId;

  bool get isValid => amount > 0 && amount <= 100000000;

  /// `isFixed` dan `sourceBillId` sengaja TIDAK punya parameter di sini —
  /// menyediakannya sama dengan membuka kembali pintu yang C1 tutup.
  EditTransactionInProgress copyWith({
    int? amount,
    String? category,
    TransactionType? type,
    String? note,
    DateTime? date,
    Object? selectedGoalId = _kEditSentinel,
  }) => EditTransactionInProgress(
    originalId: originalId,
    originalCreatedAt: originalCreatedAt,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    type: type ?? this.type,
    note: note ?? this.note,
    date: date ?? this.date,
    isFixed: isFixed,
    selectedGoalId: identical(selectedGoalId, _kEditSentinel)
        ? this.selectedGoalId
        : selectedGoalId as int?,
    sourceBillId: sourceBillId,
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
    isFixed,
    selectedGoalId,
    sourceBillId,
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
