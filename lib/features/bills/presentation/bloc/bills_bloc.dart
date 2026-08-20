import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/bills/data/datasources/bill_reminder_scheduler.dart';
import 'package:penyintas_app/features/bills/data/datasources/bill_reminder_settings_datasource.dart';
import 'package:penyintas_app/features/bills/data/models/bill_model.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/domain/repositories/bill_repository.dart';
import 'package:penyintas_app/features/bills/domain/usecases/create_bill_usecase.dart';
import 'package:penyintas_app/features/bills/domain/usecases/delete_bill_usecase.dart';
import 'package:penyintas_app/features/bills/domain/usecases/mark_bill_paid_usecase.dart';
import 'package:penyintas_app/features/bills/domain/usecases/represented_by_fixed_expenses.dart';
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
    required BillReminderScheduler reminderScheduler,
    required BillReminderSettingsDatasource reminderSettings,
  }) : _watchActiveBills = watchActiveBills,
       _createBill = createBill,
       _updateBill = updateBill,
       _deleteBill = deleteBill,
       _billRepository = billRepository,
       _addTransaction = addTransaction,
       _deleteTransaction = deleteTransaction,
       _reminderScheduler = reminderScheduler,
       _reminderSettings = reminderSettings,
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
  final BillReminderScheduler _reminderScheduler;
  final BillReminderSettingsDatasource _reminderSettings;

  static const _uuid = Uuid();

  /// Penghitung monoton untuk `BillActionFailure.seq`. Lihat dartdoc `seq`.
  int _actionSeq = 0;

  /// Pemancaran kegagalan AKSI TULIS. SENGAJA tidak menyentuh `status`
  /// maupun `failure`: keduanya milik stream muat, dan mencampurinya adalah
  /// bug yang perbaikan ini tutup — gagal menulis pernah membuat seluruh
  /// daftar lenyap dan menyalahkan "gagal memuat".
  BillsState _gagalAksi(BillWriteAction aksi, Failure f, {int? billId}) =>
      state.copyWith(
        actionFailure: BillActionFailure(
          aksi: aksi,
          failure: f,
          seq: ++_actionSeq,
          billId: billId,
        ),
      );

  static void _log(Object e, StackTrace s) {
    try {
      FirebaseCrashlytics.instance.recordError(e, s);
    } catch (_) {}
  }

  /// Reschedule pengingat dari daftar bill aktif TERKINI (Task 6.2) — BUKAN
  /// `state.bills`, yang saat handler ini jalan mungkin belum ter-refresh via
  /// stream `watchActiveBills` (race async). Non-fatal: kegagalan jadwal
  /// TIDAK boleh menggagalkan operasi bill yang sudah sukses — dibungkus
  /// try/catch, jangan emit failure karenanya.
  Future<void> _reschedule() async {
    try {
      final result = await _watchActiveBills(const NoParams()).first;
      final bills = result.fold((_) => null, (list) => list);
      if (bills == null) return; // gagal baca → skip diam-diam
      final settings = await _reminderSettings.read();
      await _reminderScheduler.rescheduleAll(
        bills,
        globalDaysBefore: settings.daysBefore,
        globalHour: settings.hour,
      );
    } catch (e, s) {
      _log(e, s);
    }
  }

  /// Batalkan pengingat SATU bill secara EKSPLISIT (F3) — dipakai saat bill
  /// keluar dari `activeBills` (dihapus, atau mark-paid → completed) sehingga
  /// [_reschedule] TAK BISA membatalkan notif lamanya (bill itu sudah tak ada
  /// di snapshot yang dibaca [_reschedule]) → tanpa ini notif jadi yatim.
  /// Non-fatal, sama seperti [_reschedule].
  Future<void> _cancelReminder(int billId) async {
    try {
      await _reminderScheduler.cancelFor(billId);
    } catch (e, s) {
      _log(e, s);
    }
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
          clearActionFailure: true,
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
    await result.fold(
      (f) async => emit(_gagalAksi(BillWriteAction.add, f)),
      // sukses: stream watchActive akan re-emit daftar terbaru otomatis;
      // reschedule (Task 6.2) pakai snapshot terkini agar bill baru ikut.
      (_) => _reschedule(),
    );
  }

  Future<void> _onUpdated(BillUpdated event, Emitter<BillsState> emit) async {
    final result = await _updateBill(event.bill);
    await result.fold(
      (f) async => emit(_gagalAksi(BillWriteAction.update, f)),
      (_) => _reschedule(),
    );
  }

  Future<void> _onDeleted(BillDeleted event, Emitter<BillsState> emit) async {
    final result = await _deleteBill(event.id);
    await result.fold(
      (f) async =>
          emit(_gagalAksi(BillWriteAction.delete, f, billId: event.id)),
      // F3: bill terhapus TIDAK ADA lagi di activeBills → rescheduleAll TAK
      // BISA membatalkan notif lamanya. cancelFor EKSPLISIT wajib, kalau
      // tidak notif jadi yatim (tetap tampil utk bill yang sudah dihapus).
      (_) => _cancelReminder(event.id),
    );
  }

  /// Orkestrasi "tandai lunas" (spec §5). Urutan WAJIB:
  /// 1. snapshot bill SEBELUM payment (untuk undo);
  /// 2. buat transaksi (kecuali opt-out) — id uuid = txId snapshot (F9);
  /// 3-5. hitung next-state (MURNI via `markBillPaid`);
  /// 6. persist mutasi bill;
  /// 6b. reschedule notif (Task 6.2) — lihat langkah di bawah;
  /// 7. simpan UndoSnapshot = state lama.
  Future<void> _onMarkedPaid(
    BillMarkedPaid event,
    Emitter<BillsState> emit,
  ) async {
    // 1. SNAPSHOT bill SEBELUM payment (untuk undo). Bedakan error baca DB
    // (forward Failure asli) dari kasus bill memang tak ada (Right(null)).
    final billResult = await _billRepository.getBillById(event.billId);
    if (billResult.isLeft()) {
      emit(
        _gagalAksi(
          BillWriteAction.markPaid,
          billResult.swap().getOrElse(
            () => const CacheFailure('Gagal memuat tagihan.'),
          ),
          billId: event.billId,
        ),
      );
      return;
    }
    final bill = billResult.fold((_) => null, (b) => b);
    if (bill == null) {
      emit(
        _gagalAksi(
          BillWriteAction.markPaid,
          const CacheFailure('Tagihan tak ditemukan.'),
          billId: event.billId,
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
        // decoupling: isFixed dari EVENT, BUKAN derive category=='fixed' —
        // lalu DISEMPITKAN oleh bentuk tagihan.
        // Monoton menurun: hanya bisa MEMATIKAN, tak pernah menyalakan.
        // Paruh `fixedExpenses > 0` sengaja TIDAK diulang di sini — itu milik
        // gerbang M1 di AddTransactionUseCase, yang punya akses BudgetSettings.
        // Menuliskannya lagi di sini = salinan kedua aturan M1.
        isFixed: event.includeAsFixed && representedByFixedExpenses(bill),
        isSynced: false,
        createdAt: now,
        updatedAt: now,
        // link untuk undo (K1/K2).
        sourceBillId: event.billId,
      );
      final txnResult = await _addTransaction(txn);
      if (txnResult.isLeft()) {
        emit(
          _gagalAksi(
            BillWriteAction.markPaid,
            txnResult.swap().getOrElse(
              () => const CacheFailure('Gagal mencatat transaksi.'),
            ),
            billId: event.billId,
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
      // KOMPENSASI. Transaksinya sudah masuk DB di langkah 2, dan tagihannya
      // gagal maju di langkah 6 — tanpa baris ini pengeluarannya tercatat
      // untuk pembayaran yang TIDAK PERNAH terjadi. Dan karena snackbarnya
      // mengundang "Coba lagi", ketukan berikutnya menulis transaksi KEDUA:
      // satu tagihan, dua kali uang keluar, tanpa satu pun tanda di layar.
      //
      // Best-effort, persis pola `_reschedule`/`_cancelReminder`: kegagalan
      // kompensasi TIDAK boleh menggantikan galat aslinya. Yang perlu
      // diketahui pengguna adalah pembayarannya tak tercatat — bukan detail
      // pembersihan yang ia tak pernah minta.
      if (txId != null) {
        try {
          final bersih = await _deleteTransaction(txId);
          bersih.fold(
            (f) => _log(
              StateError(
                'Kompensasi transaksi yatim gagal: $f '
                '(txId: $txId, billId: ${event.billId})',
              ),
              StackTrace.current,
            ),
            (_) {},
          );
        } catch (e, st) {
          _log(e, st);
        }
      }
      emit(
        _gagalAksi(
          BillWriteAction.markPaid,
          applyResult.swap().getOrElse(
            () => const CacheFailure('Gagal memperbarui tagihan.'),
          ),
          billId: event.billId,
        ),
      );
      return;
    }

    // 6b. Reschedule notif (Task 6.2) dgn daftar bill aktif TERKINI (dueDate
    // sudah roll-forward pasca applyBillPayment di atas). F3: bila bill ini
    // JADI completed, ia keluar dari activeBills sehingga _reschedule TAK
    // BISA membatalkan notif lamanya sendiri → cancelFor EKSPLISIT di
    // SAMPING reschedule, simetris dgn BillDeleted.
    await _reschedule();
    if (advance.newStatus == BillStatus.completed) {
      await _cancelReminder(event.billId);
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
        clearActionFailure: true,
      ),
    );
  }

  /// "Batal lunas" / undo (spec §6.5). Restore state bill PERSIS dari snapshot
  /// (BUKAN recompute/hitung mundur — anchor akhir-bulan tak boleh geser), lalu
  /// hapus transaksi yang dibuat saat lunas (bila ada; opt-out → txId null →
  /// skip), lalu reschedule notif (Task 6.2).
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
        _gagalAksi(
          BillWriteAction.undoPayment,
          restoreResult.swap().getOrElse(
            () => const CacheFailure('Gagal membatalkan pembayaran.'),
          ),
          billId: snap.billId,
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
          _gagalAksi(
            BillWriteAction.undoPayment,
            delResult.swap().getOrElse(
              () => const CacheFailure('Gagal menghapus transaksi.'),
            ),
            billId: snap.billId,
          ),
        );
        return;
      }
    }

    // 3. Reschedule notif (Task 6.2): bill kembali ke activeBills (undo
    // completed→active ATAU restore bulanan biasa) → cukup andalkan
    // _reschedule, TIDAK perlu cancelFor (tak ada bill yang keluar aktif).
    await _reschedule();

    // 4. Clear lastUndo + success. Daftar aktif refresh via stream watchActive.
    emit(
      state.copyWith(
        status: BillsStatus.success,
        clearUndo: true,
        clearActionFailure: true,
      ),
    );
  }
}
