import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/update_transaction_usecase.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/edit_transaction_bloc.dart';

class MockUpdateTransactionUseCase extends Mock
    implements UpdateTransactionUseCase {}

class FakeTransactionEntity extends Fake implements TransactionEntity {}

void main() {
  late MockUpdateTransactionUseCase mockUpdate;

  final tTransaction = TransactionEntity(
    id: 'tx-001',
    amount: 45000,
    category: 'food',
    type: TransactionType.expense,
    note: 'Makan siang',
    date: DateTime(2026, 5, 28, 12, 0),
    isFixed: false,
    isSynced: false,
    createdAt: DateTime(2026, 5, 28),
    updatedAt: DateTime(2026, 5, 28),
  );

  setUpAll(() {
    registerFallbackValue(FakeTransactionEntity());
  });

  setUp(() {
    mockUpdate = MockUpdateTransactionUseCase();
  });

  EditTransactionBloc buildBloc() => EditTransactionBloc(
        updateTransaction: mockUpdate,
        initial: tTransaction,
      );

  group('initial state', () {
    test('di-seed dari TransactionEntity yang diberikan', () {
      final bloc = buildBloc();
      final s = bloc.state as EditTransactionInProgress;
      expect(s.originalId, 'tx-001');
      expect(s.amount, 45000);
      expect(s.category, 'food');
      expect(s.type, TransactionType.expense);
      expect(s.note, 'Makan siang');
    });
  });

  group('EditAmountChanged', () {
    blocTest<EditTransactionBloc, EditTransactionState>(
      'update amount di state',
      build: buildBloc,
      act: (b) => b.add(const EditAmountChanged(99000)),
      expect: () => [
        isA<EditTransactionInProgress>()
            .having((s) => s.amount, 'amount', 99000),
      ],
    );
  });

  group('EditCategorySelected', () {
    blocTest<EditTransactionBloc, EditTransactionState>(
      'update category di state',
      build: buildBloc,
      act: (b) =>
          b.add(const EditCategorySelected('transport')),
      expect: () => [
        isA<EditTransactionInProgress>().having(
            (s) => s.category, 'category', 'transport'),
      ],
    );
  });

  group('EditTypeSet', () {
    blocTest<EditTransactionBloc, EditTransactionState>(
      'set type ke income dan clear selectedGoalId',
      build: buildBloc,
      act: (b) => b.add(const EditTypeSet(TransactionType.income)),
      expect: () => [
        isA<EditTransactionInProgress>()
            .having((s) => s.type, 'type', TransactionType.income)
            .having((s) => s.selectedGoalId, 'goalId', isNull),
      ],
    );

    blocTest<EditTransactionBloc, EditTransactionState>(
      'tidak emit apapun jika type sudah sama',
      build: buildBloc,
      act: (b) => b.add(const EditTypeSet(TransactionType.expense)),
      expect: () => [],
    );
  });

  group('EditNoteChanged', () {
    blocTest<EditTransactionBloc, EditTransactionState>(
      'update note di state',
      build: buildBloc,
      act: (b) => b.add(const EditNoteChanged('Edited note')),
      expect: () => [
        isA<EditTransactionInProgress>()
            .having((s) => s.note, 'note', 'Edited note'),
      ],
    );
  });

  group('SubmitEdit', () {
    blocTest<EditTransactionBloc, EditTransactionState>(
      'emit Loading → Success saat update berhasil',
      build: buildBloc,
      setUp: () {
        when(() => mockUpdate(any()))
            .thenAnswer((_) async => const Right(null));
      },
      act: (b) => b.add(const SubmitEdit()),
      expect: () => [
        const EditTransactionLoading(),
        const EditTransactionSuccess(),
      ],
      verify: (_) {
        verify(() => mockUpdate(any())).called(1);
      },
    );

    blocTest<EditTransactionBloc, EditTransactionState>(
      'emit Loading → Error saat update gagal',
      build: buildBloc,
      setUp: () {
        when(() => mockUpdate(any())).thenAnswer(
          (_) async => Left(CacheFailure('Gagal menyimpan')),
        );
      },
      act: (b) => b.add(const SubmitEdit()),
      expect: () => [
        const EditTransactionLoading(),
        const EditTransactionError('Gagal menyimpan'),
      ],
    );

    blocTest<EditTransactionBloc, EditTransactionState>(
      'tidak memanggil usecase jika amount 0 (tidak valid)',
      build: buildBloc,
      act: (b) async {
        b.add(const EditAmountChanged(0));
        b.add(const SubmitEdit());
      },
      expect: () => [
        isA<EditTransactionInProgress>()
            .having((s) => s.amount, 'amount', 0),
      ],
      verify: (_) {
        verifyNever(() => mockUpdate(any()));
      },
    );

    blocTest<EditTransactionBloc, EditTransactionState>(
      'entity yang di-submit memakai originalId dan originalCreatedAt',
      build: buildBloc,
      setUp: () {
        when(() => mockUpdate(any()))
            .thenAnswer((_) async => const Right(null));
      },
      act: (b) => b.add(const SubmitEdit()),
      verify: (_) {
        final captured = verify(() => mockUpdate(captureAny())).captured;
        final entity = captured.first as TransactionEntity;
        expect(entity.id, 'tx-001');
        expect(entity.createdAt, DateTime(2026, 5, 28));
      },
    );
  });
}
