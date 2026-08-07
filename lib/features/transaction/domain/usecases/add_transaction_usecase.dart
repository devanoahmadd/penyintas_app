import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/budget/domain/repositories/budget_repository.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/domain/repositories/transaction_repository.dart';

/// Titik cekik tunggal jalur **pembuatan** transaksi (spec Fase 8 §2.5) —
/// bukan seluruh jalur tulis. `UpdateTransactionUseCase`
/// (`update_transaction_usecase.dart:12-13`) adalah penulis kolom `isFixed`
/// kedua, dan sengaja TIDAK digating (spec §2.4): menggating edit akan
/// membalik angka bulan lalu saat `fixedExpenses` sudah berubah.
///
/// Dua pemanggil di seluruh aplikasi: `bills_bloc.dart:227` dan
/// `add_transaction_bloc.dart:166`. Invariant M1 ditegakkan DI SINI, bukan
/// per-BLoC, karena invariant domain yang dijaga di lapisan presentasi
/// selalu punya pintu ke-N+1 — Fase 7 sudah membuktikannya di repo ini.
class AddTransactionUseCase implements UseCase<void, TransactionEntity> {
  const AddTransactionUseCase(this._repository, this._budget);
  final TransactionRepository _repository;

  /// Repository domain di-inject langsung (domain -> domain), bukan
  /// `GetBudgetSettingsUseCase` — menghindari usecase memanggil usecase.
  final BudgetRepository _budget;

  @override
  Future<Either<Failure, void>> call(TransactionEntity params) async {
    // Invariant M1: `isFixed=true` hanya sah bila ada potongan di muka.
    //
    // MONOTON MENURUN — hanya boleh mematikan, tak pernah menyalakan. Kalau
    // gerbang ini bisa menyalakan, opt-out sadar pengguna di sheet bayar
    // tagihan (`includeAsFixed=false` saat fixedExpenses > 0) akan ditimpa.
    //
    // Konsekuensi langsung dari sifat monoton itu: kalau `isFixed` sudah
    // false, jawaban anggaran tak bisa mengubah apa pun. Pulang lebih awal —
    // ini jalur terpanas aplikasi (catat pengeluaran harian), dan
    // `getBudgetSettings()` adalah satu baca Drift (`budget_repository_impl
    // .dart:34`) yang di ~95% penambahan transaksi tak terpakai. Dikunci
    // test (e).
    if (!params.isFixed) return _repository.addTransaction(params);

    // Arah gagal: `Left` diperlakukan sebagai fixedExpenses = 0.
    // `budget_repository_impl.dart:36` mengembalikan Left ketika baris
    // settings belum ada, dan "belum diisi" secara semantik memang
    // fixedExpenses == 0 — yaitu kondisi M1 itu sendiri. Error DB sungguhan
    // praktis tak terjangkau di jalur ini: kalau Drift lokal mati,
    // penyimpanan transaksinya juga gagal.
    final fixedExpenses = (await _budget.getBudgetSettings()).fold(
      (_) => 0,
      (s) => s.fixedExpenses,
    );
    // Sampai di sini `params.isFixed` PASTI true, jadi `sah` hanya bisa
    // mematikan — tidak ada cabang yang menyalakan.
    final sah = fixedExpenses > 0;
    return _repository.addTransaction(
      sah ? params : params.copyWith(isFixed: false),
    );
  }
}
