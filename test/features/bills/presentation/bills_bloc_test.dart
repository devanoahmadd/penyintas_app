import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/bills/data/datasources/bill_reminder_scheduler.dart';
import 'package:penyintas_app/features/bills/data/datasources/bill_reminder_settings_datasource.dart';
import 'package:penyintas_app/features/bills/data/models/bill_model.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/domain/usecases/create_bill_usecase.dart';
import 'package:penyintas_app/features/bills/domain/usecases/delete_bill_usecase.dart';
import 'package:penyintas_app/features/bills/domain/usecases/update_bill_usecase.dart';
import 'package:penyintas_app/features/bills/domain/repositories/bill_repository.dart';
import 'package:penyintas_app/features/bills/domain/usecases/watch_active_bills_usecase.dart';
import 'package:penyintas_app/features/bills/presentation/bloc/bills_bloc.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';
import 'package:penyintas_app/features/budget/domain/repositories/budget_repository.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/add_transaction_usecase.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/delete_transaction_usecase.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class MockWatchActiveBillsUseCase extends Mock
    implements WatchActiveBillsUseCase {}

class MockCreateBillUseCase extends Mock implements CreateBillUseCase {}

class MockUpdateBillUseCase extends Mock implements UpdateBillUseCase {}

class MockDeleteBillUseCase extends Mock implements DeleteBillUseCase {}

class MockBillRepository extends Mock implements BillRepository {}

class MockAddTransactionUseCase extends Mock implements AddTransactionUseCase {}

class MockDeleteTransactionUseCase extends Mock
    implements DeleteTransactionUseCase {}

class MockBillReminderScheduler extends Mock implements BillReminderScheduler {}

class MockBillReminderSettingsDatasource extends Mock
    implements BillReminderSettingsDatasource {}

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockBudgetRepository extends Mock implements BudgetRepository {}

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

UndoSnapshot _snapshotUndo({String? txId}) => UndoSnapshot(
  billId: 7,
  dueDate: DateTime(2026, 6, 25),
  installmentsPaid: 0,
  status: BillStatus.active,
  txId: txId,
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
  late MockDeleteTransactionUseCase mockDeleteTransaction;
  late MockBillReminderScheduler mockScheduler;
  late MockBillReminderSettingsDatasource mockReminderSettings;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(FakeBillModel());
    registerFallbackValue(FakeTransactionEntity());
    registerFallbackValue(BillStatus.active);
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(<BillEntity>[]);
  });

  setUp(() {
    mockWatchActiveBills = MockWatchActiveBillsUseCase();
    mockCreateBill = MockCreateBillUseCase();
    mockUpdateBill = MockUpdateBillUseCase();
    mockDeleteBill = MockDeleteBillUseCase();
    mockBillRepository = MockBillRepository();
    mockAddTransaction = MockAddTransactionUseCase();
    mockDeleteTransaction = MockDeleteTransactionUseCase();
    mockScheduler = MockBillReminderScheduler();
    mockReminderSettings = MockBillReminderSettingsDatasource();

    // Default: stream aktif kosong (dipakai `_reschedule` internal BillsBloc
    // utk ambil snapshot bill aktif TERKINI pasca mutasi) + setting default
    // (1, 9). Test grup 'Reschedule pengingat' meng-override sesuai kasus.
    when(
      () => mockWatchActiveBills(any()),
    ).thenAnswer((_) => Stream.value(const Right(<BillEntity>[])));
    when(
      () => mockReminderSettings.read(),
    ).thenAnswer((_) async => (daysBefore: 1, hour: 9));
    when(
      () => mockScheduler.rescheduleAll(
        any(),
        globalDaysBefore: any(named: 'globalDaysBefore'),
        globalHour: any(named: 'globalHour'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockScheduler.cancelFor(any())).thenAnswer((_) async {});
  });

  BillsBloc buildBloc() => BillsBloc(
    watchActiveBills: mockWatchActiveBills,
    createBill: mockCreateBill,
    updateBill: mockUpdateBill,
    deleteBill: mockDeleteBill,
    billRepository: mockBillRepository,
    addTransaction: mockAddTransaction,
    deleteTransaction: mockDeleteTransaction,
    reminderScheduler: mockScheduler,
    reminderSettings: mockReminderSettings,
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
        final captured =
            verify(() => mockAddTransaction(captureAny())).captured.single
                as TransactionEntity;
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
        final captured =
            verify(() => mockAddTransaction(captureAny())).captured.single
                as TransactionEntity;
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

    // Fold-in (Minor 3.2 #3): transaksi gagal → abort SEBELUM advance.
    blocTest<BillsBloc, BillsState>(
      'transaksi gagal (non-opt-out) → applyBillPayment TIDAK dipanggil + failure',
      build: buildBloc,
      setUp: () {
        when(
          () => mockBillRepository.getBillById(any()),
        ).thenAnswer((_) async => Right(_makeBill(id: 7)));
        when(
          () => mockAddTransaction(any()),
        ).thenAnswer((_) async => const Left(CacheFailure('boom')));
      },
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
            .having(
              (s) => s.actionFailure?.aksi,
              'aksi',
              BillWriteAction.markPaid,
            )
            .having((s) => s.status, 'status', isNot(BillsStatus.failure)),
      ],
      verify: (_) {
        verifyNever(
          () => mockBillRepository.applyBillPayment(
            id: any(named: 'id'),
            newDueDate: any(named: 'newDueDate'),
            newInstallmentsPaid: any(named: 'newInstallmentsPaid'),
            newStatus: any(named: 'newStatus'),
          ),
        );
      },
    );
  });

  group('BillPaymentUndone', () {
    void stubRestore() {
      when(
        () => mockBillRepository.restoreBillPayment(
          id: any(named: 'id'),
          dueDate: any(named: 'dueDate'),
          installmentsPaid: any(named: 'installmentsPaid'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async => const Right(null));
    }

    blocTest<BillsBloc, BillsState>(
      'undo bulanan: restore PERSIS nilai snapshot (anchor 31 Jan) + hapus '
      'transaksi + clear lastUndo',
      build: buildBloc,
      seed: () => BillsState(
        status: BillsStatus.success,
        lastUndo: UndoSnapshot(
          billId: 1,
          dueDate: DateTime(2026, 1, 31),
          installmentsPaid: 0,
          status: BillStatus.active,
          txId: 'tx-1',
        ),
      ),
      setUp: () {
        stubRestore();
        when(
          () => mockDeleteTransaction(any()),
        ).thenAnswer((_) async => const Right(null));
      },
      act: (bloc) => bloc.add(
        BillPaymentUndone(
          UndoSnapshot(
            billId: 1,
            dueDate: DateTime(2026, 1, 31),
            installmentsPaid: 0,
            status: BillStatus.active,
            txId: 'tx-1',
          ),
        ),
      ),
      expect: () => [
        isA<BillsState>()
            .having((s) => s.status, 'status', BillsStatus.success)
            .having((s) => s.lastUndo, 'lastUndo cleared', isNull),
      ],
      verify: (_) {
        // dueDate EKSAK = snapshot (bukan hitung mundur — anchor 31 Jan utuh).
        verify(
          () => mockBillRepository.restoreBillPayment(
            id: 1,
            dueDate: DateTime(2026, 1, 31),
            installmentsPaid: 0,
            status: BillStatus.active,
          ),
        ).called(1);
        verify(() => mockDeleteTransaction('tx-1')).called(1);
        // Reschedule (Task 6.2): bill kembali aktif → rescheduleAll,
        // TIDAK cancelFor (bill tsb tak dihapus/completed).
        verify(
          () => mockScheduler.rescheduleAll(
            any(),
            globalDaysBefore: any(named: 'globalDaysBefore'),
            globalHour: any(named: 'globalHour'),
          ),
        ).called(1);
        verifyNever(() => mockScheduler.cancelFor(any()));
      },
    );

    blocTest<BillsBloc, BillsState>(
      'undo angsuran terakhir (completed→active): restore status active dari '
      'snapshot (bukan recompute)',
      build: buildBloc,
      setUp: () {
        stubRestore();
        when(
          () => mockDeleteTransaction(any()),
        ).thenAnswer((_) async => const Right(null));
      },
      act: (bloc) => bloc.add(
        BillPaymentUndone(
          UndoSnapshot(
            billId: 2,
            dueDate: DateTime(2026, 3, 10),
            installmentsPaid: 2,
            status: BillStatus.active,
            txId: 'tx-9',
          ),
        ),
      ),
      verify: (_) {
        verify(
          () => mockBillRepository.restoreBillPayment(
            id: 2,
            dueDate: DateTime(2026, 3, 10),
            installmentsPaid: 2,
            status: BillStatus.active,
          ),
        ).called(1);
      },
    );

    blocTest<BillsBloc, BillsState>(
      'undo opt-out (txId null): restore dipanggil, deleteTransaction TIDAK',
      build: buildBloc,
      setUp: stubRestore,
      act: (bloc) => bloc.add(
        BillPaymentUndone(
          UndoSnapshot(
            billId: 3,
            dueDate: DateTime(2026, 8, 5),
            installmentsPaid: 0,
            status: BillStatus.active,
          ),
        ),
      ),
      verify: (_) {
        verify(
          () => mockBillRepository.restoreBillPayment(
            id: 3,
            dueDate: DateTime(2026, 8, 5),
            installmentsPaid: 0,
            status: BillStatus.active,
          ),
        ).called(1);
        verifyNever(() => mockDeleteTransaction(any()));
      },
    );
  });

  group('Reschedule pengingat (Task 6.2)', () {
    blocTest<BillsBloc, BillsState>(
      'BillAdded sukses → rescheduleAll dipanggil dgn setting terkini (1, 9)',
      build: buildBloc,
      setUp: () {
        when(
          () => mockCreateBill(any()),
        ).thenAnswer((_) async => const Right(1));
      },
      act: (bloc) => bloc.add(BillAdded(_makeBillModel())),
      verify: (_) {
        verify(
          () => mockScheduler.rescheduleAll(
            any(),
            globalDaysBefore: 1,
            globalHour: 9,
          ),
        ).called(1);
      },
    );

    blocTest<BillsBloc, BillsState>(
      'BillAdded gagal → rescheduleAll TIDAK dipanggil',
      build: buildBloc,
      setUp: () {
        when(
          () => mockCreateBill(any()),
        ).thenAnswer((_) async => const Left(CacheFailure('boom')));
      },
      act: (bloc) => bloc.add(BillAdded(_makeBillModel())),
      verify: (_) {
        verifyNever(
          () => mockScheduler.rescheduleAll(
            any(),
            globalDaysBefore: any(named: 'globalDaysBefore'),
            globalHour: any(named: 'globalHour'),
          ),
        );
      },
    );

    blocTest<BillsBloc, BillsState>(
      'BillUpdated sukses → rescheduleAll dipanggil',
      build: buildBloc,
      setUp: () {
        when(
          () => mockUpdateBill(any()),
        ).thenAnswer((_) async => const Right(null));
      },
      act: (bloc) => bloc.add(BillUpdated(_makeBillModel())),
      verify: (_) {
        verify(
          () => mockScheduler.rescheduleAll(
            any(),
            globalDaysBefore: any(named: 'globalDaysBefore'),
            globalHour: any(named: 'globalHour'),
          ),
        ).called(1);
      },
    );

    blocTest<BillsBloc, BillsState>(
      '(c) BillDeleted sukses → cancelFor(id) EKSPLISIT (F3, notif tak yatim)',
      build: buildBloc,
      setUp: () {
        when(
          () => mockDeleteBill(any()),
        ).thenAnswer((_) async => const Right(null));
      },
      act: (bloc) => bloc.add(const BillDeleted(5)),
      verify: (_) {
        verify(() => mockScheduler.cancelFor(5)).called(1);
      },
    );

    blocTest<BillsBloc, BillsState>(
      'BillDeleted gagal → cancelFor TIDAK dipanggil',
      build: buildBloc,
      setUp: () {
        when(
          () => mockDeleteBill(any()),
        ).thenAnswer((_) async => const Left(CacheFailure('boom')));
      },
      act: (bloc) => bloc.add(const BillDeleted(5)),
      verify: (_) {
        verifyNever(() => mockScheduler.cancelFor(any()));
      },
    );

    blocTest<BillsBloc, BillsState>(
      '(d) BillMarkedPaid → completed (tenor habis) → cancelFor(billId) '
      'EKSPLISIT (F3, simetris dgn delete)',
      build: buildBloc,
      setUp: () {
        when(() => mockBillRepository.getBillById(any())).thenAnswer(
          (_) async => Right(
            _makeBill(
              id: 7,
              recurrence: Recurrence.monthly,
              dueDayOfMonth: 25,
              installmentTotal: 3,
              installmentsPaid: 2,
              dueDate: DateTime(2026, 7, 25),
            ),
          ),
        );
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
      },
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
        verify(() => mockScheduler.cancelFor(7)).called(1);
        // rescheduleAll TETAP dipanggil (bill lain di daftar aktif tetap
        // harus ter-refresh; scheduler-nya sendiri idempoten).
        verify(
          () => mockScheduler.rescheduleAll(
            any(),
            globalDaysBefore: any(named: 'globalDaysBefore'),
            globalHour: any(named: 'globalHour'),
          ),
        ).called(1);
      },
    );

    blocTest<BillsBloc, BillsState>(
      'BillMarkedPaid → masih active → cancelFor TIDAK dipanggil, '
      'rescheduleAll TETAP dipanggil',
      build: buildBloc,
      setUp: () {
        when(() => mockBillRepository.getBillById(any())).thenAnswer(
          (_) async => Right(
            _makeBill(
              id: 7,
              recurrence: Recurrence.monthly,
              dueDayOfMonth: 25,
              installmentsPaid: 0,
              dueDate: DateTime(2026, 7, 25),
            ),
          ),
        );
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
      },
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
        verifyNever(() => mockScheduler.cancelFor(any()));
        verify(
          () => mockScheduler.rescheduleAll(
            any(),
            globalDaysBefore: any(named: 'globalDaysBefore'),
            globalHour: any(named: 'globalHour'),
          ),
        ).called(1);
      },
    );

    blocTest<BillsBloc, BillsState>(
      'BillPaymentUndone sukses → rescheduleAll dipanggil (bill kembali '
      'aktif), cancelFor TIDAK dipanggil',
      build: buildBloc,
      setUp: () {
        when(
          () => mockBillRepository.restoreBillPayment(
            id: any(named: 'id'),
            dueDate: any(named: 'dueDate'),
            installmentsPaid: any(named: 'installmentsPaid'),
            status: any(named: 'status'),
          ),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockDeleteTransaction(any()),
        ).thenAnswer((_) async => const Right(null));
      },
      act: (bloc) => bloc.add(
        BillPaymentUndone(
          UndoSnapshot(
            billId: 2,
            dueDate: DateTime(2026, 3, 10),
            installmentsPaid: 2,
            status: BillStatus.active,
            txId: 'tx-9',
          ),
        ),
      ),
      verify: (_) {
        verify(
          () => mockScheduler.rescheduleAll(
            any(),
            globalDaysBefore: any(named: 'globalDaysBefore'),
            globalHour: any(named: 'globalHour'),
          ),
        ).called(1);
        verifyNever(() => mockScheduler.cancelFor(any()));
      },
    );
  });

  // ── (f) INTEGRASI: gerbang M1 di jalur tagihan, usecase ASLI ───────────
  //
  // Semua test lain di file ini memakai `MockAddTransactionUseCase`, jadi
  // gerbang M1 di dalam usecase tidak pernah dieksekusi. Grup ini merangkai
  // AddTransactionUseCase yang SEBENARNYA supaya kontrak "isFixed dimatikan
  // saat tak ada potongan di muka" terkunci ujung-ke-ujung — bukan hanya di
  // unit test usecase yang tak menyentuh BillsBloc.
  group('(f) gerbang M1 berlaku lewat BillsBloc (usecase asli)', () {
    late MockTransactionRepository mockTxRepo;
    late MockBudgetRepository mockBudget;

    final tBill = _makeBill();

    setUp(() {
      mockTxRepo = MockTransactionRepository();
      mockBudget = MockBudgetRepository();
      when(
        () => mockTxRepo.addTransaction(any()),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockBillRepository.getBillById(any()),
      ).thenAnswer((_) async => Right(tBill));
      when(
        () => mockBillRepository.applyBillPayment(
          id: any(named: 'id'),
          newDueDate: any(named: 'newDueDate'),
          newInstallmentsPaid: any(named: 'newInstallmentsPaid'),
          newStatus: any(named: 'newStatus'),
        ),
      ).thenAnswer((_) async => const Right(null));
    });

    BillsBloc buildBlocWithRealUsecase() => BillsBloc(
      watchActiveBills: mockWatchActiveBills,
      createBill: mockCreateBill,
      updateBill: mockUpdateBill,
      deleteBill: mockDeleteBill,
      billRepository: mockBillRepository,
      addTransaction: AddTransactionUseCase(mockTxRepo, mockBudget),
      deleteTransaction: mockDeleteTransaction,
      reminderScheduler: mockScheduler,
      reminderSettings: mockReminderSettings,
    );

    blocTest<BillsBloc, BillsState>(
      'includeAsFixed=true tapi fixedExpenses==0 → transaksi tersimpan '
      'isFixed=false (tanpa gerbang ini, 800rb lenyap dari totalSpentThisMonth '
      'padahal tak ada potongan di muka yang mewakilinya)',
      build: buildBlocWithRealUsecase,
      setUp: () {
        when(() => mockBudget.getBudgetSettings()).thenAnswer(
          (_) async => Right(
            BudgetSettingsEntity(
              monthlyIncome: 3000000,
              paymentDate: 25,
              emergencyFundPct: 0.10,
              createdAt: DateTime(2026, 1, 1),
              // fixedExpenses = 0 → semua breakdown nol (default)
            ),
          ),
        );
      },
      act: (bloc) => bloc.add(
        BillMarkedPaid(
          billId: tBill.id,
          actualAmount: 800000,
          paidDate: DateTime(2026, 8, 5),
          includeAsFixed: true,
          optOutTransaction: false, // WAJIB false — kalau true, tak ada
          // transaksi yang dibuat dan test ini tak menguji apa pun
        ),
      ),
      verify: (_) {
        final captured = verify(
          () => mockTxRepo.addTransaction(captureAny()),
        ).captured;
        final entity = captured.first as TransactionEntity;
        expect(entity.isFixed, isFalse);
      },
    );

    group('tabel kebenaran isFixed — jalur BillMarkedPaid', () {
      // Oracle ditulis LITERAL, diturunkan dari spec §6.1.
      // DILARANG memanggil coveredUpfront() di sini: oracle yang memakai fungsi
      // produksi membandingkan fungsi dengan dirinya sendiri dan tetap hijau
      // walau aturannya salah.
      for (final isFixedNeed in [true, false]) {
        for (final recurrence in Recurrence.values) {
          for (final fixedExpenses in [0, 500000]) {
            for (final includeAsFixed in [true, false]) {
              final expected =
                  includeAsFixed &&
                  isFixedNeed &&
                  recurrence == Recurrence.monthly &&
                  fixedExpenses > 0;

              blocTest<BillsBloc, BillsState>(
                'isFixedNeed=$isFixedNeed recurrence=${recurrence.name} '
                'fixedExpenses=$fixedExpenses includeAsFixed=$includeAsFixed '
                '→ isFixed=$expected',
                build: buildBlocWithRealUsecase,
                setUp: () {
                  when(() => mockBillRepository.getBillById(any())).thenAnswer(
                    (_) async => Right(
                      tBill.copyWith(
                        isFixedNeed: isFixedNeed,
                        recurrence: recurrence,
                      ),
                    ),
                  );
                  when(() => mockBudget.getBudgetSettings()).thenAnswer(
                    (_) async => Right(
                      BudgetSettingsEntity(
                        monthlyIncome: 3000000,
                        paymentDate: 25,
                        emergencyFundPct: 0.10,
                        // fixedExpenses adalah getter = jumlah breakdown.
                        rentExpense: fixedExpenses,
                        createdAt: DateTime(2026, 1, 1),
                      ),
                    ),
                  );
                },
                act: (bloc) => bloc.add(
                  BillMarkedPaid(
                    billId: tBill.id,
                    actualAmount: 800000,
                    paidDate: DateTime(2026, 8, 5),
                    includeAsFixed: includeAsFixed,
                    // WAJIB false. Kalau true, tak ada transaksi yang dibuat dan
                    // test ini tak menguji apa pun.
                    optOutTransaction: false,
                  ),
                ),
                verify: (_) {
                  final captured = verify(
                    () => mockTxRepo.addTransaction(captureAny()),
                  ).captured;
                  final entity = captured.first as TransactionEntity;
                  expect(entity.isFixed, expected);
                },
              );
            }
          }
        }
      }
    });
  });

  group('BillsState — kanal galat tulis (§2.3)', () {
    const galat = BillActionFailure(
      aksi: BillWriteAction.delete,
      failure: CacheFailure('db mati'),
      seq: 1,
      billId: 7,
    );

    test('copyWith membawa actionFailure', () {
      const awal = BillsState(status: BillsStatus.success);
      expect(awal.copyWith(actionFailure: galat).actionFailure, galat);
    });

    test('copyWith TANPA argumen mempertahankan actionFailure', () {
      const s = BillsState(status: BillsStatus.success, actionFailure: galat);
      expect(s.copyWith(bills: const []).actionFailure, galat);
    });

    test('clearActionFailure mengosongkannya', () {
      const s = BillsState(status: BillsStatus.success, actionFailure: galat);
      expect(s.copyWith(clearActionFailure: true).actionFailure, isNull);
    });

    test('actionFailure ikut props — dua state beda galat TIDAK sama', () {
      const a = BillsState(actionFailure: galat);
      const b = BillsState(
        actionFailure: BillActionFailure(
          aksi: BillWriteAction.delete,
          failure: CacheFailure('db mati'),
          seq: 2,
          billId: 7,
        ),
      );
      expect(
        a,
        isNot(b),
        reason:
            'seq WAJIB masuk props — tanpa itu kegagalan '
            'kedua yang identik tak pernah terlihat konsumen',
      );
    });

    test('clearActionFailure TIDAK menyentuh kanal muat', () {
      const s = BillsState(
        status: BillsStatus.failure,
        failure: CacheFailure('gagal muat'),
        actionFailure: galat,
      );
      final hasil = s.copyWith(clearActionFailure: true);
      expect(hasil.failure, isNotNull);
      expect(hasil.status, BillsStatus.failure);
    });
  });

  group('kanal galat tulis — sembilan titik (§2.4)', () {
    /// Matcher bersama: kegagalan tulis WAJIB muncul di `actionFailure` dengan
    /// `Failure` PERSIS yang diharapkan (bukan cuma `aksi`/`billId` — dua
    /// titik dengan `Failure` berbeda yang tertukar HARUS terlihat), dan
    /// kanal muat (`status` + `failure`) WAJIB tetap bersih.
    Matcher gagalTulis(BillWriteAction aksi, Failure failure, {int? billId}) =>
        isA<BillsState>()
            .having((s) => s.actionFailure?.aksi, 'aksi', aksi)
            .having((s) => s.actionFailure?.billId, 'billId', billId)
            .having((s) => s.actionFailure?.failure, 'failure asli', failure)
            .having((s) => s.status, 'status', BillsStatus.success)
            .having((s) => s.failure, 'failure', isNull);

    const seedSukses = BillsState(status: BillsStatus.success);

    blocTest<BillsBloc, BillsState>(
      'titik 1 — createBill gagal',
      build: buildBloc,
      seed: () => seedSukses,
      setUp: () => when(
        () => mockCreateBill(any()),
      ).thenAnswer((_) async => const Left(CacheFailure('db mati'))),
      act: (bloc) => bloc.add(BillAdded(_makeBillModel())),
      expect: () => [
        gagalTulis(BillWriteAction.add, const CacheFailure('db mati')),
      ],
    );

    blocTest<BillsBloc, BillsState>(
      'titik 2 — updateBill gagal',
      build: buildBloc,
      seed: () => seedSukses,
      setUp: () => when(
        () => mockUpdateBill(any()),
      ).thenAnswer((_) async => const Left(CacheFailure('db mati'))),
      act: (bloc) => bloc.add(BillUpdated(_makeBillModel())),
      expect: () => [
        gagalTulis(BillWriteAction.update, const CacheFailure('db mati')),
      ],
    );

    blocTest<BillsBloc, BillsState>(
      'titik 3 — deleteBill gagal, membawa billId untuk aksi "Coba lagi"',
      build: buildBloc,
      seed: () => seedSukses,
      setUp: () => when(
        () => mockDeleteBill(any()),
      ).thenAnswer((_) async => const Left(CacheFailure('db mati'))),
      act: (bloc) => bloc.add(const BillDeleted(7)),
      expect: () => [
        gagalTulis(
          BillWriteAction.delete,
          const CacheFailure('db mati'),
          billId: 7,
        ),
      ],
    );

    blocTest<BillsBloc, BillsState>(
      'titik 4 — markPaid: getBillById gagal',
      build: buildBloc,
      seed: () => seedSukses,
      setUp: () => when(
        () => mockBillRepository.getBillById(any()),
      ).thenAnswer((_) async => const Left(CacheFailure('db mati'))),
      act: (bloc) => bloc.add(
        BillMarkedPaid(
          billId: 7,
          actualAmount: 800000,
          paidDate: DateTime(2026, 7, 26),
          includeAsFixed: false,
          optOutTransaction: true,
        ),
      ),
      // Failure ASLI dari getBillById (forward), BUKAN pesan buatan handler —
      // pembeda ini sengaja ditulis di kode (lihat komentar :192-193 bloc).
      expect: () => [
        gagalTulis(
          BillWriteAction.markPaid,
          const CacheFailure('db mati'),
          billId: 7,
        ),
      ],
    );

    blocTest<BillsBloc, BillsState>(
      'titik 5 — markPaid: bill tak ditemukan',
      build: buildBloc,
      seed: () => seedSukses,
      setUp: () => when(
        () => mockBillRepository.getBillById(any()),
      ).thenAnswer((_) async => const Right(null)),
      act: (bloc) => bloc.add(
        BillMarkedPaid(
          billId: 7,
          actualAmount: 800000,
          paidDate: DateTime(2026, 7, 26),
          includeAsFixed: false,
          optOutTransaction: true,
        ),
      ),
      // Failure DIBUAT SENDIRI oleh handler ('Tagihan tak ditemukan.') — pesan
      // BEDA dari titik 4 ('db mati') supaya tertukar = merah, bukan lolos.
      expect: () => [
        gagalTulis(
          BillWriteAction.markPaid,
          const CacheFailure('Tagihan tak ditemukan.'),
          billId: 7,
        ),
      ],
    );

    blocTest<BillsBloc, BillsState>(
      'titik 6 — markPaid: addTransaction gagal',
      build: buildBloc,
      seed: () => seedSukses,
      setUp: () {
        when(() => mockBillRepository.getBillById(any())).thenAnswer(
          (_) async => Right(_makeBill(id: 7, dueDate: DateTime(2026, 7, 25))),
        );
        when(
          () => mockAddTransaction(any()),
        ).thenAnswer((_) async => const Left(CacheFailure('tx gagal')));
      },
      act: (bloc) => bloc.add(
        BillMarkedPaid(
          billId: 7,
          actualAmount: 800000,
          paidDate: DateTime(2026, 7, 26),
          includeAsFixed: false,
          optOutTransaction: false,
        ),
      ),
      expect: () => [
        gagalTulis(
          BillWriteAction.markPaid,
          const CacheFailure('tx gagal'),
          billId: 7,
        ),
      ],
    );

    blocTest<BillsBloc, BillsState>(
      'titik 7 — markPaid: applyBillPayment gagal',
      build: buildBloc,
      seed: () => seedSukses,
      setUp: () {
        when(() => mockBillRepository.getBillById(any())).thenAnswer(
          (_) async => Right(_makeBill(id: 7, dueDate: DateTime(2026, 7, 25))),
        );
        when(
          () => mockBillRepository.applyBillPayment(
            id: any(named: 'id'),
            newDueDate: any(named: 'newDueDate'),
            newInstallmentsPaid: any(named: 'newInstallmentsPaid'),
            newStatus: any(named: 'newStatus'),
          ),
        ).thenAnswer((_) async => const Left(CacheFailure('apply gagal')));
      },
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
        gagalTulis(
          BillWriteAction.markPaid,
          const CacheFailure('apply gagal'),
          billId: 7,
        ),
      ],
    );

    blocTest<BillsBloc, BillsState>(
      'titik 8 — undo: restoreBillPayment gagal',
      build: buildBloc,
      seed: () => seedSukses,
      setUp: () => when(
        () => mockBillRepository.restoreBillPayment(
          id: any(named: 'id'),
          dueDate: any(named: 'dueDate'),
          installmentsPaid: any(named: 'installmentsPaid'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async => const Left(CacheFailure('restore gagal'))),
      act: (bloc) => bloc.add(BillPaymentUndone(_snapshotUndo())),
      expect: () => [
        gagalTulis(
          BillWriteAction.undoPayment,
          const CacheFailure('restore gagal'),
          billId: 7,
        ),
      ],
    );

    blocTest<BillsBloc, BillsState>(
      'titik 9 — undo: deleteTransaction gagal',
      build: buildBloc,
      seed: () => seedSukses,
      setUp: () {
        when(
          () => mockBillRepository.restoreBillPayment(
            id: any(named: 'id'),
            dueDate: any(named: 'dueDate'),
            installmentsPaid: any(named: 'installmentsPaid'),
            status: any(named: 'status'),
          ),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockDeleteTransaction(any()),
        ).thenAnswer((_) async => const Left(CacheFailure('del tx gagal')));
      },
      act: (bloc) => bloc.add(BillPaymentUndone(_snapshotUndo(txId: 'tx-1'))),
      expect: () => [
        gagalTulis(
          BillWriteAction.undoPayment,
          const CacheFailure('del tx gagal'),
          billId: 7,
        ),
      ],
    );

    blocTest<BillsBloc, BillsState>(
      'seq NAIK di kegagalan kedua yang isinya identik',
      build: buildBloc,
      seed: () => seedSukses,
      setUp: () => when(
        () => mockDeleteBill(any()),
      ).thenAnswer((_) async => const Left(CacheFailure('db mati'))),
      act: (bloc) async {
        bloc.add(const BillDeleted(7));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const BillDeleted(7));
      },
      expect: () => [
        isA<BillsState>().having((s) => s.actionFailure?.seq, 'seq', 1),
        isA<BillsState>().having((s) => s.actionFailure?.seq, 'seq', 2),
      ],
    );

    blocTest<BillsBloc, BillsState>(
      'stream memancar ulang → actionFailure DIBERSIHKAN',
      build: buildBloc,
      seed: () => const BillsState(
        status: BillsStatus.success,
        actionFailure: BillActionFailure(
          aksi: BillWriteAction.delete,
          failure: CacheFailure('db mati'),
          seq: 1,
        ),
      ),
      setUp: () => when(() => mockWatchActiveBills(any())).thenAnswer(
        (_) => Stream<Either<Failure, List<BillEntity>>>.value(
          Right([_makeBill(id: 1)]),
        ),
      ),
      act: (bloc) => bloc.add(const BillsSubscribed()),
      expect: () => [
        isA<BillsState>().having(
          (s) => s.status,
          'status',
          BillsStatus.loading,
        ),
        isA<BillsState>()
            .having((s) => s.actionFailure, 'actionFailure', isNull)
            .having((s) => s.status, 'status', BillsStatus.success),
      ],
    );

    blocTest<BillsBloc, BillsState>(
      'applyBillPayment gagal → transaksi yang TERLANJUR dicatat DIHAPUS',
      build: buildBloc,
      seed: () => seedSukses,
      setUp: () {
        when(() => mockBillRepository.getBillById(any())).thenAnswer(
          (_) async => Right(_makeBill(id: 7, dueDate: DateTime(2026, 7, 25))),
        );
        when(
          () => mockAddTransaction(any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockDeleteTransaction(any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockBillRepository.applyBillPayment(
            id: any(named: 'id'),
            newDueDate: any(named: 'newDueDate'),
            newInstallmentsPaid: any(named: 'newInstallmentsPaid'),
            newStatus: any(named: 'newStatus'),
          ),
        ).thenAnswer((_) async => const Left(CacheFailure('apply gagal')));
      },
      act: (bloc) => bloc.add(
        BillMarkedPaid(
          billId: 7,
          actualAmount: 800000,
          paidDate: DateTime(2026, 7, 26),
          includeAsFixed: false,
          optOutTransaction: false,
        ),
      ),
      expect: () => [
        gagalTulis(
          BillWriteAction.markPaid,
          const CacheFailure('apply gagal'),
          billId: 7,
        ),
      ],
      verify: (_) {
        // Id-nya TIDAK ditebak dari fixture: ia uuid yang dibuat bloc sendiri.
        // Menangkapnya dari `addTransaction` adalah satu-satunya cara jujur
        // membuktikan yang dihapus adalah transaksi yang BARU SAJA ditulis.
        final txDicatat =
            verify(() => mockAddTransaction(captureAny())).captured.single
                as TransactionEntity;
        verify(() => mockDeleteTransaction(txDicatat.id)).called(1);
      },
    );

    blocTest<BillsBloc, BillsState>(
      'opt-out transaksi → applyBillPayment gagal → TIDAK ada yang dihapus',
      build: buildBloc,
      seed: () => seedSukses,
      setUp: () {
        when(() => mockBillRepository.getBillById(any())).thenAnswer(
          (_) async => Right(_makeBill(id: 7, dueDate: DateTime(2026, 7, 25))),
        );
        when(
          () => mockBillRepository.applyBillPayment(
            id: any(named: 'id'),
            newDueDate: any(named: 'newDueDate'),
            newInstallmentsPaid: any(named: 'newInstallmentsPaid'),
            newStatus: any(named: 'newStatus'),
          ),
        ).thenAnswer((_) async => const Left(CacheFailure('apply gagal')));
      },
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
        gagalTulis(
          BillWriteAction.markPaid,
          const CacheFailure('apply gagal'),
          billId: 7,
        ),
      ],
      verify: (_) => verifyNever(() => mockDeleteTransaction(any())),
    );

    blocTest<BillsBloc, BillsState>(
      'kompensasi ITU SENDIRI gagal → galat markPaid tetap yang dilaporkan',
      build: buildBloc,
      seed: () => seedSukses,
      setUp: () {
        when(() => mockBillRepository.getBillById(any())).thenAnswer(
          (_) async => Right(_makeBill(id: 7, dueDate: DateTime(2026, 7, 25))),
        );
        when(
          () => mockAddTransaction(any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockDeleteTransaction(any()),
        ).thenAnswer((_) async => const Left(CacheFailure('del gagal')));
        when(
          () => mockBillRepository.applyBillPayment(
            id: any(named: 'id'),
            newDueDate: any(named: 'newDueDate'),
            newInstallmentsPaid: any(named: 'newInstallmentsPaid'),
            newStatus: any(named: 'newStatus'),
          ),
        ).thenAnswer((_) async => const Left(CacheFailure('apply gagal')));
      },
      act: (bloc) => bloc.add(
        BillMarkedPaid(
          billId: 7,
          actualAmount: 800000,
          paidDate: DateTime(2026, 7, 26),
          includeAsFixed: false,
          optOutTransaction: false,
        ),
      ),
      // SATU state saja, dan isinya galat markPaid dengan Failure ASLI
      // ('apply gagal') — BUKAN galat hapus transaksi ('del gagal').
      // Kompensasi yang gagal tak boleh menyalip ATAU MENGGANTI pesan
      // aslinya: yang perlu diketahui pengguna adalah pembayarannya tak
      // tercatat, bukan detail pembersihan yang gagal.
      expect: () => [
        gagalTulis(
          BillWriteAction.markPaid,
          const CacheFailure('apply gagal'),
          billId: 7,
        ),
      ],
    );

    blocTest<BillsBloc, BillsState>(
      'markPaid sukses → actionFailure lama DIBERSIHKAN',
      build: buildBloc,
      seed: () => const BillsState(
        status: BillsStatus.success,
        actionFailure: BillActionFailure(
          aksi: BillWriteAction.delete,
          failure: CacheFailure('db mati'),
          seq: 1,
          billId: 9,
        ),
      ),
      setUp: () {
        when(() => mockBillRepository.getBillById(any())).thenAnswer(
          (_) async => Right(_makeBill(id: 7, dueDate: DateTime(2026, 7, 25))),
        );
        when(
          () => mockBillRepository.applyBillPayment(
            id: any(named: 'id'),
            newDueDate: any(named: 'newDueDate'),
            newInstallmentsPaid: any(named: 'newInstallmentsPaid'),
            newStatus: any(named: 'newStatus'),
          ),
        ).thenAnswer((_) async => const Right(null));
      },
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
            .having((s) => s.actionFailure, 'actionFailure', isNull),
      ],
    );

    blocTest<BillsBloc, BillsState>(
      'undo sukses → actionFailure lama DIBERSIHKAN',
      build: buildBloc,
      seed: () => const BillsState(
        status: BillsStatus.success,
        actionFailure: BillActionFailure(
          aksi: BillWriteAction.markPaid,
          failure: CacheFailure('apply gagal'),
          seq: 1,
          billId: 7,
        ),
      ),
      setUp: () => when(
        () => mockBillRepository.restoreBillPayment(
          id: any(named: 'id'),
          dueDate: any(named: 'dueDate'),
          installmentsPaid: any(named: 'installmentsPaid'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async => const Right(null)),
      act: (bloc) => bloc.add(BillPaymentUndone(_snapshotUndo())),
      expect: () => [
        isA<BillsState>()
            .having((s) => s.status, 'status', BillsStatus.success)
            .having((s) => s.actionFailure, 'actionFailure', isNull),
      ],
    );
  });
}
