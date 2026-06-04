import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/add_transaction_usecase.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/get_categories_usecase.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/add_transaction_bloc.dart';

class MockAddTransactionUseCase extends Mock implements AddTransactionUseCase {}

class MockGetCategoriesUseCase extends Mock implements GetCategoriesUseCase {}

class FakeTransactionEntity extends Fake implements TransactionEntity {}

class FakeNoParams extends Fake implements NoParams {}

const _expenseCat = CategoryEntity(
  id: 1,
  slug: 'food',
  labelKey: 'category_food',
  isBuiltIn: true,
  isLimitable: true,
  type: 'expense',
  sortOrder: 0,
);

const _incomeCat = CategoryEntity(
  id: 8,
  slug: 'income',
  labelKey: 'category_income',
  isBuiltIn: true,
  isLimitable: false,
  type: 'income',
  sortOrder: 7,
);

void main() {
  late MockAddTransactionUseCase mockAddTransaction;
  late MockGetCategoriesUseCase mockGetCategories;

  setUpAll(() {
    registerFallbackValue(FakeTransactionEntity());
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    mockAddTransaction = MockAddTransactionUseCase();
    mockGetCategories = MockGetCategoriesUseCase();
    // Default: return both categories
    when(() => mockGetCategories(any()))
        .thenAnswer((_) async => const Right([_expenseCat, _incomeCat]));
  });

  AddTransactionBloc buildBloc() => AddTransactionBloc(
        addTransaction: mockAddTransaction,
        getCategories: mockGetCategories,
      );

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
      'emits updated selectedCategory',
      build: buildBloc,
      act: (bloc) => bloc.add(const CategorySelected('transport')),
      expect: () => [
        isA<AddTransactionInProgress>()
            .having((s) => s.selectedCategory, 'selectedCategory', 'transport'),
      ],
    );
  });

  group('LoadTransactionCategories', () {
    blocTest<AddTransactionBloc, AddTransactionState>(
      'emits availableCategories filtered by expense type',
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadTransactionCategories()),
      expect: () => [
        isA<AddTransactionInProgress>().having(
          (s) => s.availableCategories.map((c) => c.slug).toList(),
          'availableCategories slugs',
          ['food'],
        ),
      ],
    );
  });

  group('TypeToggled', () {
    blocTest<AddTransactionBloc, AddTransactionState>(
      'toggles expense to income and clears selectedCategory',
      build: buildBloc,
      act: (bloc) => bloc.add(const TypeToggled()),
      expect: () => [
        // First emit: type toggled, selectedCategory cleared
        isA<AddTransactionInProgress>()
            .having((s) => s.type, 'type', TransactionType.income)
            .having((s) => s.selectedCategory, 'selectedCategory', null),
        // Second emit: categories loaded for income type
        isA<AddTransactionInProgress>().having(
          (s) => s.availableCategories.map((c) => c.slug).toList(),
          'availableCategories slugs',
          ['income'],
        ),
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
      'does not emit if selectedCategory is null',
      build: buildBloc,
      seed: () => AddTransactionInProgress(
        amount: 50000,
        selectedCategory: null,
        type: TransactionType.expense,
        note: '',
        date: DateTime.fromMillisecondsSinceEpoch(0),
      ),
      act: (bloc) => bloc.add(const SubmitTransaction()),
      expect: () => [],
    );

    blocTest<AddTransactionBloc, AddTransactionState>(
      'emits Loading then Success on usecase Right',
      build: buildBloc,
      seed: () => AddTransactionInProgress(
        amount: 50000,
        selectedCategory: 'food',
        type: TransactionType.expense,
        note: '',
        date: DateTime.fromMillisecondsSinceEpoch(0),
      ),
      setUp: () {
        when(() => mockAddTransaction(any()))
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
        selectedCategory: 'food',
        type: TransactionType.expense,
        note: '',
        date: DateTime.fromMillisecondsSinceEpoch(0),
      ),
      setUp: () {
        when(() => mockAddTransaction(any()))
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
