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
  }) : _getTransactions = getTransactions,
       _deleteTransaction = deleteTransaction,
       super(const TransactionListLoading()) {
    on<LoadTransactions>(_onLoad);
    on<RefreshTransactions>(_onRefresh);
    on<FilterChanged>(_onFilterChanged);
    on<FilterSheetApplied>(_onFilterSheetApplied);
    on<DeleteTransactionRequested>(_onDelete);
  }

  final GetTransactionsUseCase _getTransactions;
  final DeleteTransactionUseCase _deleteTransaction;

  Future<void> _onLoad(
    LoadTransactions event,
    Emitter<TransactionListState> emit,
  ) async {
    emit(const TransactionListLoading());
    await _fetchAndEmit(event.from, event.to, null, emit);
  }

  Future<void> _onRefresh(
    RefreshTransactions event,
    Emitter<TransactionListState> emit,
  ) async {
    if (state is! TransactionListLoaded) return;
    final s = state as TransactionListLoaded;
    final now = DateTime.now();
    // s.to diset saat halaman pertama dibuka — bisa usang dalam hitungan detik.
    // Transaksi baru punya date > s.to, menyebabkan query tidak menemukannya.
    // Perbarui to ke sekarang agar transaksi yang baru ditambahkan ikut terbaca.
    final isCurrentMonth = s.from.year == now.year && s.from.month == now.month;
    await _fetchAndEmit(
      s.from,
      isCurrentMonth ? now : s.to,
      s.typeFilter,
      emit,
      categoryFilter: s.categoryFilter,
      minAmount: s.minAmount,
      maxAmount: s.maxAmount,
    );
  }

  void _onFilterChanged(
    FilterChanged event,
    Emitter<TransactionListState> emit,
  ) {
    if (state is! TransactionListLoaded) return;
    final s = state as TransactionListLoaded;
    emit(
      s.copyWith(
        filtered: _applyFilters(
          s.transactions,
          typeFilter: event.type,
          categoryFilter: s.categoryFilter,
          minAmount: s.minAmount,
          maxAmount: s.maxAmount,
        ),
        typeFilter: () => event.type,
      ),
    );
  }

  void _onFilterSheetApplied(
    FilterSheetApplied event,
    Emitter<TransactionListState> emit,
  ) {
    if (state is! TransactionListLoaded) return;
    final s = state as TransactionListLoaded;
    emit(
      s.copyWith(
        filtered: _applyFilters(
          s.transactions,
          typeFilter: s.typeFilter,
          categoryFilter: event.categories,
          minAmount: event.minAmount,
          maxAmount: event.maxAmount,
        ),
        categoryFilter: () => event.categories,
        minAmount: () => event.minAmount,
        maxAmount: () => event.maxAmount,
      ),
    );
  }

  Future<void> _onDelete(
    DeleteTransactionRequested event,
    Emitter<TransactionListState> emit,
  ) async {
    if (state is! TransactionListLoaded) return;
    final s = state as TransactionListLoaded;
    emit(s.copyWith(deleteError: () => null));
    final result = await _deleteTransaction(event.id);
    result.fold(
      (failure) {
        if (state is TransactionListLoaded) {
          emit(
            (state as TransactionListLoaded).copyWith(
              deleteError: () => failure.message,
            ),
          );
        }
      },
      (_) {
        if (state is TransactionListLoaded) {
          final current = state as TransactionListLoaded;
          final updated = current.transactions
              .where((t) => t.id != event.id)
              .toList();
          final filtered = current.filtered
              .where((t) => t.id != event.id)
              .toList();
          final totalSpent = updated
              .where((t) => t.type == TransactionType.expense)
              .fold(0, (sum, t) => sum + t.amount);
          emit(
            current.copyWith(
              transactions: updated,
              filtered: filtered,
              totalSpent: totalSpent,
              deleteError: () => null,
            ),
          );
        }
      },
    );
  }

  Future<void> _fetchAndEmit(
    DateTime from,
    DateTime to,
    TransactionType? typeFilter,
    Emitter<TransactionListState> emit, {
    Set<String>? categoryFilter,
    int? minAmount,
    int? maxAmount,
  }) async {
    final result = await _getTransactions(
      GetTransactionsParams(from: from, to: to),
    );
    result.fold((failure) => emit(TransactionListError(failure.message)), (
      transactions,
    ) {
      final filtered = _applyFilters(
        transactions,
        typeFilter: typeFilter,
        categoryFilter: categoryFilter,
        minAmount: minAmount,
        maxAmount: maxAmount,
      );
      final totalSpent = transactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0, (sum, t) => sum + t.amount);
      emit(
        TransactionListLoaded(
          transactions: transactions,
          filtered: filtered,
          totalSpent: totalSpent,
          typeFilter: typeFilter,
          categoryFilter: categoryFilter,
          minAmount: minAmount,
          maxAmount: maxAmount,
          from: from,
          to: to,
        ),
      );
    });
  }

  static List<TransactionEntity> _applyFilters(
    List<TransactionEntity> transactions, {
    TransactionType? typeFilter,
    Set<String>? categoryFilter,
    int? minAmount,
    int? maxAmount,
  }) {
    return transactions.where((t) {
      if (typeFilter != null && t.type != typeFilter) {
        return false;
      }
      if (categoryFilter != null &&
          categoryFilter.isNotEmpty &&
          !categoryFilter.contains(t.category)) {
        return false;
      }
      if (minAmount != null && t.amount < minAmount) {
        return false;
      }
      if (maxAmount != null && t.amount > maxAmount) {
        return false;
      }
      return true;
    }).toList();
  }
}
