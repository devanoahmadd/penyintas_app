import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_cycle.dart';

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

class BudgetCycleConverter extends TypeConverter<BudgetCycle, String> {
  const BudgetCycleConverter();
  @override
  BudgetCycle fromSql(String s) {
    // Fallback ke BudgetCycle.cycle jika nilai DB tidak dikenal (data lama /
    // korup) agar app tidak crash. Lebih aman daripada byName() yang throw.
    return BudgetCycle.values.where((e) => e.name == s).firstOrNull ??
        BudgetCycle.cycle;
  }
  @override
  String toSql(BudgetCycle v) => v.name;
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

/// Kategori transaksi — built-in dan custom buatan user.
/// Built-in: label via labelKey (l10n). Custom: label via labelOverride.
/// Icon dan warna tidak disimpan di DB — lihat CategoryMetadata di Dart.
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get slug => text()(); // unique key: matches TransactionCategory.name for built-in
  TextColumn get labelKey => text().nullable()(); // l10n key (mis. 'category_food')
  TextColumn get labelOverride => text().nullable()(); // nama custom buatan user
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(true))();
  BoolColumn get isLimitable => boolean().withDefault(const Constant(false))();
  TextColumn get type => text().withDefault(const Constant('expense'))(); // 'expense' | 'income'
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {slug},
      ];
}

class BudgetLimits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get category => text()();
  IntColumn get limitAmount => integer()();
  // TypeConverter: stored as TEXT ('cycle'/'monthly'), mapped ke BudgetCycle enum.
  // Tidak perlu SQL migration — nilai lama sudah sesuai dengan nama enum.
  // Return type tetap TextColumn (Drift pattern, lihat SyncQueue.operation).
  TextColumn get cycleType => text()
      .withDefault(const Constant('cycle'))
      .map(const BudgetCycleConverter())();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime()();
}

// ─── Database ──────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [AppSettings, SyncQueue, Transactions, Goals, BudgetLimits, Categories])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 7;

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
      if (from < 5) {
        await m.database.customStatement('''
          CREATE TABLE IF NOT EXISTS budget_limits (
            id           INTEGER PRIMARY KEY AUTOINCREMENT,
            category     TEXT NOT NULL,
            limit_amount INTEGER NOT NULL,
            cycle_type   TEXT NOT NULL DEFAULT 'cycle',
            is_enabled   INTEGER NOT NULL DEFAULT 1,
            updated_at   INTEGER NOT NULL
          )
        ''');
      }
      if (from < 6) {
        // BudgetCycleConverter ditambahkan — TypeConverter adalah Dart-level.
        // SQL schema (TEXT) tidak berubah; nilai lama 'cycle'/'monthly' sudah
        // sesuai dengan BudgetCycle.values.byName(). Tidak ada SQL yang diperlukan.
      }
      if (from < 7) {
        // Backward compat: rename kategori lama yang sudah tidak dipakai
        await m.database.customStatement(
          "UPDATE transactions SET category = 'internet' WHERE category = 'data'",
        );
        await m.database.customStatement(
          "UPDATE transactions SET category = 'other' WHERE category = 'campus'",
        );

        // Tabel Categories baru — built-in seed di bawah
        await m.database.customStatement('''
          CREATE TABLE IF NOT EXISTS categories (
            id            INTEGER PRIMARY KEY AUTOINCREMENT,
            slug          TEXT NOT NULL,
            label_key     TEXT,
            label_override TEXT,
            is_built_in   INTEGER NOT NULL DEFAULT 1,
            is_limitable  INTEGER NOT NULL DEFAULT 0,
            type          TEXT NOT NULL DEFAULT 'expense',
            sort_order    INTEGER NOT NULL DEFAULT 0,
            UNIQUE(slug)
          )
        ''');

        // Seed 8 built-in categories (INSERT OR IGNORE agar aman dijalankan ulang)
        const seeds = [
          "(NULL,'food',    'category_food',     NULL, 1, 1, 'expense', 0)",
          "(NULL,'transport','category_transport',NULL, 1, 1, 'expense', 1)",
          "(NULL,'shopping','category_shopping',  NULL, 1, 1, 'expense', 2)",
          "(NULL,'health',  'category_health',    NULL, 1, 1, 'expense', 3)",
          "(NULL,'internet','category_internet',  NULL, 1, 1, 'expense', 4)",
          "(NULL,'other',   'category_other',     NULL, 1, 1, 'expense', 5)",
          "(NULL,'fixed',   'category_fixed',     NULL, 1, 0, 'expense', 6)",
          "(NULL,'income',  'category_income',    NULL, 1, 0, 'income',  7)",
        ];
        for (final row in seeds) {
          await m.database.customStatement(
            'INSERT OR IGNORE INTO categories VALUES $row',
          );
        }
      }
    },
  );

  /// Wipe semua data lokal (logout flow). Menghapus semua baris di semua tabel dan
  /// menjalankan VACUUM untuk reclaim disk space.
  Future<void> clearAllLocalData() async {
    await transaction(() async {
      await delete(goals).go();
      await delete(transactions).go();
      await delete(budgetLimits).go();
      await delete(syncQueue).go();
      await delete(appSettings).go();
      // Hapus hanya custom kategori; built-in akan di-seed ulang saat onboarding
      await (delete(categories)..where((c) => c.isBuiltIn.not())).go();
    });
    await customStatement('VACUUM');
  }
}

QueryExecutor _openConnection() => driftDatabase(name: 'penyintas_db');
