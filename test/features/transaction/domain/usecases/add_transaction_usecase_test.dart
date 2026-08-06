import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';
import 'package:penyintas_app/features/budget/domain/repositories/budget_repository.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/add_transaction_usecase.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockBudgetRepository extends Mock implements BudgetRepository {}

class FakeTransactionEntity extends Fake implements TransactionEntity {}

void main() {
  late AddTransactionUseCase useCase;
  late MockTransactionRepository mockRepo;
  late MockBudgetRepository mockBudget;

  setUpAll(() {
    registerFallbackValue(FakeTransactionEntity());
  });

  setUp(() {
    mockRepo = MockTransactionRepository();
    mockBudget = MockBudgetRepository();
    useCase = AddTransactionUseCase(mockRepo, mockBudget);
    when(
      () => mockRepo.addTransaction(any()),
    ).thenAnswer((_) async => const Right(null));
  });

  /// `fixedExpenses` adalah getter — jumlah 5 breakdown. Ditaruh seluruhnya
  /// di `rentExpense` supaya nilai totalnya jelas dari pemanggilan test.
  BudgetSettingsEntity settings({required int fixedExpenses}) =>
      BudgetSettingsEntity(
        monthlyIncome: 3000000,
        paymentDate: 25,
        emergencyFundPct: 0.10,
        createdAt: DateTime(2026, 1, 1),
        rentExpense: fixedExpenses,
      );

  TransactionEntity txn({required bool isFixed, String category = 'fixed'}) =>
      TransactionEntity(
        id: 'tx-1',
        amount: 150000,
        category: category,
        type: TransactionType.expense,
        date: DateTime(2026, 8, 5),
        isFixed: isFixed,
        isSynced: false,
        createdAt: DateTime(2026, 8, 5),
        updatedAt: DateTime(2026, 8, 5),
      );

  TransactionEntity captured() {
    final c = verify(() => mockRepo.addTransaction(captureAny())).captured;
    return c.first as TransactionEntity;
  }

  test('meneruskan ke repository dan mengembalikan Right(null)', () async {
    when(
      () => mockBudget.getBudgetSettings(),
    ).thenAnswer((_) async => Right(settings(fixedExpenses: 800000)));

    final result = await useCase(txn(isFixed: false));

    expect(result, const Right<dynamic, void>(null));
    expect(captured().amount, 150000);
  });

  group('Invariant M1 — isFixed=true hanya sah bila ada potongan di muka', () {
    test(
      '(a) fixedExpenses == 0 + isFixed=true → repository terima false',
      () async {
        when(
          () => mockBudget.getBudgetSettings(),
        ).thenAnswer((_) async => Right(settings(fixedExpenses: 0)));

        await useCase(txn(isFixed: true));

        expect(captured().isFixed, isFalse);
      },
    );

    test(
      '(b) fixedExpenses > 0 + isFixed=true → repository terima true',
      () async {
        when(
          () => mockBudget.getBudgetSettings(),
        ).thenAnswer((_) async => Right(settings(fixedExpenses: 800000)));

        await useCase(txn(isFixed: true));

        expect(captured().isFixed, isTrue);
      },
    );

    test(
      '(c) isFixed=false + fixedExpenses > 0 → tetap false. MONOTON MENURUN: '
      'opt-out pengguna di sheet bayar tagihan tak pernah ditimpa jadi true',
      () async {
        when(
          () => mockBudget.getBudgetSettings(),
        ).thenAnswer((_) async => Right(settings(fixedExpenses: 800000)));

        await useCase(txn(isFixed: false));

        expect(captured().isFixed, isFalse);
      },
    );

    test(
      '(d) getBudgetSettings() Left → diperlakukan fixedExpenses = 0. '
      'budget_repository_impl.dart:36 mengembalikan Left saat baris settings '
      'belum ada, dan "belum diisi" secara semantik MEMANG fixedExpenses == 0',
      () async {
        when(() => mockBudget.getBudgetSettings()).thenAnswer(
          (_) async =>
              const Left(CacheFailure('Pengaturan anggaran belum diisi.')),
        );

        await useCase(txn(isFixed: true));

        expect(captured().isFixed, isFalse);
      },
    );

    test('(e) isFixed=false → anggaran TIDAK ditanya sama sekali. Gerbang ini '
        'monoton menurun, jadi jawabannya tak pernah bisa mengubah apa pun; '
        'menanyakannya cuma menambah satu baca Drift di jalur terpanas aplikasi '
        '(catat pengeluaran harian). Sekaligus mengunci bahwa gerbang mustahil '
        'MENYALAKAN isFixed', () async {
      await useCase(txn(isFixed: false));

      verifyNever(() => mockBudget.getBudgetSettings());
      expect(captured().isFixed, isFalse);
    });
  });
}
