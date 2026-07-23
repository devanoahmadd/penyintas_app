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
import 'package:penyintas_app/features/bills/domain/usecases/watch_active_bills_usecase.dart';
import 'package:penyintas_app/features/bills/presentation/bloc/bills_bloc.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class MockWatchActiveBillsUseCase extends Mock
    implements WatchActiveBillsUseCase {}

class MockCreateBillUseCase extends Mock implements CreateBillUseCase {}

class MockUpdateBillUseCase extends Mock implements UpdateBillUseCase {}

class MockDeleteBillUseCase extends Mock implements DeleteBillUseCase {}

class FakeBillModel extends Fake implements BillModel {}

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

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(FakeBillModel());
  });

  setUp(() {
    mockWatchActiveBills = MockWatchActiveBillsUseCase();
    mockCreateBill = MockCreateBillUseCase();
    mockUpdateBill = MockUpdateBillUseCase();
    mockDeleteBill = MockDeleteBillUseCase();
  });

  BillsBloc buildBloc() => BillsBloc(
    watchActiveBills: mockWatchActiveBills,
    createBill: mockCreateBill,
    updateBill: mockUpdateBill,
    deleteBill: mockDeleteBill,
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
}
