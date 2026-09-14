import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:sqlite3/sqlite3.dart';

// Bentuk MINIMAL skema v15 untuk migrasi 15→16. Hanya `app_settings` yang perlu
// direplikasi: blok `if (from < 16)` menambah satu kolom di tabel itu dan
// membuat satu tabel baru. `beforeOpen` cuma menyetel PRAGMA foreign_keys.
const _createAppSettingsV15 = '''
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
    partial_onboarding_at INTEGER,
    bill_reminder_days_before INTEGER NOT NULL DEFAULT 1,
    bill_reminder_hour INTEGER NOT NULL DEFAULT 9
  )
''';

void main() {
  late Database raw;
  // NULLABLE dengan sengaja: test converter di bawah murni sinkron dan tidak
  // pernah membuka database. Kalau `db` `late`, tearDown-nya melempar
  // LateInitializationError dan test yang sebetulnya hijau ikut merah.
  AppDatabase? db;

  setUp(() {
    raw = sqlite3.openInMemory();
    raw.execute(_createAppSettingsV15);
    // Baris settings milik user lama — WAJIB selamat melewati migrasi.
    raw.execute(
      "INSERT INTO app_settings (id, monthly_income) VALUES (1, 3500000)",
    );
    raw.execute('PRAGMA user_version = 15');
  });

  tearDown(() async {
    if (db != null) {
      await db!.close(); // NativeDatabase.opened ikut menutup `raw`
    } else {
      raw.close(); // tak pernah dibuka Drift — tutup manual, jangan bocor
    }
    db = null;
  });

  Future<void> openAtV16() async {
    db = AppDatabase(NativeDatabase.opened(raw));
    await db!.customSelect('SELECT 1').get(); // sentuh agar migrasi jalan
  }

  test(
    'U32 · migrasi 15→16 membuat weekly_challenges dengan kolom lengkap',
    () async {
      await openAtV16();
      final cols = raw
          .select("PRAGMA table_info('weekly_challenges')")
          .map((r) => r['name'] as String)
          .toSet();
      expect(
        cols,
        containsAll(<String>[
          'week_key',
          'category',
          'target_amount',
          'baseline_amount',
          'status',
          'final_spent',
          'timezone',
          'created_at',
          'updated_at',
          'resolved_at',
          'result_seen_at',
          'is_synced',
        ]),
      );
      // Kolom milik CF yang ditunda TIDAK boleh ikut lahir di v16.
      expect(cols, isNot(contains('copy_request_count')));
      expect(cols, isNot(contains('ai_copy')));
    },
  );

  test(
    'U32 · migrasi 15→16 menambah challenge_enabled dengan default false',
    () async {
      await openAtV16();
      final row = raw
          .select("SELECT challenge_enabled FROM app_settings WHERE id = 1")
          .first;
      expect(row['challenge_enabled'], 0);
    },
  );

  test('U32 · data settings lama utuh setelah migrasi', () async {
    await openAtV16();
    final row = raw
        .select("SELECT monthly_income FROM app_settings WHERE id = 1")
        .first;
    expect(row['monthly_income'], 3500000);
  });

  test(
    'U35 · kolom category/target/baseline boleh NULL (baris held)',
    () async {
      await openAtV16();
      raw.execute('''
      INSERT INTO weekly_challenges
        (week_key, status, timezone, created_at, updated_at, is_synced)
      VALUES (20260907, 'held', 'WIB', 0, 0, 0)
    ''');
      final row = raw
          .select(
            'SELECT category, target_amount, baseline_amount '
            'FROM weekly_challenges WHERE week_key = 20260907',
          )
          .first;
      expect(row['category'], isNull);
      expect(row['target_amount'], isNull);
      expect(row['baseline_amount'], isNull);
    },
  );

  test(
    'U51 · status asing dari remote jadi unknown, converter TIDAK melempar',
    () {
      const konverter = ChallengeStatusConverter();
      expect(konverter.fromSql('paused_v17'), ChallengeStatus.unknown);
      expect(konverter.fromSql('achieved'), ChallengeStatus.achieved);
      expect(konverter.toSql(ChallengeStatus.held), 'held');
    },
  );
}
