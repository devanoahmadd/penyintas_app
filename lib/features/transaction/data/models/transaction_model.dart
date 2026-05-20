import 'package:drift/drift.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';

class TransactionModel {
  const TransactionModel({
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
  });

  final String id;
  final int amount;
  final TransactionCategory category;
  final TransactionType type;
  final String? note;
  final DateTime date;
  final bool isFixed;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionEntity toEntity() => TransactionEntity(
        id: id,
        amount: amount,
        category: category,
        type: type,
        note: note,
        date: date,
        isFixed: isFixed,
        isSynced: isSynced,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static TransactionModel fromEntity(TransactionEntity e) => TransactionModel(
        id: e.id,
        amount: e.amount,
        category: e.category,
        type: e.type,
        note: e.note,
        date: e.date,
        isFixed: e.isFixed,
        isSynced: e.isSynced,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
      );

  static TransactionModel fromDrift(Transaction row) => TransactionModel(
        id: row.txId,
        amount: row.amount,
        category: _categoryFromString(row.category),
        type: TransactionType.values.byName(row.type),
        note: row.note,
        date: row.date,
        isFixed: row.isFixed,
        isSynced: row.isSynced,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  TransactionsCompanion toDriftCompanion() => TransactionsCompanion(
        txId: Value(id),
        amount: Value(amount),
        category: Value(category.name),
        type: Value(type.name),
        note: Value(note),
        date: Value(date),
        isFixed: Value(isFixed),
        isSynced: Value(isSynced),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
      );

  static TransactionModel fromFirestore(Map<String, dynamic> data) =>
      TransactionModel(
        id: data['id'] as String,
        amount: (data['amount'] as num?)?.toInt() ?? 0,
        category: _categoryFromString(data['category'] as String? ?? 'other'),
        type: _typeFromString(data['type'] as String? ?? 'expense'),
        note: data['note'] as String?,
        date: DateTime.parse(data['date'] as String),
        isFixed: data['isFixed'] as bool? ?? false,
        isSynced: true,
        createdAt: DateTime.parse(data['createdAt'] as String),
        updatedAt: DateTime.parse(data['updatedAt'] as String),
      );

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'amount': amount,
        'category': category.name,
        'type': type.name,
        'note': note,
        'date': date.toIso8601String(),
        'isFixed': isFixed,
        'isSynced': true,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  TransactionModel copyWith({bool? isSynced}) => TransactionModel(
        id: id,
        amount: amount,
        category: category,
        type: type,
        note: note,
        date: date,
        isFixed: isFixed,
        isSynced: isSynced ?? this.isSynced,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static TransactionCategory _categoryFromString(String s) {
    switch (s) {
      case 'food':
        return TransactionCategory.food;
      case 'transport':
        return TransactionCategory.transport;
      case 'shopping':
        return TransactionCategory.shopping;
      case 'health':
        return TransactionCategory.health;
      case 'internet':
      case 'data': // backward compat
        return TransactionCategory.internet;
      case 'fixed':
        return TransactionCategory.fixed;
      case 'income':
        return TransactionCategory.income;
      case 'campus': // backward compat → other
      default:
        return TransactionCategory.other;
    }
  }

  static TransactionType _typeFromString(String s) =>
      s == 'income' ? TransactionType.income : TransactionType.expense;
}
