import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/bills/data/models/bill_model.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';

abstract class BillRepository {
  /// Stream bill aktif, terurut jatuh tempo terdekat dulu.
  Stream<Either<Failure, List<BillEntity>>> watchActiveBills();

  /// Simpan bill baru. Return id lokal autoincrement (dipakai jadwal notif).
  Future<Either<Failure, int>> createBill(BillModel model);

  /// Update bill existing — [model] WAJIB sudah membawa cloudId.
  Future<Either<Failure, void>> updateBill(BillModel model);

  Future<Either<Failure, void>> deleteBill(int id);

  /// Ambil satu bill sebagai entity by id lokal (null bila tak dikenal).
  /// Dipakai orkestrasi "tandai lunas" untuk snapshot state SEBELUM payment.
  Future<Either<Failure, BillEntity?>> getBillById(int id);

  /// Persist mutasi pasca pembayaran (roll-forward): dueDate + progres
  /// cicilan + status sekaligus. Lokal-first (tak push remote di sini).
  Future<Either<Failure, void>> applyBillPayment({
    required int id,
    required DateTime newDueDate,
    required int newInstallmentsPaid,
    required BillStatus newStatus,
  });

  /// Hydrate bill dari Firestore SEKALI saat tabel lokal kosong
  /// (reinstall / ganti device / login akun lama) — pull-all-on-first-sync.
  /// Return jumlah bill yang dipulihkan (0 bila lokal berisi/offline/remote
  /// kosong).
  Future<Either<Failure, int>> syncBillsFromRemote();
}
