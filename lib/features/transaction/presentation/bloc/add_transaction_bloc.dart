import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/add_transaction_usecase.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/get_categories_usecase.dart';
import 'package:uuid/uuid.dart';

part 'add_transaction_event.dart';
part 'add_transaction_state.dart';

class AddTransactionBloc
    extends Bloc<AddTransactionEvent, AddTransactionState> {
  AddTransactionBloc({
    required AddTransactionUseCase addTransaction,
    required GetCategoriesUseCase getCategories,
  }) : _addTransaction = addTransaction,
       _getCategories = getCategories,
       super(
         AddTransactionInProgress(
           amount: 0,
           selectedCategory: null,
           type: TransactionType.expense,
           note: '',
           date: DateTime.now(),
         ),
       ) {
    on<AmountChanged>(_onAmountChanged);
    on<CategorySelected>(_onCategorySelected);
    on<TypeToggled>(_onTypeToggled);
    on<TypeSet>(_onTypeSet);
    on<NoteChanged>(_onNoteChanged);
    on<DateChanged>(_onDateChanged);
    on<GoalSelected>(_onGoalSelected);
    on<SubmitTransaction>(_onSubmit);
    on<LoadTransactionCategories>(_onLoadCategories);
  }

  final AddTransactionUseCase _addTransaction;
  final GetCategoriesUseCase _getCategories;
  static const _uuid = Uuid();

  void _onAmountChanged(
    AmountChanged event,
    Emitter<AddTransactionState> emit,
  ) {
    if (state is AddTransactionInProgress) {
      emit((state as AddTransactionInProgress).copyWith(amount: event.amount));
    }
  }

  void _onCategorySelected(
    CategorySelected event,
    Emitter<AddTransactionState> emit,
  ) {
    if (state is AddTransactionInProgress) {
      emit(
        (state as AddTransactionInProgress).copyWith(
          selectedCategory: event.categorySlug,
        ),
      );
    }
  }

  void _onTypeToggled(TypeToggled event, Emitter<AddTransactionState> emit) {
    if (state is AddTransactionInProgress) {
      final s = state as AddTransactionInProgress;
      final next = s.type == TransactionType.expense
          ? TransactionType.income
          : TransactionType.expense;
      // Clear goal link dan selectedCategory saat beralih tipe
      emit(
        s.copyWith(
          type: next,
          selectedGoalId: null,
          clearSelectedCategory: true,
        ),
      );
      add(const LoadTransactionCategories());
    }
  }

  void _onTypeSet(TypeSet event, Emitter<AddTransactionState> emit) {
    if (state is AddTransactionInProgress) {
      final s = state as AddTransactionInProgress;
      if (s.type == event.type) return;
      emit(
        s.copyWith(
          type: event.type,
          selectedGoalId: null,
          clearSelectedCategory: true,
        ),
      );
      add(const LoadTransactionCategories());
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

  void _onGoalSelected(GoalSelected event, Emitter<AddTransactionState> emit) {
    if (state is AddTransactionInProgress) {
      emit(
        (state as AddTransactionInProgress).copyWith(
          selectedGoalId: event.goalId,
        ),
      );
    }
  }

  Future<void> _onLoadCategories(
    LoadTransactionCategories event,
    Emitter<AddTransactionState> emit,
  ) async {
    if (state is! AddTransactionInProgress) return;
    final result = await _getCategories(const NoParams());
    result.fold(
      (_) {}, // silently ignore — kategori tidak wajib untuk submit
      (cats) {
        if (state is! AddTransactionInProgress) return;
        final s = state as AddTransactionInProgress;
        final filtered = s.type == TransactionType.expense
            ? cats.where((c) => c.isExpense).toList()
            : cats.where((c) => c.isIncomeType).toList();
        emit(s.copyWith(availableCategories: filtered));
      },
    );
  }

  Future<void> _onSubmit(
    SubmitTransaction event,
    Emitter<AddTransactionState> emit,
  ) async {
    if (state is! AddTransactionInProgress) return;
    final s = state as AddTransactionInProgress;
    if (!s.isValid) return;

    emit(const AddTransactionLoading());

    final now = DateTime.now();
    final categorySlug = s.selectedCategory!;
    final entity = TransactionEntity(
      id: _uuid.v4(),
      amount: s.amount,
      category: categorySlug,
      type: s.type,
      note: s.note.isEmpty ? null : s.note,
      date: s.date,
      isFixed: categorySlug == 'fixed',
      isSynced: false,
      createdAt: now,
      updatedAt: now,
      goalId: s.type == TransactionType.income ? s.selectedGoalId : null,
    );

    final result = await _addTransaction(entity);
    result.fold(
      (failure) => emit(AddTransactionError(failure.message)),
      (_) => emit(const AddTransactionSuccess()),
    );
  }
}
