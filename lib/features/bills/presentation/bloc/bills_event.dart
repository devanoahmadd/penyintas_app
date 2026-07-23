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

// NOTE: BillMarkedPaid (Task 3.2) & BillPaymentUndone (Task 3.3) SENGAJA
// belum dideklarasikan di sini — di luar scope Task 3.1.
