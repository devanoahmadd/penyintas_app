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

/// Helper lokal test (d): salinan entity dengan `isFixed=false`.
/// `TransactionEntity` tidak punya `copyWith`, jadi dibangun ulang eksplisit.
///
/// `this.id` ditulis eksplisit: dartz mengekspor fungsi top-level `id<A>(A)`
/// yang menutupi `id` milik entity di dalam badan extension ini.
extension on TransactionEntity {
  TransactionEntity copyWithIsFixedFalse() => TransactionEntity(
    id: this.id,
    amount: amount,
    category: category,
    type: type,
    note: note,
    date: date,
    isFixed: false,
    isSynced: isSynced,
    createdAt: createdAt,
    updatedAt: updatedAt,
    goalId: goalId,
    sourceBillId: sourceBillId,
  );
}

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

  EditTransactionBloc buildBloc() =>
      EditTransactionBloc(updateTransaction: mockUpdate, initial: tTransaction);

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
        isA<EditTransactionInProgress>().having(
          (s) => s.amount,
          'amount',
          99000,
        ),
      ],
    );
  });

  group('EditCategorySelected', () {
    blocTest<EditTransactionBloc, EditTransactionState>(
      'update category di state',
      build: buildBloc,
      act: (b) => b.add(const EditCategorySelected('transport')),
      expect: () => [
        isA<EditTransactionInProgress>().having(
          (s) => s.category,
          'category',
          'transport',
        ),
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
        isA<EditTransactionInProgress>().having(
          (s) => s.note,
          'note',
          'Edited note',
        ),
      ],
    );
  });

  group('SubmitEdit', () {
    blocTest<EditTransactionBloc, EditTransactionState>(
      'emit Loading → Success saat update berhasil',
      build: buildBloc,
      setUp: () {
        when(
          () => mockUpdate(any()),
        ).thenAnswer((_) async => const Right(null));
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
        when(
          () => mockUpdate(any()),
        ).thenAnswer((_) async => Left(CacheFailure('Gagal menyimpan')));
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
        isA<EditTransactionInProgress>().having((s) => s.amount, 'amount', 0),
      ],
      verify: (_) {
        verifyNever(() => mockUpdate(any()));
      },
    );

    blocTest<EditTransactionBloc, EditTransactionState>(
      'entity yang di-submit memakai originalId dan originalCreatedAt',
      build: buildBloc,
      setUp: () {
        when(
          () => mockUpdate(any()),
        ).thenAnswer((_) async => const Right(null));
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

  // ── C1: state adalah proyeksi lossy dari entity ────────────────────────
  //
  // `_onSubmit` merekonstruksi TransactionEntity dari state. Dua field
  // entity tidak pernah masuk state, jadi rekonstruksinya menebak:
  // `isFixed` diturunkan ulang dari kategori, `sourceBillId` hilang jadi
  // null. Karena `updateTransaction` menulis companion PENUH
  // (transaction_local_datasource.dart:49), null itu ditulis balik sebagai
  // NULL — bukan dilewati.
  group('C1 — isFixed & sourceBillId bertahan lewat edit', () {
    TransactionEntity capturedEntity() {
      final captured = verify(() => mockUpdate(captureAny())).captured;
      return captured.first as TransactionEntity;
    }

    EditTransactionBloc buildFrom(TransactionEntity initial) =>
        EditTransactionBloc(updateTransaction: mockUpdate, initial: initial);

    final billTxn = TransactionEntity(
      id: 'tx-bill',
      amount: 800000,
      category: 'fixed',
      type: TransactionType.expense,
      date: DateTime(2026, 8, 1),
      isFixed: false, // opt-out sadar di sheet bayar tagihan
      isSynced: false,
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
      sourceBillId: 42,
    );

    final internetTxn = TransactionEntity(
      id: 'tx-internet',
      amount: 300000,
      category: 'internet', // BUKAN 'fixed'
      type: TransactionType.expense,
      date: DateTime(2026, 8, 2),
      isFixed: true, // dianggarkan di muka
      isSynced: false,
      createdAt: DateTime(2026, 8, 2),
      updatedAt: DateTime(2026, 8, 2),
    );

    blocTest<EditTransactionBloc, EditTransactionState>(
      '(a) category="fixed" + isFixed=false → tersimpan TETAP false '
      '(tanpa ini, saldo naik kembali sebesar yang sudah dibelanjakan)',
      build: () => buildFrom(billTxn),
      setUp: () {
        when(
          () => mockUpdate(any()),
        ).thenAnswer((_) async => const Right(null));
      },
      act: (b) => b.add(const SubmitEdit()),
      verify: (_) => expect(capturedEntity().isFixed, isFalse),
    );

    blocTest<EditTransactionBloc, EditTransactionState>(
      '(b) category="internet" + isFixed=true → tersimpan TETAP true',
      build: () => buildFrom(internetTxn),
      setUp: () {
        when(
          () => mockUpdate(any()),
        ).thenAnswer((_) async => const Right(null));
      },
      act: (b) => b.add(const SubmitEdit()),
      verify: (_) => expect(capturedEntity().isFixed, isTrue),
    );

    blocTest<EditTransactionBloc, EditTransactionState>(
      '(c) sourceBillId bertahan setelah edit (mengunci link undo K1/K2)',
      build: () => buildFrom(billTxn),
      setUp: () {
        when(
          () => mockUpdate(any()),
        ).thenAnswer((_) async => const Right(null));
      },
      act: (b) {
        b.add(const EditAmountChanged(850000));
        b.add(const SubmitEdit());
      },
      verify: (_) => expect(capturedEntity().sourceBillId, 42),
    );

    blocTest<EditTransactionBloc, EditTransactionState>(
      '(d) mengganti kategori ke "fixed" TIDAK menyalakan isFixed — '
      'pengguna mengganti label, bukan menyatakan sudah dianggarkan di muka',
      build: () => buildFrom(internetTxn.copyWithIsFixedFalse()),
      setUp: () {
        when(
          () => mockUpdate(any()),
        ).thenAnswer((_) async => const Right(null));
      },
      act: (b) {
        b.add(const EditCategorySelected('fixed'));
        b.add(const SubmitEdit());
      },
      verify: (_) => expect(capturedEntity().isFixed, isFalse),
    );
  });
}
