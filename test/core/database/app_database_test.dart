import 'package:drift/drift.dart' hide isNull, isNotNull;
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
      // DB v8 nyata SELALU punya tabel categories (dibuat di from<7, +icon_slug
      // di from<8). Fixture wajib memuatnya agar migrasi 8→12 (yang kini re-seed
      // categories di from<12) tidak gagal "no such table".
      raw.execute('''
        CREATE TABLE categories (
          id             INTEGER PRIMARY KEY AUTOINCREMENT,
          slug           TEXT NOT NULL,
          label_key      TEXT,
          label_override TEXT,
          is_built_in    INTEGER NOT NULL DEFAULT 1,
          is_limitable   INTEGER NOT NULL DEFAULT 0,
          type           TEXT NOT NULL DEFAULT 'expense',
          sort_order     INTEGER NOT NULL DEFAULT 0,
          icon_slug      TEXT,
          UNIQUE(slug)
        )
      ''');
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

  group('seed kategori built-in', () {
    test('fresh install (onCreate) men-seed 8 kategori built-in', () async {
      // Fresh in-memory DB → onCreate berjalan saat query pertama.
      final cats = await db.select(db.categories).get();

      expect(cats, hasLength(8),
          reason: 'onCreate harus men-seed 8 kategori built-in — '
              'tanpa ini fresh install punya tabel categories kosong');

      final slugs = cats.map((c) => c.slug).toSet();
      expect(
        slugs,
        {'food', 'transport', 'shopping', 'health', 'internet', 'other',
            'fixed', 'income'},
      );

      // 6 kategori expense limitable; 'fixed' & 'income' tidak limitable.
      final limitable = cats.where((c) => c.isLimitable).map((c) => c.slug);
      expect(limitable, hasLength(6));
      expect(limitable, isNot(contains('fixed')));
      expect(limitable, isNot(contains('income')));

      // Semua seed adalah built-in.
      expect(cats.every((c) => c.isBuiltIn), isTrue);
      // 'income' bertipe income; sisanya expense.
      final income = cats.firstWhere((c) => c.slug == 'income');
      expect(income.type, 'income');
    });
  });

  group('migrasi v11→v12 (heal categories kosong)', () {
    // Skema categories persis bentuk v11 (8 kolom v7 + icon_slug dari v8).
    const createV11Categories = '''
      CREATE TABLE categories (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        slug           TEXT NOT NULL,
        label_key      TEXT,
        label_override TEXT,
        is_built_in    INTEGER NOT NULL DEFAULT 1,
        is_limitable   INTEGER NOT NULL DEFAULT 0,
        type           TEXT NOT NULL DEFAULT 'expense',
        sort_order     INTEGER NOT NULL DEFAULT 0,
        icon_slug      TEXT,
        UNIQUE(slug)
      )
    ''';

    test('upgrade men-seed built-in ke DB v11 yang categories-nya kosong',
        () async {
      final raw = sqlite3.openInMemory();
      raw.execute(createV11Categories);
      raw.execute('PRAGMA user_version = 11');

      // Buka AppDatabase di atas DB v11 → migrasi 11→12 re-seed kategori.
      final migrated = AppDatabase(NativeDatabase.opened(raw));
      addTearDown(migrated.close);

      final cats = await migrated.select(migrated.categories).get();
      expect(cats, hasLength(8),
          reason: 'migrasi from<12 harus men-seed built-in untuk '
              'menyembuhkan fresh install lama yang terlanjur kosong');
      expect(
        cats.map((c) => c.slug).toSet(),
        {'food', 'transport', 'shopping', 'health', 'internet', 'other',
            'fixed', 'income'},
      );
    });

    test('re-seed idempoten — kategori built-in yang sudah ada tidak dobel',
        () async {
      final raw = sqlite3.openInMemory();
      raw.execute(createV11Categories);
      // Sudah ada 'food' (kasus DB yang seed-nya jalan via jalur onUpgrade<7).
      raw.execute(
        "INSERT INTO categories (slug, label_key, is_built_in, is_limitable, "
        "type, sort_order) VALUES ('food','category_food',1,1,'expense',0)",
      );
      raw.execute('PRAGMA user_version = 11');

      final migrated = AppDatabase(NativeDatabase.opened(raw));
      addTearDown(migrated.close);

      final cats = await migrated.select(migrated.categories).get();
      // Tetap 8 (bukan 9) — INSERT OR IGNORE tidak menduplikasi 'food'.
      expect(cats, hasLength(8));
      expect(cats.where((c) => c.slug == 'food'), hasLength(1));
    });
  });
}
