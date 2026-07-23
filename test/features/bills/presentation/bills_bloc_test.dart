import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/bills/data/models/bill_model.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/domain/usecases/create_bill_usecase.dart';
import 'package:penyintas_app/features/bills/domain/usecases/delete_bill_usecase.dart';
import 'package:penyintas_app/features/bills/domain/usecases/update_bill_usecase.dart';
import 'package:penyintas_app/features/bills/domain/repositories/bill_repository.dart';
import 'package:penyintas_app/features/bills/domain/usecases/watch_active_bills_usecase.dart';
import 'package:penyintas_app/features/bills/presentation/bloc/bills_bloc.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/add_transaction_usecase.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class MockWatchActiveBillsUseCase extends Mock
    implements WatchActiveBillsUseCase {}

class MockCreateBillUseCase extends Mock implements CreateBillUseCase {}

class MockUpdateBillUseCase extends Mock implements UpdateBillUseCase {}

class MockDeleteBillUseCase extends Mock implements DeleteBillUseCase {}

class MockBillRepository extends Mock implements BillRepository {}

class MockAddTransactionUseCase extends Mock
    implements AddTransactionUseCase {}

class FakeBillModel extends Fake implements BillModel {}

class FakeTransactionEntity extends Fake implements TransactionEntity {}

// ── Helpers ──────────────────────────────────────────────────────────────────

BillEntity _makeBill({
  int id = 1,
  String? cloudId,
  String name = 'Kos Bu Tini',
  int estimatedAmount = 750000,
  String category = 'housing',
  bool isFixedNeed = true,
  String? notes,
  DateTime? dueDate,
  Recurrence recurrence = Recurrence.monthly,
  int? installmentTotal,
  int installmentsPaid = 0,
  DateTime? recurrenceEndDate,
  int? dueDayOfMonth = 5,
  int? reminderDaysBefore = 3,
  bool reminderEnabled = true,
  BillStatus status = BillStatus.active,
  DateTime? createdAt,
  DateTime? updatedAt,
}) => BillEntity(
  id: id,
  cloudId: cloudId,
  name: name,
  estimatedAmount: estimatedAmount,
  category: category,
  isFixedNeed: isFixedNeed,
  notes: notes,
  dueDate: dueDate ?? DateTime(2026, 8, 5),
  recurrence: recurrence,
  installmentTotal: installmentTotal,
  installmentsPaid: installmentsPaid,
  recurrenceEndDate: recurrenceEndDate,
  dueDayOfMonth: dueDayOfMonth,
  reminderDaysBefore: reminderDaysBefore,
  reminderEnabled: reminderEnabled,
  status: status,
  createdAt: createdAt ?? DateTime(2026, 7, 1),
  updatedAt: updatedAt ?? DateTime(2026, 7, 1),
);

BillModel _makeBillModel({
  String? cloudId,
  String name = 'Kos Bu Tini',
  int estimatedAmount = 750000,
  String category = 'housing',
  bool isFixedNeed = true,
  String? notes,
  DateTime? dueDate,
  Recurrence recurrence = Recurrence.monthly,
  int? installmentTotal,
  int installmentsPaid = 0,
  DateTime? recurrenceEndDate,
  int? dueDayOfMonth = 5,
  int? reminderDaysBefore = 3,
  bool reminderEnabled = true,
  BillStatus status = BillStatus.active,
  DateTime? createdAt,
  DateTime? updatedAt,
}) => BillModel(
  cloudId: cloudId,
  name: name,
  estimatedAmount: estimatedAmount,
  category: category,
  isFixedNeed: isFixedNeed,
  notes: notes,
  dueDate: dueDate ?? DateTime(2026, 8, 5),
  recurrence: recurrence,
  installmentTotal: installmentTotal,
  installmentsPaid: installmentsPaid,
  recurrenceEndDate: recurrenceEndDate,
  dueDayOfMonth: dueDayOfMonth,
  reminderDaysBefore: reminderDaysBefore,
  reminderEnabled: reminderEnabled,
  status: status,
  createdAt: createdAt ?? DateTime(2026, 7, 1),
  updatedAt: updatedAt ?? DateTime(2026, 7, 1),
);

void main() {
  late MockWatchActiveBillsUseCase mockWatchActiveBills;
  late MockCreateBillUseCase mockCreateBill;
  late MockUpdateBillUseCase mockUpdateBill;
  late MockDeleteBillUseCase mockDeleteBill;
  late MockBillRepository mockBillRepository;
  late MockAddTransactionUseCase mockAddTransaction;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(FakeBillModel());
    registerFallbackValue(FakeTransactionEntity());
    registerFallbackValue(BillStatus.active);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    mockWatchActiveBills = MockWatchActiveBillsUseCase();
    mockCreateBill = MockCreateBillUseCase();
    mockUpdateBill = MockUpdateBillUseCase();
    mockDeleteBill = MockDeleteBillUseCase();
    mockBillRepository = MockBillRepository();
    mockAddTransaction = MockAddTransactionUseCase();
  });

  BillsBloc buildBloc() => BillsBloc(
    watchActiveBills: mockWatchActiveBills,
    createBill: mockCreateBill,
    updateBill: mockUpdateBill,
    deleteBill: mockDeleteBill,
    billRepository: mockBillRepository,
    addTransaction: mockAddTransaction,
  );

  group('BillsSubscribed', () {
    final tEntity = _makeBill();

    blocTest<BillsBloc, BillsState>(
      'emits [loading, success] dengan bills terisi saat stream berhasil',
      build: buildBloc,
      setUp: () {
        when(() => mockWatchActiveBills(any())).thenAnswer(
          (_) => Stream.value(Right<Failure, List<BillEntity>>([tEntity])),
        );
      },
      act: (bloc) => bloc.add(const BillsSubscribed()),
      expect: () => [
        isA<BillsState>().having(
          (s) => s.status,
          'status',
          BillsStatus.loading,
        ),
        isA<BillsState>()
            .having((s) => s.status, 'status', BillsStatus.success)
            .having((s) => s.bills, 'bills', [tEntity]),
      ],
    );

    blocTest<BillsBloc, BillsState>(
      'emits [loading, failure] saat stream gagal',
      build: buildBloc,
      setUp: () {
        when(() => mockWatchActiveBills(any())).thenAnswer(
          (_) =>
              Stream.value(const Left(CacheFailure('Gagal memuat tagihan.'))),
        );
      },
      act: (bloc) => bloc.add(const BillsSubscribed()),
      expect: () => [
        isA<BillsState>().having(
          (s) => s.status,
          'status',
          BillsStatus.loading,
        ),
        isA<BillsState>().having(
          (s) => s.status,
          'status',
          BillsStatus.failure,
        ),
      ],
    );
  });

  group('BillAdded', () {
    blocTest<BillsBloc, BillsState>(
      'memanggil createBill usecase',
      build: buildBloc,
      setUp: () {
        when(
          () => mockCreateBill(any()),
        ).thenAnswer((_) async => const Right(1));
      },
      act: (bloc) => bloc.add(BillAdded(_makeBillModel())),
      verify: (_) {
        verify(() => mockCreateBill(any())).called(1);
      },
    );
  });

  group('BillUpdated', () {
    blocTest<BillsBloc, BillsState>(
      'memanggil updateBill usecase',
      build: buildBloc,
      setUp: () {
        when(
          () => mockUpdateBill(any()),
        ).thenAnswer((_) async => const Right(null));
      },
      act: (bloc) => bloc.add(BillUpdated(_makeBillModel())),
      verify: (_) {
        verify(() => mockUpdateBill(any())).called(1);
      },
    );
  });

  group('BillDeleted', () {
    blocTest<BillsBloc, BillsState>(
      'memanggil deleteBill usecase',
      build: buildBloc,
      setUp: () {
        when(
          () => mockDeleteBill(any()),
        ).thenAnswer((_) async => const Right(null));
      },
      act: (bloc) => bloc.add(const BillDeleted(5)),
      verify: (_) {
        verify(() => mockDeleteBill(5)).called(1);
      },
    );
  });

  group('BillMarkedPaid', () {
    // Stub sukses default untuk getBillById + applyBillPayment + addTransaction.
    void stubSuccess(BillEntity bill) {
      when(
        () => mockBillRepository.getBillById(any()),
      ).thenAnswer((_) async => Right(bill));
      when(
        () => mockBillRepository.applyBillPayment(
          id: any(named: 'id'),
          newDueDate: any(named: 'newDueDate'),
          newInstallmentsPaid: any(named: 'newInstallmentsPaid'),
          newStatus: any(named: 'newStatus'),
        ),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockAddTransaction(any()),
      ).thenAnswer((_) async => const Right(null));
    }

    blocTest<BillsBloc, BillsState>(
      'membuat transaksi benar (category/type/amount/isFixed/sourceBillId) '
      'lalu applyBillPayment',
      build: buildBloc,
      setUp: () => stubSuccess(
        _makeBill(
          id: 7,
          category: 'housing',
          recurrence: Recurrence.monthly,
          dueDayOfMonth: 25,
          installmentsPaid: 0,
          dueDate: DateTime(2026, 7, 25),
        ),
      ),
      act: (bloc) => bloc.add(
        BillMarkedPaid(
          billId: 7,
          actualAmount: 800000,
          paidDate: DateTime(2026, 7, 26),
          includeAsFixed: true,
          optOutTransaction: false,
        ),
      ),
      verify: (_) {
        final captured = verify(
          () => mockAddTransaction(captureAny()),
        ).captured.single as TransactionEntity;
        expect(captured.amount, 800000);
        expect(captured.category, 'housing');
        expect(captured.type, TransactionType.expense);
        expect(captured.isFixed, true);
        expect(captured.sourceBillId, 7);
        expect(captured.date, DateTime(2026, 7, 26));
        expect(captured.id, isNotEmpty);
        verify(
          () => mockBillRepository.applyBillPayment(
            id: 7,
            newDueDate: any(named: 'newDueDate'),
            newInstallmentsPaid: any(named: 'newInstallmentsPaid'),
            newStatus: any(named: 'newStatus'),
          ),
        ).called(1);
      },
    );

    blocTest<BillsBloc, BillsState>(
      'opt-out: TIDAK membuat transaksi tetapi applyBillPayment TETAP dipanggil',
      build: buildBloc,
      setUp: () => stubSuccess(
        _makeBill(
          id: 7,
          recurrence: Recurrence.monthly,
          dueDayOfMonth: 25,
          installmentsPaid: 0,
          dueDate: DateTime(2026, 7, 25),
        ),
      ),
      act: (bloc) => bloc.add(
        BillMarkedPaid(
          billId: 7,
          actualAmount: 800000,
          paidDate: DateTime(2026, 7, 26),
          includeAsFixed: false,
          optOutTransaction: true,
        ),
      ),
      verify: (_) {
        verifyNever(() => mockAddTransaction(any()));
        verify(
          () => mockBillRepository.applyBillPayment(
            id: 7,
            newDueDate: any(named: 'newDueDate'),
            newInstallmentsPaid: any(named: 'newInstallmentsPaid'),
            newStatus: any(named: 'newStatus'),
          ),
        ).called(1);
      },
    );

    blocTest<BillsBloc, BillsState>(
      'tenor habis: applyBillPayment dipanggil dengan newStatus completed',
      build: buildBloc,
      setUp: () => stubSuccess(
        _makeBill(
          id: 7,
          recurrence: Recurrence.monthly,
          dueDayOfMonth: 25,
          installmentTotal: 3,
          installmentsPaid: 2,
          dueDate: DateTime(2026, 7, 25),
        ),
      ),
      act: (bloc) => bloc.add(
        BillMarkedPaid(
          billId: 7,
          actualAmount: 800000,
          paidDate: DateTime(2026, 7, 26),
          includeAsFixed: true,
          optOutTransaction: false,
        ),
      ),
      verify: (_) {
        verify(
          () => mockBillRepository.applyBillPayment(
            id: 7,
            newDueDate: any(named: 'newDueDate'),
            newInstallmentsPaid: 3,
            newStatus: BillStatus.completed,
          ),
        ).called(1);
      },
    );

    blocTest<BillsBloc, BillsState>(
      'decoupling §4.2: category=internet + includeAsFixed=true => transaksi '
      'isFixed=true & category=internet (invariant isFixed≡fixed diputus)',
      build: buildBloc,
      setUp: () => stubSuccess(
        _makeBill(
          id: 7,
          category: 'internet',
          recurrence: Recurrence.monthly,
          dueDayOfMonth: 25,
          installmentsPaid: 0,
          dueDate: DateTime(2026, 7, 25),
        ),
      ),
      act: (bloc) => bloc.add(
        BillMarkedPaid(
          billId: 7,
          actualAmount: 300000,
          paidDate: DateTime(2026, 7, 26),
          includeAsFixed: true,
          optOutTransaction: false,
        ),
      ),
      verify: (_) {
        final captured = verify(
          () => mockAddTransaction(captureAny()),
        ).captured.single as TransactionEntity;
        expect(captured.isFixed, true);
        expect(captured.category, 'internet');
      },
    );

    blocTest<BillsBloc, BillsState>(
      'UndoSnapshot = state SEBELUM payment + txId non-null (non-opt-out)',
      build: buildBloc,
      setUp: () => stubSuccess(
        _makeBill(
          id: 7,
          recurrence: Recurrence.monthly,
          dueDayOfMonth: 25,
          installmentsPaid: 1,
          dueDate: DateTime(2026, 7, 25),
          status: BillStatus.active,
        ),
      ),
      act: (bloc) => bloc.add(
        BillMarkedPaid(
          billId: 7,
          actualAmount: 800000,
          paidDate: DateTime(2026, 7, 26),
          includeAsFixed: true,
          optOutTransaction: false,
        ),
      ),
      expect: () => [
        isA<BillsState>()
            .having((s) => s.status, 'status', BillsStatus.success)
            .having((s) => s.lastUndo?.billId, 'undo.billId', 7)
            .having(
              (s) => s.lastUndo?.dueDate,
              'undo.dueDate (lama)',
              DateTime(2026, 7, 25),
            )
            .having(
              (s) => s.lastUndo?.installmentsPaid,
              'undo.installmentsPaid (lama)',
              1,
            )
            .having(
              (s) => s.lastUndo?.status,
              'undo.status (lama)',
              BillStatus.active,
            )
            .having((s) => s.lastUndo?.txId, 'undo.txId', isNotNull),
      ],
    );

    blocTest<BillsBloc, BillsState>(
      'UndoSnapshot txId null saat opt-out',
      build: buildBloc,
      setUp: () => stubSuccess(
        _makeBill(
          id: 7,
          recurrence: Recurrence.monthly,
          dueDayOfMonth: 25,
          installmentsPaid: 0,
          dueDate: DateTime(2026, 7, 25),
        ),
      ),
      act: (bloc) => bloc.add(
        BillMarkedPaid(
          billId: 7,
          actualAmount: 800000,
          paidDate: DateTime(2026, 7, 26),
          includeAsFixed: false,
          optOutTransaction: true,
        ),
      ),
      expect: () => [
        isA<BillsState>()
            .having((s) => s.status, 'status', BillsStatus.success)
            .having((s) => s.lastUndo?.txId, 'undo.txId', isNull),
      ],
    );
  });
}
