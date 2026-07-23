part of 'bills_bloc.dart';

sealed class BillsEvent extends Equatable {
  const BillsEvent();

  @override
  List<Object?> get props => [];
}

/// Subscribe ke stream tagihan aktif (Drift `watchActiveBills`).
/// `restartable()` — subscription lama dibatalkan saat event baru masuk.
final class BillsSubscribed extends BillsEvent {
  const BillsSubscribed();
}

final class BillAdded extends BillsEvent {
  const BillAdded(this.bill);

  final BillModel bill;

  @override
  List<Object?> get props => [bill];
}

final class BillUpdated extends BillsEvent {
  const BillUpdated(this.bill);

  final BillModel bill;

  @override
  List<Object?> get props => [bill];
}

final class BillDeleted extends BillsEvent {
  const BillDeleted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

/// "Tandai lunas" (spec §5): snapshot → transaksi (kecuali opt-out) →
/// advance progres + roll-forward dueDate + stop-check → persist → UndoSnapshot.
final class BillMarkedPaid extends BillsEvent {
  const BillMarkedPaid({
    required this.billId,
    required this.actualAmount,
    required this.paidDate,
    required this.includeAsFixed,
    required this.optOutTransaction,
  });

  /// PK lokal bill yang dibayar.
  final int billId;

  /// Nominal aktual yang dibayar (bisa beda dari estimasi bill).
  final int actualAmount;

  /// Tanggal pembayaran — dipakai sebagai `date` transaksi.
  final DateTime paidDate;

  /// Catat transaksi sebagai kebutuhan tetap (decoupling §4.2: dari EVENT,
  /// BUKAN derive dari `category == 'fixed'`).
  final bool includeAsFixed;

  /// Bila true: TIDAK membuat transaksi (advance bill tetap jalan).
  final bool optOutTransaction;

  @override
  List<Object?> get props => [
    billId,
    actualAmount,
    paidDate,
    includeAsFixed,
    optOutTransaction,
  ];
}

// NOTE: BillPaymentUndone (Task 3.3) SENGAJA belum dideklarasikan di sini —
// di luar scope Task 3.2.
