import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/delete_transaction_usecase.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/get_transactions_usecase.dart';

part 'transaction_list_event.dart';
part 'transaction_list_state.dart';

class TransactionListBloc
    extends Bloc<TransactionListEvent, TransactionListState> {
  TransactionListBloc({
    required GetTransactionsUseCase getTransactions,
    required DeleteTransactionUseCase deleteTransaction,
  })  : _getTransactions = getTransactions,
        _deleteTransaction = deleteTransaction,
        super(const TransactionListLoading()) {
    on<LoadTransactions>(_onLoad);
    on<RefreshTransactions>(_onRefresh);
    on<FilterChanged>(_onFilterChanged);
    on<DeleteTransactionRequested>(_onDelete);
  }

  final GetTransactionsUseCase _getTransactions;
  final DeleteTransactionUseCase _deleteTransaction;

  Future<void> _onLoad(
      LoadTransactions event, Emitter<TransactionListState> emit) async {
    emit(const TransactionListLoading());
    await _fetchAndEmit(event.from, event.to, null, emit);
  }

  Future<void> _onRefresh(
      RefreshTransactions event, Emitter<TransactionListState> emit) async {
    if (state is! TransactionListLoaded) return;
    final s = state as TransactionListLoaded;
    await _fetchAndEmit(s.from, s.to, s.typeFilter, emit);
  }

  void _onFilterChanged(
      FilterChanged event, Emitter<TransactionListState> emit) {
    if (state is! TransactionListLoaded) return;
    final s = state as TransactionListLoaded;
    final filtered = event.type == null
        ? s.transactions
        : s.transactions.where((t) => t.type == event.type).toList();
    emit(s.copyWith(
      filtered: filtered,
      typeFilter: () => event.type,
    ));
  }

  Future<void> _onDelete(
      DeleteTransactionRequested event,
      Emitter<TransactionListState> emit) async {
    final result = await _deleteTransaction(event.id);
    result.fold(
      (failure) {},
      (_) {
        if (state is TransactionListLoaded) {
          final s = state as TransactionListLoaded;
          final updated =
              s.transactions.where((t) => t.id != event.id).toList();
          final filtered =
              s.filtered.where((t) => t.id != event.id).toList();
          final totalSpent = updated
              .where((t) => t.type == TransactionType.expense)
              .fold(0, (sum, t) => sum + t.amount);
          emit(s.copyWith(
            transactions: updated,
            filtered: filtered,
            totalSpent: totalSpent,
          ));
        }
      },
    );
  }

  Future<void> _fetchAndEmit(
    DateTime from,
    DateTime to,
    TransactionType? typeFilter,
    Emitter<TransactionListState> emit,
  ) async {
    final result = await _getTransactions(
      GetTransactionsParams(from: from, to: to),
    );
    result.fold(
      (failure) => emit(TransactionListError(failure.message)),
      (transactions) {
        final filtered = typeFilter == null
            ? transactions
            : transactions.where((t) => t.type == typeFilter).toList();
        final totalSpent = transactions
            .where((t) => t.type == TransactionType.expense)
            .fold(0, (sum, t) => sum + t.amount);
        emit(TransactionListLoaded(
          transactions: transactions,
          filtered: filtered,
          totalSpent: totalSpent,
          typeFilter: typeFilter,
          from: from,
          to: to,
        ));
      },
    );
  }
}
