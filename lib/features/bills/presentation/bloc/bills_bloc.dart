import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/bills/data/models/bill_model.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/domain/repositories/bill_repository.dart';
import 'package:penyintas_app/features/bills/domain/usecases/create_bill_usecase.dart';
import 'package:penyintas_app/features/bills/domain/usecases/delete_bill_usecase.dart';
import 'package:penyintas_app/features/bills/domain/usecases/mark_bill_paid_usecase.dart';
import 'package:penyintas_app/features/bills/domain/usecases/update_bill_usecase.dart';
import 'package:penyintas_app/features/bills/domain/usecases/watch_active_bills_usecase.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/add_transaction_usecase.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/delete_transaction_usecase.dart';
import 'package:uuid/uuid.dart';

part 'bills_event.dart';
part 'bills_state.dart';

class BillsBloc extends Bloc<BillsEvent, BillsState> {
  BillsBloc({
    required WatchActiveBillsUseCase watchActiveBills,
    required CreateBillUseCase createBill,
    required UpdateBillUseCase updateBill,
    required DeleteBillUseCase deleteBill,
    required BillRepository billRepository,
    required AddTransactionUseCase addTransaction,
    required DeleteTransactionUseCase deleteTransaction,
  }) : _watchActiveBills = watchActiveBills,
       _createBill = createBill,
       _updateBill = updateBill,
       _deleteBill = deleteBill,
       _billRepository = billRepository,
       _addTransaction = addTransaction,
       _deleteTransaction = deleteTransaction,
       super(const BillsState()) {
    on<BillsSubscribed>(_onSubscribed, transformer: restartable());
    on<BillAdded>(_onAdded);
    on<BillUpdated>(_onUpdated);
    on<BillDeleted>(_onDeleted);
    on<BillMarkedPaid>(_onMarkedPaid);
    on<BillPaymentUndone>(_onPaymentUndone);
  }

  final WatchActiveBillsUseCase _watchActiveBills;
  final CreateBillUseCase _createBill;
  final UpdateBillUseCase _updateBill;
  final DeleteBillUseCase _deleteBill;
  final BillRepository _billRepository;
  final AddTransactionUseCase _addTransaction;
  final DeleteTransactionUseCase _deleteTransaction;

  static const _uuid = Uuid();

  static void _log(Object e, StackTrace s) {
    try {
      FirebaseCrashlytics.instance.recordError(e, s);
    } catch (_) {}
  }

  Future<void> _onSubscribed(
    BillsSubscribed event,
    Emitter<BillsState> emit,
  ) async {
    emit(state.copyWith(status: BillsStatus.loading));
    await emit.forEach<Either<Failure, List<BillEntity>>>(
      _watchActiveBills(const NoParams()),
      onData: (either) => either.fold(
        (f) => state.copyWith(status: BillsStatus.failure, failure: f),
        (bills) => state.copyWith(
          status: BillsStatus.success,
          bills: bills,
          clearFailure: true,
        ),
      ),
      onError: (e, s) {
        _log(e, s);
        return state.copyWith(
          status: BillsStatus.failure,
          failure: const CacheFailure('Gagal memuat tagihan.'),
        );
      },
    );
  }

  Future<void> _onAdded(BillAdded event, Emitter<BillsState> emit) async {
    final result = await _createBill(event.bill);
    result.fold(
      (f) => emit(state.copyWith(status: BillsStatus.failure, failure: f)),
      (_) {},
    );
    // sukses: stream watchActive akan re-emit daftar terbaru otomatis.
  }

  Future<void> _onUpdated(BillUpdated event, Emitter<BillsState> emit) async {
    final result = await _updateBill(event.bill);
    result.fold(
      (f) => emit(state.copyWith(status: BillsStatus.failure, failure: f)),
      (_) {},
    );
  }

  Future<void> _onDeleted(BillDeleted event, Emitter<BillsState> emit) async {
    final result = await _deleteBill(event.id);
    result.fold(
      (f) => emit(state.copyWith(status: BillsStatus.failure, failure: f)),
      (_) {},
    );
  }

  /// Orkestrasi "tandai lunas" (spec §5). Urutan WAJIB:
  /// 1. snapshot bill SEBELUM payment (untuk undo);
  /// 2. buat transaksi (kecuali opt-out) — id uuid = txId snapshot (F9);
  /// 3-5. hitung next-state (MURNI via `markBillPaid`);
  /// 6. persist mutasi bill;
  /// 7. simpan UndoSnapshot = state lama.
  /// Reschedule notif menyusul di Task 6.2.
  Future<void> _onMarkedPaid(
    BillMarkedPaid event,
    Emitter<BillsState> emit,
  ) async {
    // 1. SNAPSHOT bill SEBELUM payment (untuk undo). Bedakan error baca DB
    // (forward Failure asli) dari kasus bill memang tak ada (Right(null)).
    final billResult = await _billRepository.getBillById(event.billId);
    if (billResult.isLeft()) {
      emit(
        state.copyWith(
          status: BillsStatus.failure,
          failure: billResult.swap().getOrElse(
            () => const CacheFailure('Gagal memuat tagihan.'),
          ),
        ),
      );
      return;
    }
    final bill = billResult.fold((_) => null, (b) => b);
    if (bill == null) {
      emit(
        state.copyWith(
          status: BillsStatus.failure,
          failure: const CacheFailure('Tagihan tak ditemukan.'),
        ),
      );
      return;
    }

    // 2. Buat transaksi KECUALI opt-out. F9: AddTransactionUseCase return void →
    // generate uuid SENDIRI; id yang sama dipakai sebagai txId snapshot.
    String? txId;
    if (!event.optOutTransaction) {
      final id = _uuid.v4();
      final now = DateTime.now();
      final txn = TransactionEntity(
        id: id,
        amount: event.actualAmount,
        // decoupling §4.2: category dari bill.
        category: bill.category,
        type: TransactionType.expense,
        date: event.paidDate,
        // decoupling: isFixed dari EVENT, BUKAN derive category=='fixed'.
        isFixed: event.includeAsFixed,
        isSynced: false,
        createdAt: now,
        updatedAt: now,
        // link untuk undo (K1/K2).
        sourceBillId: event.billId,
      );
      final txnResult = await _addTransaction(txn);
      if (txnResult.isLeft()) {
        emit(
          state.copyWith(
            status: BillsStatus.failure,
            failure: txnResult.swap().getOrElse(
              () => const CacheFailure('Gagal mencatat transaksi.'),
            ),
          ),
        );
        return; // JANGAN advance tanpa transaksi tersimpan.
      }
      txId = id;
    }

    // 3-5. Hitung next-state (MURNI).
    final advance = markBillPaid(bill: bill);

    // 6. Persist mutasi bill.
    final applyResult = await _billRepository.applyBillPayment(
      id: event.billId,
      newDueDate: advance.newDueDate,
      newInstallmentsPaid: advance.newInstallmentsPaid,
      newStatus: advance.newStatus,
    );
    if (applyResult.isLeft()) {
      emit(
        state.copyWith(
          status: BillsStatus.failure,
          failure: applyResult.swap().getOrElse(
            () => const CacheFailure('Gagal memperbarui tagihan.'),
          ),
        ),
      );
      return;
    }

    // 7. UndoSnapshot = state SEBELUM payment (nilai bill yang di-snapshot di
    // langkah 1). Daftar aktif refresh otomatis via stream watchActive.
    emit(
      state.copyWith(
        status: BillsStatus.success,
        lastUndo: UndoSnapshot(
          billId: event.billId,
          dueDate: bill.dueDate,
          installmentsPaid: bill.installmentsPaid,
          status: bill.status,
          txId: txId,
        ),
      ),
    );
  }

  /// "Batal lunas" / undo (spec §6.5). Restore state bill PERSIS dari snapshot
  /// (BUKAN recompute/hitung mundur — anchor akhir-bulan tak boleh geser), lalu
  /// hapus transaksi yang dibuat saat lunas (bila ada; opt-out → txId null →
  /// skip). Reschedule notif menyusul di Task 6.2.
  Future<void> _onPaymentUndone(
    BillPaymentUndone event,
    Emitter<BillsState> emit,
  ) async {
    final snap = event.snapshot;

    // 1. RESTORE state bill PERSIS dari snapshot (bukan recompute).
    final restoreResult = await _billRepository.restoreBillPayment(
      id: snap.billId,
      dueDate: snap.dueDate,
      installmentsPaid: snap.installmentsPaid,
      status: snap.status,
    );
    if (restoreResult.isLeft()) {
      emit(
        state.copyWith(
          status: BillsStatus.failure,
          failure: restoreResult.swap().getOrElse(
            () => const CacheFailure('Gagal membatalkan pembayaran.'),
          ),
        ),
      );
      return;
    }

    // 2. Hapus transaksi bila ada (opt-out → txId null → skip).
    final txId = snap.txId;
    if (txId != null) {
      final delResult = await _deleteTransaction(txId);
      if (delResult.isLeft()) {
        emit(
          state.copyWith(
            status: BillsStatus.failure,
            failure: delResult.swap().getOrElse(
              () => const CacheFailure('Gagal menghapus transaksi.'),
            ),
          ),
        );
        return;
      }
    }

    // 3. Reschedule notif → Task 6.2 (belum di sini).
    // 4. Clear lastUndo + success. Daftar aktif refresh via stream watchActive.
    emit(state.copyWith(status: BillsStatus.success, clearUndo: true));
  }
}
