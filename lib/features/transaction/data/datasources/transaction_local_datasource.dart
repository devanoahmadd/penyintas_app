import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/transaction/data/models/transaction_model.dart';

abstract class TransactionLocalDataSource {
  Future<void> saveTransaction(TransactionModel model);
  Future<void> updateTransaction(TransactionModel model);
  Future<void> deleteTransaction(String txId);
  Future<List<TransactionModel>> getTodayTransactions();
  Future<List<TransactionModel>> getTransactionsByDateRange(
      DateTime from, DateTime to);
  Stream<List<TransactionModel>> watchTodayTransactions();
  Future<void> markSynced(String txId);
  Future<List<TransactionModel>> getUnsyncedTransactions();
  Future<void> addToSyncQueue({
    required String itemId,
    required String collectionPath,
    required Map<String, dynamic> data,
    required SyncOperation operation,
  });
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  TransactionLocalDataSourceImpl(this._db);
  final AppDatabase _db;

  @override
  Future<void> saveTransaction(TransactionModel model) =>
      _db.into(_db.transactions).insertOnConflictUpdate(model.toDriftCompanion());

  @override
  Future<void> updateTransaction(TransactionModel model) =>
      _db.into(_db.transactions).insertOnConflictUpdate(model.toDriftCompanion());

  @override
  Future<void> deleteTransaction(String txId) =>
      (_db.delete(_db.transactions)..where((t) => t.txId.equals(txId))).go();

  @override
  Future<List<TransactionModel>> getTodayTransactions() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    final rows = await (_db.select(_db.transactions)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerOrEqualValue(end))
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .get();
    return rows.map(TransactionModel.fromDrift).toList();
  }

  @override
  Future<List<TransactionModel>> getTransactionsByDateRange(
      DateTime from, DateTime to) async {
    final rows = await (_db.select(_db.transactions)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(from) &
              t.date.isSmallerOrEqualValue(to))
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .get();
    return rows.map(TransactionModel.fromDrift).toList();
  }

  @override
  Stream<List<TransactionModel>> watchTodayTransactions() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return (_db.select(_db.transactions)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerOrEqualValue(end))
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .watch()
        .map((rows) => rows.map(TransactionModel.fromDrift).toList());
  }

  @override
  Future<void> markSynced(String txId) =>
      (_db.update(_db.transactions)..where((t) => t.txId.equals(txId))).write(
        TransactionsCompanion(
          isSynced: const Value(true),
          syncedAt: Value(DateTime.now()),
        ),
      );

  @override
  Future<List<TransactionModel>> getUnsyncedTransactions() async {
    final rows = await (_db.select(_db.transactions)
          ..where((t) => t.isSynced.equals(false)))
        .get();
    return rows.map(TransactionModel.fromDrift).toList();
  }

  @override
  Future<void> addToSyncQueue({
    required String itemId,
    required String collectionPath,
    required Map<String, dynamic> data,
    required SyncOperation operation,
  }) =>
      _db.into(_db.syncQueue).insert(SyncQueueCompanion(
            itemId: Value(itemId),
            collectionPath: Value(collectionPath),
            data: Value(jsonEncode(data)),
            operation: Value(operation),
            createdAt: Value(DateTime.now()),
          ));
}
