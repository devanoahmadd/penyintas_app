import 'package:equatable/equatable.dart';

class TransactionEntity extends Equatable {
  const TransactionEntity({
    required this.id,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
    required this.isFixed,
    required this.isSynced,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.goalId,
    this.sourceBillId,
  });

  final String id;
  final int amount;
  final String category;
  final TransactionType type;
  final String? note;
  final DateTime date;
  final bool isFixed;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Link ke Goals.id — null jika tidak dikaitkan ke tujuan tabungan.
  final int? goalId;

  /// Link balik ke tagihan asal — null jika transaksi bukan hasil "Tandai
  /// Lunas" tagihan (A1 Tagihan). PK lokal murni, TIDAK disinkron ke
  /// Firestore (int lokal tak bermakna lintas-device).
  final int? sourceBillId;

  /// Sengaja HANYA `isFixed` yang bisa diubah — entity domain ini tidak butuh
  /// `copyWith` umum, dan menambah parameter lain membuka jalan mutasi yang
  /// tak ada pemakainya (YAGNI). Satu-satunya pemakai: gerbang invariant M1
  /// di `AddTransactionUseCase`.
  TransactionEntity copyWith({bool? isFixed}) => TransactionEntity(
    id: id,
    amount: amount,
    category: category,
    type: type,
    note: note,
    date: date,
    isFixed: isFixed ?? this.isFixed,
    isSynced: isSynced,
    createdAt: createdAt,
    updatedAt: updatedAt,
    goalId: goalId,
    sourceBillId: sourceBillId,
  );

  @override
  List<Object?> get props => [
    id,
    amount,
    category,
    type,
    note,
    date,
    isFixed,
    isSynced,
    createdAt,
    updatedAt,
    goalId,
    sourceBillId,
  ];
}

enum TransactionType { expense, income }
