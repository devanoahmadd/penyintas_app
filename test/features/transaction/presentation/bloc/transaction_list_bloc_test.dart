import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/delete_transaction_usecase.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/get_transactions_usecase.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/transaction_list_bloc.dart';

class MockGetTransactionsUseCase extends Mock
    implements GetTransactionsUseCase {}

class MockDeleteTransactionUseCase extends Mock
    implements DeleteTransactionUseCase {}

class FakeGetTransactionsParams extends Fake implements GetTransactionsParams {}

void main() {
  late MockGetTransactionsUseCase mockGet;
  late MockDeleteTransactionUseCase mockDelete;

  final tFrom = DateTime(2026, 5, 1);
  final tTo = DateTime(2026, 5, 8);

  final tTransaction = TransactionEntity(
    id: 'tx-1',
    amount: 50000,
    category: 'food',
    type: TransactionType.expense,
    date: DateTime(2026, 5, 8),
    isFixed: false,
    isSynced: true,
    createdAt: DateTime(2026, 5, 8),
    updatedAt: DateTime(2026, 5, 8),
  );

  setUpAll(() {
    registerFallbackValue(FakeGetTransactionsParams());
  });

  setUp(() {
    mockGet = MockGetTransactionsUseCase();
    mockDelete = MockDeleteTransactionUseCase();
  });

  TransactionListBloc buildBloc() => TransactionListBloc(
    getTransactions: mockGet,
    deleteTransaction: mockDelete,
  );

  group('LoadTransactions', () {
    blocTest<TransactionListBloc, TransactionListState>(
      'emits Loading then Loaded with transactions',
      build: buildBloc,
      setUp: () {
        when(
          () => mockGet(any()),
        ).thenAnswer((_) async => Right([tTransaction]));
      },
      act: (bloc) => bloc.add(LoadTransactions(from: tFrom, to: tTo)),
      expect: () => [
        isA<TransactionListLoading>(),
        isA<TransactionListLoaded>()
            .having((s) => s.transactions.length, 'length', 1)
            .having((s) => s.totalSpent, 'totalSpent', 50000),
      ],
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'emits Loading then Error on failure',
      build: buildBloc,
      setUp: () {
        when(
          () => mockGet(any()),
        ).thenAnswer((_) async => const Left(CacheFailure()));
      },
      act: (bloc) => bloc.add(LoadTransactions(from: tFrom, to: tTo)),
      expect: () => [
        isA<TransactionListLoading>(),
        isA<TransactionListError>(),
      ],
    );
  });

  group('FilterChanged', () {
    blocTest<TransactionListBloc, TransactionListState>(
      'filters to category when loaded',
      build: buildBloc,
      seed: () => TransactionListLoaded(
        transactions: [tTransaction],
        filtered: [tTransaction],
        totalSpent: 50000,
        typeFilter: null,
        from: tFrom,
        to: tTo,
      ),
      act: (bloc) => bloc.add(const FilterChanged(TransactionType.income)),
      expect: () => [
        isA<TransactionListLoaded>()
            .having((s) => s.filtered.length, 'filtered empty', 0)
            .having((s) => s.typeFilter, 'filter', TransactionType.income),
      ],
    );
  });

  group('DeleteTransactionRequested', () {
    blocTest<TransactionListBloc, TransactionListState>(
      'removes item from list on success',
      build: buildBloc,
      seed: () => TransactionListLoaded(
        transactions: [tTransaction],
        filtered: [tTransaction],
        totalSpent: 50000,
        typeFilter: null,
        from: tFrom,
        to: tTo,
      ),
      setUp: () {
        when(
          () => mockDelete(any()),
        ).thenAnswer((_) async => const Right(null));
      },
      act: (bloc) => bloc.add(const DeleteTransactionRequested('tx-1')),
      expect: () => [
        isA<TransactionListLoaded>()
            .having((s) => s.transactions.length, 'length', 0)
            .having((s) => s.totalSpent, 'totalSpent', 0),
      ],
    );
  });

  group('FilterSheetApplied', () {
    blocTest<TransactionListBloc, TransactionListState>(
      'filters out transactions not matching category',
      build: buildBloc,
      seed: () => TransactionListLoaded(
        transactions: [tTransaction],
        filtered: [tTransaction],
        totalSpent: 50000,
        typeFilter: null,
        from: tFrom,
        to: tTo,
      ),
      act: (bloc) =>
          bloc.add(const FilterSheetApplied(categories: {'shopping'})),
      expect: () => [
        isA<TransactionListLoaded>()
            .having((s) => s.filtered.length, 'filtered empty', 0)
            .having((s) => s.categoryFilter, 'categoryFilter set', {
              'shopping',
            }),
      ],
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'null categories clears active filter and passes all transactions',
      build: buildBloc,
      seed: () => TransactionListLoaded(
        transactions: [tTransaction],
        filtered: [],
        totalSpent: 50000,
        typeFilter: null,
        categoryFilter: {'shopping'},
        from: tFrom,
        to: tTo,
      ),
      act: (bloc) => bloc.add(const FilterSheetApplied()),
      expect: () => [
        isA<TransactionListLoaded>()
            .having((s) => s.filtered.length, 'all pass', 1)
            .having((s) => s.categoryFilter, 'categoryFilter null', null),
      ],
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'minAmount filters out amounts below threshold',
      build: buildBloc,
      seed: () => TransactionListLoaded(
        transactions: [tTransaction], // amount = 50000
        filtered: [tTransaction],
        totalSpent: 50000,
        typeFilter: null,
        from: tFrom,
        to: tTo,
      ),
      act: (bloc) => bloc.add(const FilterSheetApplied(minAmount: 100000)),
      expect: () => [
        isA<TransactionListLoaded>().having(
          (s) => s.filtered.length,
          'filtered empty',
          0,
        ),
      ],
    );
  });
}
