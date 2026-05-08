import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/add_transaction_usecase.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/add_transaction_bloc.dart';

class MockAddTransactionUseCase extends Mock implements AddTransactionUseCase {}

class FakeTransactionEntity extends Fake implements TransactionEntity {}

void main() {
  late MockAddTransactionUseCase mockUseCase;

  setUpAll(() {
    registerFallbackValue(FakeTransactionEntity());
  });

  setUp(() {
    mockUseCase = MockAddTransactionUseCase();
  });

  AddTransactionBloc buildBloc() =>
      AddTransactionBloc(addTransaction: mockUseCase);

  group('AmountChanged', () {
    blocTest<AddTransactionBloc, AddTransactionState>(
      'emits updated amount',
      build: buildBloc,
      act: (bloc) => bloc.add(const AmountChanged(75000)),
      expect: () => [
        isA<AddTransactionInProgress>()
            .having((s) => s.amount, 'amount', 75000),
      ],
    );
  });

  group('CategorySelected', () {
    blocTest<AddTransactionBloc, AddTransactionState>(
      'emits updated category',
      build: buildBloc,
      act: (bloc) => bloc.add(const CategorySelected(TransactionCategory.transport)),
      expect: () => [
        isA<AddTransactionInProgress>()
            .having((s) => s.category, 'category', TransactionCategory.transport),
      ],
    );
  });

  group('TypeToggled', () {
    blocTest<AddTransactionBloc, AddTransactionState>(
      'toggles expense to income',
      build: buildBloc,
      act: (bloc) => bloc.add(const TypeToggled()),
      expect: () => [
        isA<AddTransactionInProgress>()
            .having((s) => s.type, 'type', TransactionType.income),
      ],
    );
  });

  group('SubmitTransaction', () {
    blocTest<AddTransactionBloc, AddTransactionState>(
      'does not emit if amount is 0',
      build: buildBloc,
      act: (bloc) => bloc.add(const SubmitTransaction()),
      expect: () => [],
    );

    blocTest<AddTransactionBloc, AddTransactionState>(
      'emits Loading then Success on usecase Right',
      build: buildBloc,
      seed: () => AddTransactionInProgress(
        amount: 50000,
        category: TransactionCategory.food,
        type: TransactionType.expense,
        note: '',
        date: DateTime(2026, 5, 8),
      ),
      setUp: () {
        when(() => mockUseCase(any()))
            .thenAnswer((_) async => const Right(null));
      },
      act: (bloc) => bloc.add(const SubmitTransaction()),
      expect: () => [
        isA<AddTransactionLoading>(),
        isA<AddTransactionSuccess>(),
      ],
    );

    blocTest<AddTransactionBloc, AddTransactionState>(
      'emits Loading then Error on usecase Left',
      build: buildBloc,
      seed: () => AddTransactionInProgress(
        amount: 50000,
        category: TransactionCategory.food,
        type: TransactionType.expense,
        note: '',
        date: DateTime(2026, 5, 8),
      ),
      setUp: () {
        when(() => mockUseCase(any()))
            .thenAnswer((_) async => const Left(CacheFailure()));
      },
      act: (bloc) => bloc.add(const SubmitTransaction()),
      expect: () => [
        isA<AddTransactionLoading>(),
        isA<AddTransactionError>(),
      ],
    );
  });
}
