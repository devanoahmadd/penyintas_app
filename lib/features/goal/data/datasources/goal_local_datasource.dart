import 'package:drift/drift.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/goal/domain/entities/goal_entity.dart';

abstract class GoalLocalDatasource {
  Future<List<GoalEntity>> loadGoals();
  Future<void> createGoal({
    required String title,
    required int targetAmount,
    required DateTime targetDate,
  });
  Future<void> linkTransaction({required String txId, required int goalId});
  Future<void> unlinkTransaction(String txId);
  Future<void> completeGoal(int goalId);
  Future<void> deleteGoal(int goalId);
}

class GoalLocalDatasourceImpl implements GoalLocalDatasource {
  GoalLocalDatasourceImpl(this._db);
  final AppDatabase _db;

  @override
  Future<List<GoalEntity>> loadGoals() async {
    final goals = await (_db.select(_db.goals)
          ..orderBy([(g) => OrderingTerm(expression: g.createdAt, mode: OrderingMode.desc)]))
        .get();

    return Future.wait(goals.map((goal) async {
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
    }));
  }

  @override
  Future<void> createGoal({
    required String title,
    required int targetAmount,
    required DateTime targetDate,
  }) {
    final now = DateTime.now();
    return _db.into(_db.goals).insert(GoalsCompanion(
          title: Value(title),
          targetAmount: Value(targetAmount),
          targetDate: Value(targetDate),
          isCompleted: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ));
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
    await (_db.update(_db.transactions)
          ..where((t) => t.goalId.equals(goalId)))
        .write(const TransactionsCompanion(goalId: Value(null)));
    // Hapus goal
    await (_db.delete(_db.goals)..where((g) => g.id.equals(goalId))).go();
  }
}
