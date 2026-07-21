part of 'add_transaction_bloc.dart';

sealed class AddTransactionState extends Equatable {
  const AddTransactionState();
}

final class AddTransactionInProgress extends AddTransactionState {
  const AddTransactionInProgress({
    required this.amount,
    required this.type,
    required this.note,
    required this.date,
    this.selectedCategory,
    this.selectedGoalId,
    this.availableCategories = const [],
  });

  final int amount;

  /// Slug kategori yang dipilih (mis. 'food', 'transport').
  /// null = belum dipilih.
  final String? selectedCategory;

  final TransactionType type;
  final String note;
  final DateTime date;

  /// Daftar kategori yang bisa dipilih, diload dari DB sesuai tipe transaksi.
  final List<CategoryEntity> availableCategories;

  /// null = tidak dikaitkan ke tujuan tabungan.
  final int? selectedGoalId;

  bool get isValid =>
      amount > 0 && amount <= 100000000 && selectedCategory != null;

  AddTransactionInProgress copyWith({
    int? amount,
    String? selectedCategory,
    bool clearSelectedCategory = false,
    TransactionType? type,
    String? note,
    DateTime? date,
    List<CategoryEntity>? availableCategories,
    Object? selectedGoalId = _kSentinel,
  }) => AddTransactionInProgress(
    amount: amount ?? this.amount,
    selectedCategory: clearSelectedCategory
        ? null
        : (selectedCategory ?? this.selectedCategory),
    type: type ?? this.type,
    note: note ?? this.note,
    date: date ?? this.date,
    availableCategories: availableCategories ?? this.availableCategories,
    selectedGoalId: identical(selectedGoalId, _kSentinel)
        ? this.selectedGoalId
        : selectedGoalId as int?,
  );

  @override
  List<Object?> get props => [
    amount,
    selectedCategory,
    type,
    note,
    date,
    availableCategories,
    selectedGoalId,
  ];
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
