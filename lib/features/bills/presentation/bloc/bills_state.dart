part of 'bills_bloc.dart';

enum BillsStatus { initial, loading, success, failure }

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
  });

  final BillsStatus status;
  final List<BillEntity> bills;
  final Failure? failure;
  final UndoSnapshot? lastUndo;

  BillsState copyWith({
    BillsStatus? status,
    List<BillEntity>? bills,
    Failure? failure,
    bool clearFailure = false,
    UndoSnapshot? lastUndo,
    bool clearUndo = false,
  }) => BillsState(
    status: status ?? this.status,
    bills: bills ?? this.bills,
    failure: clearFailure ? null : (failure ?? this.failure),
    lastUndo: clearUndo ? null : (lastUndo ?? this.lastUndo),
  );

  @override
  List<Object?> get props => [status, bills, failure, lastUndo];
}
