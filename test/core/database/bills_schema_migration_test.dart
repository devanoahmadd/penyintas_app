import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

// Bentuk tabel persis skema v13 (state SEBELUM migrasi Bills, F1 A1 Tagihan).
// Disalin dari struktur yang dibentuk migrasi lama (bukan definisi Drift saat
// ini) — lihat pola yang sama di goals_sync_migration_test.dart.
const _createTransactionsV13 = '''
  CREATE TABLE transactions (
    tx_id TEXT NOT NULL PRIMARY KEY,
    amount INTEGER NOT NULL,
    category TEXT NOT NULL,
    type TEXT NOT NULL,
    note TEXT,
    date INTEGER NOT NULL,
    is_fixed INTEGER NOT NULL DEFAULT 0,
    is_synced INTEGER NOT NULL DEFAULT 0,
    synced_at INTEGER,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    goal_id INTEGER
  )
''';

const _createAppSettingsV13 = '''
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
    survival_mode_activated_at INTEGER,
    partial_onboarding_step INTEGER,
    partial_onboarding_at INTEGER
  )
''';

const _createGoalsV13 = '''
  CREATE TABLE goals (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    target_amount INTEGER NOT NULL,
    target_date INTEGER NOT NULL,
    is_completed INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    firestore_id TEXT
  )
''';

void main() {
  test('migrasi 13→14: tabel bills + kolom baru ada, default benar', () async {
    final raw = sqlite3.openInMemory();
    raw.execute('PRAGMA user_version = 13');
    raw.execute(_createTransactionsV13);
    raw.execute(_createAppSettingsV13);
    raw.execute(_createGoalsV13);
    raw.execute(
      "INSERT INTO transactions "
      "(tx_id, amount, category, type, note, date, is_fixed, is_synced, synced_at, created_at, updated_at, goal_id) "
      "VALUES "
      "('tx-lama-1', 50000, 'food', 'expense', 'Makan siang', 1750000000, 0, 0, NULL, 1750000000, 1750000000, NULL)",
    );
    raw.execute('INSERT INTO app_settings (id) VALUES (1)');

    final db = AppDatabase(NativeDatabase.opened(raw));

    // Tabel bills baru harus bisa diquery tanpa error, dan kosong (belum ada
    // data lama untuk tagihan).
    final bills = await db.select(db.bills).get();
    expect(bills, isEmpty);

    // Baris transaksi lama tetap ada, sourceBillId (kolom baru) default null.
    final txs = await db.select(db.transactions).get();
    expect(txs, hasLength(1));
    expect(txs.single.txId, 'tx-lama-1');
    expect(txs.single.amount, 50000);
    expect(txs.single.sourceBillId, isNull);

    // Tulis eksplisit ke sourceBillId pada baris baru — round-trip ini WAJIB
    // menyentuh kolom fisik source_bill_id (bukan sekadar baca lenient yang
    // diam-diam default ke null bila kolom tak ada, lihat catatan anti-sabotase).
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            txId: 'tx-baru-terkait-bill',
            amount: 800000,
            category: 'fixed',
            type: 'expense',
            date: DateTime(2026, 7, 22),
            createdAt: DateTime(2026, 7, 22),
            updatedAt: DateTime(2026, 7, 22),
            sourceBillId: const Value(99),
          ),
        );
    final withBill = await (db.select(
      db.transactions,
    )..where((t) => t.txId.equals('tx-baru-terkait-bill'))).getSingle();
    expect(withBill.sourceBillId, 99);

    // Setting pengingat tagihan baru: default 1 hari sebelumnya, jam 9.
    final settings = await (db.select(
      db.appSettings,
    )..where((t) => t.id.equals(1))).getSingle();
    expect(settings.billReminderDaysBefore, 1);
    expect(settings.billReminderHour, 9);

    await db.close();
  });

  test('fresh install v14: bills insert & query jalan', () async {
    final db = AppDatabase(NativeDatabase.memory());

    await db
        .into(db.bills)
        .insert(
          BillsCompanion.insert(
            name: 'Kos Bulanan',
            estimatedAmount: 800000,
            category: 'rent',
            isFixedNeed: true,
            dueDate: DateTime(2026, 8, 5),
            recurrence: 'monthly',
            status: 'upcoming',
            createdAt: DateTime(2026, 7, 22),
            updatedAt: DateTime(2026, 7, 22),
          ),
        );

    final rows = await (db.select(
      db.bills,
    )..where((t) => t.status.equals('upcoming'))).get();
    expect(rows, hasLength(1));
    expect(rows.single.name, 'Kos Bulanan');
    // Default kolom yang tidak diisi eksplisit di insert().
    expect(rows.single.installmentsPaid, 0);
    expect(rows.single.reminderEnabled, isTrue);
    expect(rows.single.cloudId, isNull);

    // app_settings singleton: default billReminderHour == 9 bila di-seed.
    await db
        .into(db.appSettings)
        .insert(const AppSettingsCompanion(id: Value(1)));
    final settings = await (db.select(
      db.appSettings,
    )..where((t) => t.id.equals(1))).getSingle();
    expect(settings.billReminderHour, 9);
    expect(settings.billReminderDaysBefore, 1);

    await db.close();
  });
}
