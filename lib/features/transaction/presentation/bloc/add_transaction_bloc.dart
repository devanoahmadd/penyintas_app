import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/add_transaction_usecase.dart';
import 'package:uuid/uuid.dart';

part 'add_transaction_event.dart';
part 'add_transaction_state.dart';

class AddTransactionBloc
    extends Bloc<AddTransactionEvent, AddTransactionState> {
  AddTransactionBloc({required AddTransactionUseCase addTransaction})
      : _addTransaction = addTransaction,
        super(AddTransactionInProgress(
          amount: 0,
          category: TransactionCategory.food,
          type: TransactionType.expense,
          note: '',
          date: DateTime.now(),
        )) {
    on<AmountChanged>(_onAmountChanged);
    on<CategorySelected>(_onCategorySelected);
    on<TypeToggled>(_onTypeToggled);
    on<NoteChanged>(_onNoteChanged);
    on<DateChanged>(_onDateChanged);
    on<SubmitTransaction>(_onSubmit);
  }

  final AddTransactionUseCase _addTransaction;
  static const _uuid = Uuid();

  void _onAmountChanged(AmountChanged event, Emitter<AddTransactionState> emit) {
    if (state is AddTransactionInProgress) {
      emit((state as AddTransactionInProgress).copyWith(amount: event.amount));
    }
  }

  void _onCategorySelected(
      CategorySelected event, Emitter<AddTransactionState> emit) {
    if (state is AddTransactionInProgress) {
      emit((state as AddTransactionInProgress)
          .copyWith(category: event.category));
    }
  }

  void _onTypeToggled(TypeToggled event, Emitter<AddTransactionState> emit) {
    if (state is AddTransactionInProgress) {
      final s = state as AddTransactionInProgress;
      final next = s.type == TransactionType.expense
          ? TransactionType.income
          : TransactionType.expense;
      emit(s.copyWith(type: next));
    }
  }

  void _onNoteChanged(NoteChanged event, Emitter<AddTransactionState> emit) {
    if (state is AddTransactionInProgress) {
      emit((state as AddTransactionInProgress).copyWith(note: event.note));
    }
  }

  void _onDateChanged(DateChanged event, Emitter<AddTransactionState> emit) {
    if (state is AddTransactionInProgress) {
      emit((state as AddTransactionInProgress).copyWith(date: event.date));
    }
  }

  Future<void> _onSubmit(
      SubmitTransaction event, Emitter<AddTransactionState> emit) async {
    if (state is! AddTransactionInProgress) return;
    final s = state as AddTransactionInProgress;
    if (!s.isValid) return;

    emit(const AddTransactionLoading());

    final now = DateTime.now();
    final entity = TransactionEntity(
      id: _uuid.v4(),
      amount: s.amount,
      category: s.category,
      type: s.type,
      note: s.note.isEmpty ? null : s.note,
      date: s.date,
      isFixed: s.category == TransactionCategory.fixed,
      isSynced: false,
      createdAt: now,
      updatedAt: now,
    );

    final result = await _addTransaction(entity);
    result.fold(
      (failure) => emit(AddTransactionError(failure.message)),
      (_) => emit(const AddTransactionSuccess()),
    );
  }
}
