import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

// Bentuk tabel goals persis skema v12 (dibuat di migrasi from<4, tak pernah
// berubah sampai v12). DateTime drift = INTEGER unix-seconds.
const _createGoalsV12 = '''
  CREATE TABLE goals (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    target_amount INTEGER NOT NULL,
    target_date INTEGER NOT NULL,
    is_completed INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
''';

// DB nyata pra-v14 SELALU punya tabel transactions & app_settings (skema
// dasar sejak v1). Fixture yang menyeberang ke v14 wajib memuatnya agar
// migrasi from<14 (ALTER TABLE transactions/app_settings, A1 Tagihan) tak
// gagal "no such table" — pola yang sama seperti _createGoalsV12 di atas.
const _createTransactionsPreV14 = '''
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
const _createAppSettingsMinimal =
    'CREATE TABLE app_settings (id INTEGER PRIMARY KEY)';

void main() {
  test('migrasi 12→13: kolom firestore_id ditambah + backfill 32-hex unik', () async {
    final raw = sqlite3.openInMemory();
    raw.execute('PRAGMA user_version = 12');
    raw.execute(_createGoalsV12);
    raw.execute(_createTransactionsPreV14);
    raw.execute(_createAppSettingsMinimal);
    raw.execute(
      "INSERT INTO goals (title, target_amount, target_date, is_completed, created_at, updated_at) "
      "VALUES ('Pulang kampung', 1500000, 1798675200, 0, 1750000000, 1750000000)",
    );
    raw.execute(
      "INSERT INTO goals (title, target_amount, target_date, is_completed, created_at, updated_at) "
      "VALUES ('Laptop baru', 8000000, 1806537600, 0, 1750000000, 1750000000)",
    );

    final db = AppDatabase(NativeDatabase.opened(raw));
    final rows = await db.select(db.goals).get();

    expect(rows, hasLength(2));
    final ids = rows.map((r) => r.firestoreId).toList();
    // Backfill: 32 hex chars (randomblob), tidak null, unik antar-baris.
    for (final id in ids) {
      expect(id, isNotNull);
      expect(
        RegExp(r'^[0-9a-f]{32}$').hasMatch(id!),
        isTrue,
        reason: 'backfill harus 32-hex lowercase, dapat: $id',
      );
    }
    expect(ids.toSet().length, 2, reason: 'firestore_id wajib unik');
    // Data lama tidak berubah.
    expect(
      rows.map((r) => r.title),
      containsAll(['Pulang kampung', 'Laptop baru']),
    );
    await db.close();
  });

  test('migrasi 12→13: idempoten terhadap goals kosong', () async {
    final raw = sqlite3.openInMemory();
    raw.execute('PRAGMA user_version = 12');
    raw.execute(_createGoalsV12);
    raw.execute(_createTransactionsPreV14);
    raw.execute(_createAppSettingsMinimal);

    final db = AppDatabase(NativeDatabase.opened(raw));
    expect(await db.select(db.goals).get(), isEmpty); // tak melempar
    await db.close();
  });

  test('fresh install (onCreate): index unik firestore_id aktif', () async {
    final db = AppDatabase(NativeDatabase.memory());
    GoalsCompanion goal(String fid, String title) => GoalsCompanion.insert(
      title: title,
      targetAmount: 1000000,
      targetDate: DateTime(2026, 12, 31),
      createdAt: DateTime(2026, 7, 5),
      updatedAt: DateTime(2026, 7, 5),
      firestoreId: Value(fid),
    );
    await db.into(db.goals).insert(goal('fid-sama', 'Goal A'));
    await expectLater(
      db.into(db.goals).insert(goal('fid-sama', 'Goal B')),
      throwsA(anything),
      reason: 'firestore_id duplikat wajib ditolak index unik',
    );
    await db.close();
  });
}
