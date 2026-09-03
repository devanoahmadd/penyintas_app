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
  RealColumn get emergencyFundPct => real().withDefault(const Constant(0.10))();
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
  // Partial onboarding state — untuk fitur "Lanjut nanti" (schemaVersion 9)
  IntColumn get partialOnboardingStep => integer().nullable()();
  IntColumn get partialOnboardingAt => integer().nullable()(); // epoch millis
  // Pengingat tagihan (A1 Tagihan, schemaVersion 14) — berapa hari sebelum
  // jatuh tempo notifikasi dikirim, dan jam berapa (24h, waktu lokal device).
  IntColumn get billReminderDaysBefore =>
      integer().withDefault(const Constant(1))();
  IntColumn get billReminderHour => integer().withDefault(const Constant(9))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Queue untuk operasi yang belum tersync ke Firestore.
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get itemId => text()();
  TextColumn get collectionPath => text()();
  TextColumn get data => text()();
  TextColumn get operation => text().map(const SyncOperationConverter())();
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
  // Link balik ke tagihan asal (nullable) — transaksi hasil "Tandai Lunas"
  // tagihan (A1 Tagihan, schemaVersion 14).
  IntColumn get sourceBillId => integer().nullable()();

  @override
  Set<Column> get primaryKey => {txId};
}

/// Tujuan tabungan pengguna.
class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  IntColumn get targetAmount => integer()();
  DateTimeColumn get targetDate => dateTime()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  // Identitas cloud stabil = doc ID Firestore (B1 goal sync, schemaVersion 13).
  // Nullable di SQL (ALTER TABLE tabel berisi data); setelah backfill migrasi
  // 12→13 SELALU terisi — baris baru diisi UUID v4 oleh GoalLocalDatasource.
  // Unik via index idx_goals_firestore_id (dibuat onCreate & onUpgrade).
  TextColumn get firestoreId => text().nullable()();
}

/// Kategori transaksi — built-in dan custom buatan user.
/// Built-in: label via labelKey (l10n). Custom: label via labelOverride.
/// iconSlug disimpan di DB untuk custom kategori (null = built-in, gunakan CategoryMetadata).
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get slug => text()(); // unique key for category identifier
  TextColumn get labelKey =>
      text().nullable()(); // l10n key (mis. 'category_food')
  TextColumn get labelOverride =>
      text().nullable()(); // nama custom buatan user
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(true))();
  BoolColumn get isLimitable => boolean().withDefault(const Constant(false))();
  TextColumn get type =>
      text().withDefault(const Constant('expense'))(); // 'expense' | 'income'
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get iconSlug => text().nullable()(); // null=built-in, diisi=custom

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

/// Singleton (id selalu = 1). Preferences: timezone, currency, language, profil.
/// Currency Spec 1 = IDR-seragam (base/home tak diubah user); UX currency → Spec 2.
class Preferences extends Table {
  IntColumn get id => integer()();
  TextColumn get timezone =>
      text().withDefault(const Constant('Asia/Jakarta'))();
  TextColumn get baseCurrency => text().withDefault(const Constant('IDR'))();
  TextColumn get homeCurrency => text().withDefault(const Constant('IDR'))();
  TextColumn get language => text().withDefault(const Constant('id'))();
  TextColumn get displayName => text().nullable()();
  TextColumn get status => text().nullable()();
  TextColumn get currentCountry => text().withDefault(const Constant('ID'))();
  TextColumn get currentCity => text().nullable()();
  TextColumn get homeCountry => text().withDefault(const Constant('ID'))();
  TextColumn get homeCity => text().nullable()();
  BoolColumn get isPerantau => boolean().withDefault(const Constant(false))();
  BoolColumn get profileCompleted =>
      boolean().withDefault(const Constant(false))();
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();
  // Sengaja belum ditulis siapa pun di Phase A1 ("kolom mati"). Diaktifkan di
  // Task A4/A6/D1 sebagai dirty-flag anti-clobber multi-device (temuan T-1).
  IntColumn get lastSyncedAtMs => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tagihan berulang (kos/listrik/wifi/cicilan) — A1 Tagihan (schemaVersion 14).
/// F1 ini HANYA schema; DAO/domain/UI dibangun di fase selanjutnya.
class Bills extends Table {
  IntColumn get id => integer().autoIncrement()();
  // Identitas cloud (doc ID Firestore) — nullable, diisi saat sinkron ke cloud.
  TextColumn get cloudId => text().nullable()();
  TextColumn get name => text()();
  IntColumn get estimatedAmount => integer()();
  TextColumn get category => text()();
  BoolColumn get isFixedNeed => boolean()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get dueDate => dateTime()();
  TextColumn get recurrence => text()();
  // Cicilan: total tenor & progres bayar. Null = bukan cicilan (tagihan biasa).
  IntColumn get installmentTotal => integer().nullable()();
  IntColumn get installmentsPaid => integer().withDefault(const Constant(0))();
  DateTimeColumn get recurrenceEndDate => dateTime().nullable()();
  IntColumn get dueDayOfMonth => integer().nullable()();
  IntColumn get reminderDaysBefore => integer().nullable()();
  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(true))();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Penanda "hari ini tidak ada pengeluaran" (A4 Konsistensi, schemaVersion 15).
///
/// BUKAN append-only: §4.3 spec memberi user undo di hari yang sama, dan undo
/// itu adalah DELETE baris — lokal maupun remote (jalur hapus di §6.2).
class StreakDayMarks extends Table {
  /// Tanggal lokal sebagai INT yyyymmdd (20260902) — bukan DateTime, supaya
  /// tak ada ambiguitas jam saat sinkron lintas device.
  IntColumn get dayKey => integer()();
  DateTimeColumn get markedAt => dateTime()(); // UTC — audit & merge
  TextColumn get timezone => text()(); // TZ device saat ditandai — audit
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  /// true bila baris ini tercipta saat hari device berada > 2 hari DI BAWAH
  /// [StreakMeta.maxSeenDay] (spec §4.7). Dikecualikan dari replay dan
  /// TIDAK PERNAH disinkronkan — baris TETAP ada secara lokal, tidak dihapus,
  /// tidak ada peringatan ke user.
  ///
  /// Pembandingnya `maxSeenDay`, BUKAN `lastSeenDay`: `lastSeenDay` sudah
  /// diturunkan StreakBloc saat snapshot dihitung — jauh sebelum user sempat
  /// menekan tombol — sehingga membandingkannya selalu memberi nol.
  BoolColumn get viaClockCorrection =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {dayKey};
}

/// Baris tunggal (id = 1) untuk hal yang tidak bisa diturunkan sama sekali.
///
/// SELURUH isinya boleh hilang tanpa merusak streak — `clearAllLocalData()`
/// menyapunya saat logout dan TIDAK membuatnya ulang, jadi setiap pembaca
/// wajib tahan baris kosong (lihat StreakLocalDatasource.readMeta).
class StreakMeta extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get lastSeenDay => integer().withDefault(const Constant(0))();

  /// Hari tertinggi yang PERNAH dilihat. Hanya naik, tidak pernah diturunkan
  /// oleh cabang koreksi jam. Tugasnya TUNGGAL: mendeteksi penandaan yang
  /// dibuat saat jam device mundur jauh. Ia tidak pernah memblokir apa pun.
  IntColumn get maxSeenDay => integer().withDefault(const Constant(0))();
  IntColumn get lastCelebratedRuas =>
      integer().withDefault(const Constant(0))();
  IntColumn get clockAnomalyCount => integer().withDefault(const Constant(0))();

  /// dayKey putusnya ruas yang sudah pernah diakui user. 0 = belum ada.
  IntColumn get acknowledgedBreakDay =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Database ──────────────────────────────────────────────────────────────────

@DriftDatabase(
  tables: [
    AppSettings,
    SyncQueue,
    Transactions,
    Goals,
    BudgetLimits,
    Categories,
    Preferences,
    Bills,
    StreakDayMarks,
    StreakMeta,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 15;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // Seed singleton preferences (id=1) agar row SELALU ada di fresh install
      // maupun jalur upgrade (INSERT OR IGNORE di if (from < 10)).
      await m.database.customStatement(
        'INSERT OR IGNORE INTO preferences (id) VALUES (1)',
      );
      // Seed 8 kategori built-in di fresh install. Sebelumnya seed HANYA ada di
      // jalur onUpgrade (if (from < 7)), sehingga fresh install lewat onCreate
      // punya tabel categories kosong → tombol "Tambah batas kategori" dan
      // picker kategori transaksi ikut hilang (limitableCategories == []).
      await _seedBuiltInCategories();
      // Index unik firestore_id (B1): fresh install dapat guard yang sama
      // dengan jalur upgrade — pull remote tak boleh menduplikasi goal.
      await m.database.customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_goals_firestore_id ON goals (firestore_id)',
      );
      // Index bantu query watchActive (A1 Tagihan): filter status + sort due_date.
      await m.database.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_bills_status_due ON bills (status, due_date)',
      );
      // A4: baris singleton streak_meta + index tanggal transaksi — fresh
      // install harus mendapat keduanya, persis seperti jalur upgrade.
      // (Pelajaran seed kategori yang dulu hanya ada di jalur onUpgrade.)
      await m.database.customStatement(
        'INSERT OR IGNORE INTO streak_meta (id) VALUES (1)',
      );
      await m.database.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions (date)',
      );
    },
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
      if (from < 8) {
        // Fase 3C: tambah kolom iconSlug untuk custom kategori
        await m.database.customStatement(
          'ALTER TABLE categories ADD COLUMN icon_slug TEXT',
        );
      }
      if (from < 9) {
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN partial_onboarding_step INTEGER',
        );
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN partial_onboarding_at INTEGER',
        );
      }
      if (from < 10) {
        await m.database.customStatement('''
          CREATE TABLE IF NOT EXISTS preferences (
            id                INTEGER NOT NULL PRIMARY KEY,
            timezone          TEXT NOT NULL DEFAULT 'Asia/Jakarta',
            base_currency     TEXT NOT NULL DEFAULT 'IDR',
            home_currency     TEXT NOT NULL DEFAULT 'IDR',
            language          TEXT NOT NULL DEFAULT 'id',
            display_name      TEXT,
            status            TEXT,
            current_country   TEXT NOT NULL DEFAULT 'ID',
            current_city      TEXT,
            home_country      TEXT NOT NULL DEFAULT 'ID',
            home_city         TEXT,
            is_perantau       INTEGER NOT NULL DEFAULT 0,
            profile_completed INTEGER NOT NULL DEFAULT 0,
            schema_version    INTEGER NOT NULL DEFAULT 1,
            last_synced_at_ms INTEGER
          )
        ''');
        // SEED: salin locale dari app_settings, clamp ke nilai dikenal (C5).
        // Ini SEED sekali — bukan cutover canonical. app_settings.locale tetap
        // sumber kebenaran sampai Phase C (atomik: repoint app.dart + rewire
        // settings_bloc). Jangan rilis Phase A tanpa Phase C ke build user nyata.
        await m.database.customStatement('''
          INSERT OR IGNORE INTO preferences (id, language)
          SELECT 1,
                 CASE WHEN locale IN ('id','en') THEN locale ELSE 'id' END
          FROM app_settings WHERE id = 1
        ''');
        // Defensif: pastikan row singleton ada walau app_settings kosong
        await m.database.customStatement(
          'INSERT OR IGNORE INTO preferences (id) VALUES (1)',
        );
      }
      if (from < 11) {
        // C3 cutover anchor: mulai versi ini `preferences.language` = canonical
        // bahasa app (SettingsBloc baca dari sini, bukan app_settings.locale lagi).
        // Re-seed dari app_settings.locale (sumber lama, terbaru pra-cutover) agar
        // device yang sudah migrasi 9→10 lalu mengubah bahasa via SettingsBloc lama
        // tidak ter-flip bahasanya. CLAMP {id,en} (konsisten C5). Idempoten, sekali jalan.
        //
        // L2 (self-contained): jangan diam-diam bergantung pada Phase A men-seed row.
        // Pastikan singleton id=1 ADA dulu agar UPDATE di bawah tak pernah no-op —
        // no-op = read() jatuh ke default 'id' → bahasa user ter-flip. Idempoten.
        await m.database.customStatement(
          'INSERT OR IGNORE INTO preferences (id) VALUES (1)',
        );
        await m.database.customStatement('''
          UPDATE preferences
          SET language = (
            SELECT CASE WHEN s.locale IN ('id','en') THEN s.locale ELSE 'id' END
            FROM app_settings s WHERE s.id = 1
          )
          WHERE id = 1 AND EXISTS (SELECT 1 FROM app_settings WHERE id = 1)
        ''');
      }
      if (from < 12) {
        // Heal: device yang ter-create via onCreate pada skema 7–11 tak pernah
        // masuk blok if (from < 7), jadi tabel categories-nya kosong. Re-seed
        // idempoten (INSERT OR IGNORE) — takkan menduplikasi built-in yang sudah
        // ada (mis. dari jalur onUpgrade<7) maupun mengubah kategori custom user.
        await _seedBuiltInCategories();
      }
      if (from < 13) {
        // B1 goal cloud sync: identitas stabil goal ↔ dokumen Firestore.
        // Backfill baris lama dengan 32-hex random (setara UUID v4 tanpa dash,
        // valid sebagai Firestore doc ID) via randomblob — self-contained SQL,
        // tanpa loop Dart. Baris baru diisi UUID v4 oleh GoalLocalDatasource.
        await m.database.customStatement(
          'ALTER TABLE goals ADD COLUMN firestore_id TEXT',
        );
        await m.database.customStatement(
          'UPDATE goals SET firestore_id = lower(hex(randomblob(16))) '
          'WHERE firestore_id IS NULL',
        );
        await m.database.customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_goals_firestore_id ON goals (firestore_id)',
        );
      }
      if (from < 14) {
        // A1 Tagihan: tabel bills + link balik dari transaksi + setting
        // pengingat. Raw SQL — Drift typed createTable/addColumn tidak dipakai
        // di jalur upgrade (konsisten dengan pola migrasi sebelumnya).
        await m.database.customStatement('''
          CREATE TABLE IF NOT EXISTS bills (
            id                    INTEGER PRIMARY KEY AUTOINCREMENT,
            cloud_id              TEXT,
            name                  TEXT NOT NULL,
            estimated_amount      INTEGER NOT NULL,
            category              TEXT NOT NULL,
            is_fixed_need         INTEGER NOT NULL,
            notes                 TEXT,
            due_date              INTEGER NOT NULL,
            recurrence            TEXT NOT NULL,
            installment_total     INTEGER,
            installments_paid     INTEGER NOT NULL DEFAULT 0,
            recurrence_end_date   INTEGER,
            due_day_of_month      INTEGER,
            reminder_days_before  INTEGER,
            reminder_enabled      INTEGER NOT NULL DEFAULT 1,
            status                TEXT NOT NULL,
            created_at            INTEGER NOT NULL,
            updated_at            INTEGER NOT NULL
          )
        ''');
        await m.database.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_bills_status_due ON bills (status, due_date)',
        );
        await m.database.customStatement(
          'ALTER TABLE transactions ADD COLUMN source_bill_id INTEGER',
        );
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN bill_reminder_days_before INTEGER NOT NULL DEFAULT 1',
        );
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN bill_reminder_hour INTEGER NOT NULL DEFAULT 9',
        );
      }
      if (from < 15) {
        // A4 Konsistensi & Streak: dua tabel baru + index bantu untuk query
        // turunan hari-transaksi. Raw SQL, konsisten dengan pola from < 13
        // dan from < 14 di atas.
        await m.database.customStatement('''
          CREATE TABLE IF NOT EXISTS streak_day_marks (
            day_key               INTEGER NOT NULL PRIMARY KEY,
            marked_at             INTEGER NOT NULL,
            timezone              TEXT    NOT NULL,
            is_synced             INTEGER NOT NULL DEFAULT 0,
            via_clock_correction  INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await m.database.customStatement('''
          CREATE TABLE IF NOT EXISTS streak_meta (
            id                     INTEGER NOT NULL PRIMARY KEY,
            last_seen_day          INTEGER NOT NULL DEFAULT 0,
            max_seen_day           INTEGER NOT NULL DEFAULT 0,
            last_celebrated_ruas   INTEGER NOT NULL DEFAULT 0,
            clock_anomaly_count    INTEGER NOT NULL DEFAULT 0,
            acknowledged_break_day INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await m.database.customStatement(
          'INSERT OR IGNORE INTO streak_meta (id) VALUES (1)',
        );
        // Query turunan hari-transaksi memfilter transactions.date >= epoch.
        // Tanpa index ini ia jadi full scan pada tabel paling ramai di app.
        await m.database.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions (date)',
        );
      }
    },
  );

  /// Seed 8 kategori built-in secara idempoten. Dipakai di onCreate (fresh
  /// install) DAN migrasi from<12 (heal DB lama yang terlanjur kosong).
  ///
  /// Sengaja pakai companion typed + InsertMode.insertOrIgnore, BUKAN positional
  /// `INSERT ... VALUES (...)` seperti di blok from<7: pada onCreate/from<12
  /// tabel sudah punya kolom `icon_slug` (ditambah di from<8), jadi insert
  /// positional 8-nilai akan mismatch. Kunci unik `slug` membuat re-run aman.
  Future<void> _seedBuiltInCategories() async {
    final seeds = <CategoriesCompanion>[
      CategoriesCompanion.insert(
        slug: 'food',
        labelKey: const Value('category_food'),
        isLimitable: const Value(true),
        sortOrder: const Value(0),
      ),
      CategoriesCompanion.insert(
        slug: 'transport',
        labelKey: const Value('category_transport'),
        isLimitable: const Value(true),
        sortOrder: const Value(1),
      ),
      CategoriesCompanion.insert(
        slug: 'shopping',
        labelKey: const Value('category_shopping'),
        isLimitable: const Value(true),
        sortOrder: const Value(2),
      ),
      CategoriesCompanion.insert(
        slug: 'health',
        labelKey: const Value('category_health'),
        isLimitable: const Value(true),
        sortOrder: const Value(3),
      ),
      CategoriesCompanion.insert(
        slug: 'internet',
        labelKey: const Value('category_internet'),
        isLimitable: const Value(true),
        sortOrder: const Value(4),
      ),
      CategoriesCompanion.insert(
        slug: 'other',
        labelKey: const Value('category_other'),
        isLimitable: const Value(true),
        sortOrder: const Value(5),
      ),
      CategoriesCompanion.insert(
        slug: 'fixed',
        labelKey: const Value('category_fixed'),
        sortOrder: const Value(6),
      ),
      CategoriesCompanion.insert(
        slug: 'income',
        labelKey: const Value('category_income'),
        type: const Value('income'),
        sortOrder: const Value(7),
      ),
    ];
    await batch((b) {
      b.insertAll(categories, seeds, mode: InsertMode.insertOrIgnore);
    });
  }

  /// Wipe semua data lokal (logout & hapus akun), lalu VACUUM untuk reclaim
  /// disk space.
  ///
  /// Tak ada satu pun tabel di sini yang menyimpan pemiliknya (tak ada kolom
  /// `userId`), jadi fungsi ini adalah SATU-SATUNYA pembatas antar akun di
  /// device yang sama. Bolong satu tabel = data akun lama menyambut akun
  /// berikutnya yang login.
  ///
  /// Karena itu penghapusan menyapu [allTables] — daftar yang diturunkan Drift
  /// dari anotasi `@DriftDatabase` — bukan daftar tabel yang ditulis tangan.
  /// Daftar tangan sempat tertinggal saat tabel `bills` lahir di
  /// schemaVersion 14, dan tagihan pun bocor lintas akun. Dengan menyapu
  /// [allTables], tabel baru ikut terhapus secara bawaan; yang ingin
  /// dipertahankan harus dikecualikan secara sadar di bawah ini.
  Future<void> clearAllLocalData() async {
    await transaction(() async {
      // Bahasa itu preferensi device (dipilih sebelum login), bukan data akun.
      final keepLang =
          (await (select(
            preferences,
          )..where((t) => t.id.equals(1))).getSingleOrNull())?.language ??
          'id';

      for (final table in allTables) {
        // Kategori dikecualikan dari sapuan — ditangani terpisah di bawah
        // karena hanya sebagian barisnya yang milik akun.
        if (identical(table, categories)) continue;
        await delete(table).go();
      }

      // Kategori built-in adalah label bersama, bukan milik akun mana pun;
      // yang dihapus hanya kategori buatan pengguna.
      await (delete(categories)..where((c) => c.isBuiltIn.not())).go();

      // Baris singleton preferences (id=1) WAJIB selalu ada — ia baru saja
      // ikut tersapu, jadi dibuat ulang dengan bahasa yang dipertahankan.
      await into(preferences).insert(
        PreferencesCompanion(id: const Value(1), language: Value(keepLang)),
      );
    });
    await customStatement('VACUUM');
  }
}

QueryExecutor _openConnection() => driftDatabase(name: 'penyintas_db');
