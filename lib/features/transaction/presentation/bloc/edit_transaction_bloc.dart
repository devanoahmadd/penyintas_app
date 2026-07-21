import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/update_transaction_usecase.dart';

part 'edit_transaction_event.dart';
part 'edit_transaction_state.dart';

class EditTransactionBloc
    extends Bloc<EditTransactionEvent, EditTransactionState> {
  EditTransactionBloc({
    required UpdateTransactionUseCase updateTransaction,
    required TransactionEntity initial,
  }) : _updateTransaction = updateTransaction,
       super(
         EditTransactionInProgress(
           originalId: initial.id,
           originalCreatedAt: initial.createdAt,
           amount: initial.amount,
           category: initial.category,
           type: initial.type,
           note: initial.note ?? '',
           date: initial.date,
           selectedGoalId: initial.goalId,
         ),
       ) {
    on<EditAmountChanged>(_onAmountChanged);
    on<EditCategorySelected>(_onCategorySelected);
    on<EditTypeSet>(_onTypeSet);
    on<EditNoteChanged>(_onNoteChanged);
    on<EditDateChanged>(_onDateChanged);
    on<EditGoalSelected>(_onGoalSelected);
    on<SubmitEdit>(_onSubmit);
  }

  final UpdateTransactionUseCase _updateTransaction;

  void _onAmountChanged(
    EditAmountChanged event,
    Emitter<EditTransactionState> emit,
  ) {
    if (state is EditTransactionInProgress) {
      emit((state as EditTransactionInProgress).copyWith(amount: event.amount));
    }
  }

  void _onCategorySelected(
    EditCategorySelected event,
    Emitter<EditTransactionState> emit,
  ) {
    if (state is EditTransactionInProgress) {
      emit(
        (state as EditTransactionInProgress).copyWith(category: event.category),
      );
    }
  }

  void _onTypeSet(EditTypeSet event, Emitter<EditTransactionState> emit) {
    if (state is EditTransactionInProgress) {
      final s = state as EditTransactionInProgress;
      if (s.type == event.type) return;
      emit(s.copyWith(type: event.type, selectedGoalId: null));
    }
  }

  void _onNoteChanged(
    EditNoteChanged event,
    Emitter<EditTransactionState> emit,
  ) {
    if (state is EditTransactionInProgress) {
      emit((state as EditTransactionInProgress).copyWith(note: event.note));
    }
  }

  void _onDateChanged(
    EditDateChanged event,
    Emitter<EditTransactionState> emit,
  ) {
    if (state is EditTransactionInProgress) {
      emit((state as EditTransactionInProgress).copyWith(date: event.date));
    }
  }

  void _onGoalSelected(
    EditGoalSelected event,
    Emitter<EditTransactionState> emit,
  ) {
    if (state is EditTransactionInProgress) {
      emit(
        (state as EditTransactionInProgress).copyWith(
          selectedGoalId: event.goalId,
        ),
      );
    }
  }

  Future<void> _onSubmit(
    SubmitEdit event,
    Emitter<EditTransactionState> emit,
  ) async {
    if (state is! EditTransactionInProgress) return;
    final s = state as EditTransactionInProgress;
    if (!s.isValid) return;

    emit(const EditTransactionLoading());

    final entity = TransactionEntity(
      id: s.originalId,
      amount: s.amount,
      category: s.category,
      type: s.type,
      note: s.note.isEmpty ? null : s.note,
      date: s.date,
      isFixed: s.category == 'fixed',
      isSynced: false,
      createdAt: s.originalCreatedAt,
      updatedAt: DateTime.now(),
      goalId: s.type == TransactionType.income ? s.selectedGoalId : null,
    );

    final result = await _updateTransaction(entity);
    result.fold(
      (failure) => emit(EditTransactionError(failure.message)),
      (_) => emit(const EditTransactionSuccess()),
    );
  }
}
