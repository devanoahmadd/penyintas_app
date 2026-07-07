import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/goal/data/models/goal_model.dart';
import 'package:penyintas_app/features/goal/domain/entities/goal_entity.dart';
import 'package:uuid/uuid.dart';

abstract class GoalLocalDatasource {
  Future<List<GoalEntity>> loadGoals();

  /// Insert goal baru + generate UUID v4 sebagai firestoreId.
  /// Return model tersimpan — dipakai repository untuk push/queue remote.
  Future<GoalModel> createGoal({
    required String title,
    required int targetAmount,
    required DateTime targetDate,
  });

  Future<void> linkTransaction({required String txId, required int goalId});
  Future<void> unlinkTransaction(String txId);
  Future<void> completeGoal(int goalId);
  Future<void> deleteGoal(int goalId);

  /// Snapshot row → model untuk push remote (null bila id tak dikenal).
  Future<GoalModel?> findById(int goalId);

  /// firestoreId milik goal (null bila id tak dikenal).
  Future<String?> firestoreIdOf(int goalId);

  Future<bool> hasAnyGoals();

  /// Hydrate dari remote — idempoten by firestoreId (skip yang sudah ada).
  Future<void> upsertFromRemote(List<GoalModel> models);

  Future<void> addToSyncQueue({
    required String itemId,
    required String collectionPath,
    required Map<String, dynamic> data,
    required SyncOperation operation,
  });
}

class GoalLocalDatasourceImpl implements GoalLocalDatasource {
  GoalLocalDatasourceImpl(this._db);
  final AppDatabase _db;

  @override
  Future<List<GoalEntity>> loadGoals() async {
    final goals =
        await (_db.select(_db.goals)..orderBy([
              (g) => OrderingTerm(
                expression: g.createdAt,
                mode: OrderingMode.desc,
              ),
            ]))
            .get();

    return Future.wait(
      goals.map((goal) async {
        // savedAmount = SUM amount dari transaksi income yang dikaitkan ke goal ini
        final sumExp = _db.transactions.amount.sum();
        final query = _db.selectOnly(_db.transactions)
          ..addColumns([sumExp])
          ..where(
            _db.transactions.goalId.equals(goal.id) &
                _db.transactions.amount.isBiggerThanValue(0),
          );
        final savedAmount = await query
            .map((row) => row.read(sumExp) ?? 0)
            .getSingle();

        return GoalEntity(
          id: goal.id,
          title: goal.title,
          targetAmount: goal.targetAmount,
          savedAmount: savedAmount,
          targetDate: goal.targetDate,
          isCompleted: goal.isCompleted,
          createdAt: goal.createdAt,
        );
      }),
    );
  }

  static const _uuid = Uuid();

  @override
  Future<GoalModel> createGoal({
    required String title,
    required int targetAmount,
    required DateTime targetDate,
  }) async {
    final now = DateTime.now();
    final firestoreId = _uuid.v4();
    await _db
        .into(_db.goals)
        .insert(
          GoalsCompanion(
            title: Value(title),
            targetAmount: Value(targetAmount),
            targetDate: Value(targetDate),
            isCompleted: const Value(false),
            createdAt: Value(now),
            updatedAt: Value(now),
            firestoreId: Value(firestoreId),
          ),
        );
    return GoalModel(
      firestoreId: firestoreId,
      title: title,
      targetAmount: targetAmount,
      targetDate: targetDate,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> linkTransaction({required String txId, required int goalId}) =>
      (_db.update(_db.transactions)..where((t) => t.txId.equals(txId))).write(
        TransactionsCompanion(goalId: Value(goalId)),
      );

  @override
  Future<void> unlinkTransaction(String txId) =>
      (_db.update(_db.transactions)..where((t) => t.txId.equals(txId))).write(
        const TransactionsCompanion(goalId: Value(null)),
      );

  @override
  Future<void> completeGoal(int goalId) =>
      (_db.update(_db.goals)..where((g) => g.id.equals(goalId))).write(
        GoalsCompanion(
          isCompleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );

  @override
  Future<void> deleteGoal(int goalId) async {
    // Unlink semua transaksi yang terkait dulu
    await (_db.update(_db.transactions)..where((t) => t.goalId.equals(goalId)))
        .write(const TransactionsCompanion(goalId: Value(null)));
    // Hapus goal
    await (_db.delete(_db.goals)..where((g) => g.id.equals(goalId))).go();
  }

  @override
  Future<GoalModel?> findById(int goalId) async {
    final row = await (_db.select(
      _db.goals,
    )..where((g) => g.id.equals(goalId))).getSingleOrNull();
    return row == null ? null : GoalModel.fromRow(row);
  }

  @override
  Future<String?> firestoreIdOf(int goalId) async {
    final row = await (_db.select(
      _db.goals,
    )..where((g) => g.id.equals(goalId))).getSingleOrNull();
    return row?.firestoreId;
  }

  @override
  Future<bool> hasAnyGoals() async {
    final row = await (_db.select(_db.goals)..limit(1)).getSingleOrNull();
    return row != null;
  }

  @override
  Future<void> upsertFromRemote(List<GoalModel> models) async {
    await _db.transaction(() async {
      for (final model in models) {
        final existing =
            await (_db.select(_db.goals)
                  ..where((g) => g.firestoreId.equals(model.firestoreId)))
                .getSingleOrNull();
        if (existing == null) {
          await _db.into(_db.goals).insert(model.toCompanion());
        }
      }
    });
  }

  @override
  Future<void> addToSyncQueue({
    required String itemId,
    required String collectionPath,
    required Map<String, dynamic> data,
    required SyncOperation operation,
  }) async {
    await _db
        .into(_db.syncQueue)
        .insert(
          SyncQueueCompanion(
            itemId: Value(itemId),
            collectionPath: Value(collectionPath),
            data: Value(jsonEncode(data)),
            operation: Value(operation),
            createdAt: Value(DateTime.now()),
          ),
        );
  }
}
