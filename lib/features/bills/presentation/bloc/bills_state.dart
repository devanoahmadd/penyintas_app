part of 'bills_bloc.dart';

enum BillsStatus { initial, loading, success, failure }

/// Aksi tulis yang bisa gagal. Dipakai konsumen untuk memutuskan permukaan
/// mana yang berbicara — daftar berbicara untuk `delete` dan `undoPayment`,
/// dua aksi yang tak punya permukaan lain di atasnya.
enum BillWriteAction { add, update, delete, markPaid, undoPayment }

/// Kegagalan AKSI TULIS — TERPISAH dari [BillsState.status], yang sejak
/// perbaikan ini murni milik stream `watchActiveBills`.
///
/// Sebelum pemisahan ini, gagal menghapus satu tagihan membuat SELURUH daftar
/// lenyap dan diganti layar "Gagal memuat tagihan" — menyalahkan hal yang
/// salah, dan menetap karena tak ada tulisan ke DB yang memicu stream
/// memancar ulang.
class BillActionFailure extends Equatable {
  const BillActionFailure({
    required this.aksi,
    required this.failure,
    required this.seq,
    this.billId,
  });

  final BillWriteAction aksi;
  final Failure failure;

  /// Penghitung monoton dari bloc. ADA KARENA DUA ALASAN KONKRET:
  /// (a) gagal hapus dua kali berturut-turut dengan [Failure] identik membuat
  ///     `props` sama, `listenWhen` tak menyala, dan snackbar kedua tak
  ///     pernah tampil;
  /// (b) konsumen memakainya untuk membedakan kegagalan BARU dari kegagalan
  ///     lama yang masih menempel di state — tanpa itu form menutup diam-diam
  ///     atau menampilkan galat milik permukaan lain.
  final int seq;

  /// Id tagihan yang gagal ditulis — dipakai aksi "Coba lagi" di snackbar.
  /// Null untuk aksi yang tak punya sasaran tunggal.
  final int? billId;

  @override
  List<Object?> get props => [aksi, failure, seq, billId];
}

/// Snapshot state bill SEBELUM pembayaran — untuk undo (Task 3.3).
class UndoSnapshot extends Equatable {
  const UndoSnapshot({
    required this.billId,
    required this.dueDate,
    required this.installmentsPaid,
    required this.status,
    this.txId,
  });

  final int billId;
  final DateTime dueDate;
  final int installmentsPaid;
  final BillStatus status;

  /// null bila pembayaran opt-out (tanpa transaksi).
  final String? txId;

  @override
  List<Object?> get props => [billId, dueDate, installmentsPaid, status, txId];
}

class BillsState extends Equatable {
  const BillsState({
    this.status = BillsStatus.initial,
    this.bills = const <BillEntity>[],
    this.failure,
    this.lastUndo,
    this.actionFailure,
  });

  final BillsStatus status;
  final List<BillEntity> bills;
  final Failure? failure;
  final UndoSnapshot? lastUndo;
  final BillActionFailure? actionFailure;

  BillsState copyWith({
    BillsStatus? status,
    List<BillEntity>? bills,
    Failure? failure,
    bool clearFailure = false,
    UndoSnapshot? lastUndo,
    bool clearUndo = false,
    BillActionFailure? actionFailure,
    bool clearActionFailure = false,
  }) => BillsState(
    status: status ?? this.status,
    bills: bills ?? this.bills,
    failure: clearFailure ? null : (failure ?? this.failure),
    lastUndo: clearUndo ? null : (lastUndo ?? this.lastUndo),
    actionFailure: clearActionFailure
        ? null
        : (actionFailure ?? this.actionFailure),
  );

  @override
  List<Object?> get props => [status, bills, failure, lastUndo, actionFailure];
}
