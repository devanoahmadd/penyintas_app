import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

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

  group('migrasi v8→v9 (#234)', () {
    // Skema app_settings persis bentuk v8 (semua kolom KECUALI dua partial).
    const createV8 = '''
      CREATE TABLE app_settings (
        id INTEGER NOT NULL PRIMARY KEY,
        locale TEXT NOT NULL DEFAULT 'id',
        theme_mode TEXT NOT NULL DEFAULT 'system',
        onboarding_completed INTEGER NOT NULL DEFAULT 0,
        monthly_income INTEGER NOT NULL DEFAULT 0,
        payment_date INTEGER NOT NULL DEFAULT 1,
        fixed_expenses INTEGER NOT NULL DEFAULT 0,
        emergency_fund_pct REAL NOT NULL DEFAULT 0.10,
        onboarding_created_at INTEGER,
        reminder_enabled INTEGER NOT NULL DEFAULT 1,
        reminder_hour INTEGER NOT NULL DEFAULT 20,
        reminder_minute INTEGER NOT NULL DEFAULT 0,
        rent_expense INTEGER NOT NULL DEFAULT 0,
        utilities_expense INTEGER NOT NULL DEFAULT 0,
        internet_expense INTEGER NOT NULL DEFAULT 0,
        phone_expense INTEGER NOT NULL DEFAULT 0,
        other_fixed_expense INTEGER NOT NULL DEFAULT 0,
        survival_mode_activated_at INTEGER
      )
    ''';

    test('upgrade menambah kolom partial (NULL) & mempertahankan data budget',
        () async {
      final raw = sqlite3.openInMemory();
      raw.execute(createV8);
      raw.execute(
        'INSERT INTO app_settings '
        '(id, monthly_income, payment_date, fixed_expenses, rent_expense, '
        'onboarding_completed) '
        'VALUES (1, 3000000, 25, 1000000, 1000000, 1)',
      );
      raw.execute('PRAGMA user_version = 8');

      // Membuka AppDatabase di atas DB v8 → migrasi 8→9 berjalan saat query.
      final migrated = AppDatabase(NativeDatabase.opened(raw));
      addTearDown(migrated.close);

      final row = await (migrated.select(migrated.appSettings)
            ..where((t) => t.id.equals(1)))
          .getSingleOrNull();

      expect(row, isNotNull);
      // Data existing v8 TIDAK hilang saat upgrade.
      expect(row!.monthlyIncome, 3000000);
      expect(row.paymentDate, 25);
      expect(row.rentExpense, 1000000);
      expect(row.onboardingCompleted, true);
      // Kolom baru v9 ADA & NULL (bukan crash NOT NULL).
      // Kalau migrasi tak jalan, baca kolom ini akan throw "no such column".
      expect(row.partialOnboardingStep, isNull);
      expect(row.partialOnboardingAt, isNull);
    });
  });
}
