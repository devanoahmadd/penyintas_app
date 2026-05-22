import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// ─── Enum ──────────────────────────────────────────────────────────────────────

enum SyncOperation { create, update, delete }

// ─── Type Converters ───────────────────────────────────────────────────────────

class SyncOperationConverter extends TypeConverter<SyncOperation, String> {
  const SyncOperationConverter();
  @override
  SyncOperation fromSql(String s) => SyncOperation.values.byName(s);
  @override
  String toSql(SyncOperation v) => v.name;
}

// ─── Tables ────────────────────────────────────────────────────────────────────

/// Singleton (id selalu = 1). Gabungan preferences + budget settings.
class AppSettings extends Table {
  IntColumn get id => integer()();
  TextColumn get locale => text().withDefault(const Constant('id'))();
  TextColumn get themeMode => text().withDefault(const Constant('system'))();
  BoolColumn get onboardingCompleted =>
      boolean().withDefault(const Constant(false))();
  IntColumn get monthlyIncome => integer().withDefault(const Constant(0))();
  IntColumn get paymentDate => integer().withDefault(const Constant(1))();
  IntColumn get fixedExpenses => integer().withDefault(const Constant(0))();
  RealColumn get emergencyFundPct =>
      real().withDefault(const Constant(0.10))();
  // Set once on first onboarding completion — jangan overwrite
  DateTimeColumn get onboardingCreatedAt => dateTime().nullable()();
  // Notification reminder settings (added schemaVersion 2)
  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(true))();
  IntColumn get reminderHour => integer().withDefault(const Constant(20))();
  IntColumn get reminderMinute => integer().withDefault(const Constant(0))();
  // Expense breakdown per kategori (added schemaVersion 3 — #40)
  IntColumn get rentExpense => integer().withDefault(const Constant(0))();
  IntColumn get utilitiesExpense => integer().withDefault(const Constant(0))();
  IntColumn get internetExpense => integer().withDefault(const Constant(0))();
  IntColumn get phoneExpense => integer().withDefault(const Constant(0))();
  IntColumn get otherFixedExpense => integer().withDefault(const Constant(0))();
  // Timestamp ketika Survival Mode aktif (null = tidak aktif) — schemaVersion 4
  DateTimeColumn get survivalModeActivatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Queue untuk operasi yang belum tersync ke Firestore.
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get itemId => text()();
  TextColumn get collectionPath => text()();
  TextColumn get data => text()();
  TextColumn get operation =>
      text().map(const SyncOperationConverter())();
  DateTimeColumn get createdAt => dateTime()();
}

/// Tabel transaksi. UUID sebagai primary key.
class Transactions extends Table {
  TextColumn get txId => text()();
  IntColumn get amount => integer()();
  TextColumn get category => text()();
  TextColumn get type => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get date => dateTime()();
  BoolColumn get isFixed => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  // Link ke tujuan tabungan (nullable) — schemaVersion 4
  IntColumn get goalId => integer().nullable()();

  @override
  Set<Column> get primaryKey => {txId};
}

/// Tujuan tabungan pengguna.
class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  IntColumn get targetAmount => integer()();
  DateTimeColumn get targetDate => dateTime()();
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

// ─── Database ──────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [AppSettings, SyncQueue, Transactions, Goals])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      // #138: enforce foreign key constraints — OFF by default in SQLite
      await customStatement('PRAGMA foreign_keys = ON');
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Drift type system tidak bisa assigni BoolColumn/IntColumn ke
        // GeneratedColumn<Object>, jadi pakai raw SQL untuk migration ini.
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN reminder_enabled INTEGER NOT NULL DEFAULT 1',
        );
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN reminder_hour INTEGER NOT NULL DEFAULT 20',
        );
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN reminder_minute INTEGER NOT NULL DEFAULT 0',
        );
      }
      if (from < 3) {
        // #40: expense breakdown per kategori
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN rent_expense INTEGER NOT NULL DEFAULT 0',
        );
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN utilities_expense INTEGER NOT NULL DEFAULT 0',
        );
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN internet_expense INTEGER NOT NULL DEFAULT 0',
        );
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN phone_expense INTEGER NOT NULL DEFAULT 0',
        );
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN other_fixed_expense INTEGER NOT NULL DEFAULT 0',
        );
        // Preserve existing fixedExpenses data — copy total ke otherFixedExpense
        await m.database.customStatement(
          'UPDATE app_settings SET other_fixed_expense = fixed_expenses',
        );
      }
      if (from < 4) {
        // Phase 7: Goals table + goalId di Transactions + survivalModeActivatedAt
        // Gunakan raw SQL — Drift typed addColumn tidak support nullable columns.
        await m.database.customStatement('''
          CREATE TABLE IF NOT EXISTS goals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            target_amount INTEGER NOT NULL,
            target_date INTEGER NOT NULL,
            is_completed INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await m.database.customStatement(
          'ALTER TABLE transactions ADD COLUMN goal_id INTEGER',
        );
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN survival_mode_activated_at INTEGER',
        );
      }
    },
  );
}

QueryExecutor _openConnection() => driftDatabase(name: 'penyintas_db');
