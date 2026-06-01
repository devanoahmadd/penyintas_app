import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/database/app_database.dart';

AppDatabase _openTestDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;

  setUp(() => db = _openTestDb());
  tearDown(() => db.close());

  test('clearAllLocalData menghapus semua baris di semua tabel', () async {
    await db.into(db.appSettings).insert(
          const AppSettingsCompanion(id: Value(1)),
        );
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
          txId: 'tx-1',
          amount: 1000,
          category: 'food',
          type: 'expense',
          date: DateTime(2026, 6, 1),
          createdAt: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 6, 1),
        ));
    await db.into(db.goals).insert(GoalsCompanion.insert(
          title: 'Laptop',
          targetAmount: 5000000,
          targetDate: DateTime(2026, 12, 1),
          createdAt: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 6, 1),
        ));
    await db.into(db.budgetLimits).insert(BudgetLimitsCompanion.insert(
          category: 'food',
          limitAmount: 500000,
          updatedAt: DateTime(2026, 6, 1),
        ));
    await db.into(db.syncQueue).insert(SyncQueueCompanion.insert(
          itemId: 'i-1',
          collectionPath: 'users/{uid}/x',
          data: '{}',
          operation: SyncOperation.create,
          createdAt: DateTime(2026, 6, 1),
        ));

    await db.clearAllLocalData();

    expect(await db.select(db.appSettings).get(), isEmpty);
    expect(await db.select(db.transactions).get(), isEmpty);
    expect(await db.select(db.goals).get(), isEmpty);
    expect(await db.select(db.budgetLimits).get(), isEmpty);
    expect(await db.select(db.syncQueue).get(), isEmpty);
  });
}
