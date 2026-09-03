import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

// Bentuk MINIMAL skema v14 untuk migrasi 14→15. HANYA `transactions` yang
// perlu direplikasi: dari `from = 14` cuma blok `if (from < 15)` yang jalan,
// dan satu-satunya tabel lama yang disentuhnya adalah transactions (dapat
// index baru). `beforeOpen` di app_database.dart hanya menyetel
// `PRAGMA foreign_keys` — ia tidak menyentuh tabel mana pun, jadi fixture
// sesempit ini aman. (Bandingkan bills_schema_migration_test.dart yang
// mereplikasi tiga tabel karena migrasi 13→14 memang menyentuh ketiganya.)
const _createTransactionsV14 = '''
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
    goal_id INTEGER,
    source_bill_id INTEGER
  )
''';

void main() {
  late Database raw;
  late AppDatabase db;

  setUp(() {
    raw = sqlite3.openInMemory();
    raw.execute(_createTransactionsV14);
    raw.execute('PRAGMA user_version = 14');
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> openAtV15() async {
    db = AppDatabase(NativeDatabase.opened(raw));
    // Sentuh database agar migrasi benar-benar berjalan.
    await db.customSelect('SELECT 1').get();
  }

  test('migrasi 14→15 membuat streak_day_marks dengan kolom lengkap', () async {
    await openAtV15();
    final cols = raw
        .select("PRAGMA table_info('streak_day_marks')")
        .map((r) => r['name'] as String)
        .toSet();
    expect(
      cols,
      containsAll(<String>[
        'day_key',
        'marked_at',
        'timezone',
        'is_synced',
        'via_clock_correction',
      ]),
    );
  });

  test(
    'migrasi 14→15 membuat streak_meta berikut baris singleton id=1',
    () async {
      await openAtV15();
      final cols = raw
          .select("PRAGMA table_info('streak_meta')")
          .map((r) => r['name'] as String)
          .toSet();
      expect(
        cols,
        containsAll(<String>[
          'id',
          'last_seen_day',
          'max_seen_day',
          'last_celebrated_ruas',
          'clock_anomaly_count',
          'acknowledged_break_day',
        ]),
      );
      final rows = raw.select('SELECT id FROM streak_meta');
      expect(rows.length, 1, reason: 'baris singleton wajib di-seed migrasi');
      expect(rows.first['id'], 1);
    },
  );

  test('migrasi 14→15 membuat index idx_transactions_date', () async {
    await openAtV15();
    final idx = raw
        .select("SELECT name FROM sqlite_master WHERE type='index'")
        .map((r) => r['name'] as String)
        .toSet();
    expect(idx, contains('idx_transactions_date'));
  });

  test('fresh install (onCreate) mendapat seed & index yang sama', () async {
    final fresh = AppDatabase(NativeDatabase.memory());
    addTearDown(fresh.close);
    final metaCount = await fresh
        .customSelect('SELECT COUNT(*) AS c FROM streak_meta')
        .getSingle();
    expect(
      metaCount.data['c'],
      1,
      reason: 'pelajaran seed kategori: jalur onCreate sering luput',
    );
    final idx = await fresh
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='index' "
          "AND name='idx_transactions_date'",
        )
        .get();
    expect(idx, hasLength(1));
  });
}
