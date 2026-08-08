import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/transaction/domain/repositories/transaction_repository.dart';

/// Hapus semua transaksi yang bersumber dari sebuah tagihan.
///
/// **NOL PEMANGGIL — DAN ITU DISENGAJA (spec §4.6, keputusan D7).**
///
/// Menghapus tagihan TIDAK menghapus transaksi yang sudah tercatat: tagihan
/// adalah jadwal, transaksi adalah fakta. Uang yang keluar bulan lalu tetap
/// keluar meski jadwalnya dihapus hari ini. Menyambungkan usecase ini ke jalur
/// hapus-tagihan akan menaikkan saldo historis, mengubah laporan bulan-bulan
/// lampau, dan menggeser Days-to-Live — tanpa satu rupiah pun benar-benar
/// kembali.
///
/// Dartdoc lama menyebut "(undo tagihan)" dan itu KELIRU: undo tandai-lunas
/// dikerjakan `restoreBillPayment`, bukan ini. Salah baca itulah yang membuat
/// usecase ini berulang kali terlihat seperti pekerjaan yang tertinggal.
///
/// Sengaja TIDAK didaftarkan di `injection_container.dart`. Mendaftarkannya
/// tanpa pemakai hanya menambah umpan bagi salah paham berikutnya. Ia disimpan
/// karena jalurnya lengkap (hapus lokal + antre hapus remote) dan siap dipakai
/// kalau kelak ada fitur "hapus tagihan beserta seluruh jejaknya" yang memang
/// diminta pengguna.
class DeleteTransactionsBySourceBillUseCase implements UseCase<void, int> {
  const DeleteTransactionsBySourceBillUseCase(this._repository);
  final TransactionRepository _repository;

  @override
  Future<Either<Failure, void>> call(int params) =>
      _repository.deleteTransactionsBySourceBill(params);
}
