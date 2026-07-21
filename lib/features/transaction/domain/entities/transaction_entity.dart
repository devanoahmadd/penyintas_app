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
  ];
}

enum TransactionType { expense, income }
