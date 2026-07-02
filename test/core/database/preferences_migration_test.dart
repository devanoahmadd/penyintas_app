import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

// DB v9 nyata punya tabel categories (dibuat di from<7, +icon_slug di from<8).
// Fixture wajib memuatnya agar migrasi 9→12 (yang kini re-seed categories di
// from<12) tidak gagal "no such table: categories".
const _createCategoriesV9 = '''
  CREATE TABLE categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT, slug TEXT NOT NULL,
    label_key TEXT, label_override TEXT,
    is_built_in INTEGER NOT NULL DEFAULT 1,
    is_limitable INTEGER NOT NULL DEFAULT 0,
    type TEXT NOT NULL DEFAULT 'expense',
    sort_order INTEGER NOT NULL DEFAULT 0, icon_slug TEXT,
    UNIQUE(slug)
  )
''';

void main() {
  test('migrasi 9→10: buat tabel preferences + copy locale dari app_settings', () async {
    final raw = sqlite3.openInMemory();
    raw.execute('PRAGMA user_version = 9');
    raw.execute(
      "CREATE TABLE app_settings (id INTEGER PRIMARY KEY, locale TEXT NOT NULL DEFAULT 'id')",
    );
    raw.execute(_createCategoriesV9);
    raw.execute("INSERT INTO app_settings (id, locale) VALUES (1, 'en')");

    final db = AppDatabase(NativeDatabase.opened(raw));
    final row = await (db.select(db.preferences)..where((t) => t.id.equals(1)))
        .getSingleOrNull();

    expect(row, isNotNull);
    expect(row!.language, 'en');
    expect(row.timezone, 'Asia/Jakarta');
    expect(row.baseCurrency, 'IDR');
    expect(row.profileCompleted, false);

    await db.close();
  });

  test('migrasi 9→10: locale liar di-CLAMP ke id (C5)', () async {
    final raw = sqlite3.openInMemory();
    raw.execute('PRAGMA user_version = 9');
    raw.execute(
      "CREATE TABLE app_settings (id INTEGER PRIMARY KEY, locale TEXT NOT NULL DEFAULT 'id')",
    );
    raw.execute(_createCategoriesV9);
    raw.execute("INSERT INTO app_settings (id, locale) VALUES (1, 'fr')");

    final db = AppDatabase(NativeDatabase.opened(raw));
    final row = await (db.select(db.preferences)..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    expect(row!.language, 'id');
    await db.close();
  });

  test('migrasi 9→10: app_settings TANPA row → defensive-seed singleton tetap ada', () async {
    // DB v9 dengan tabel app_settings dibuat tapi KOSONG (mis. data ter-truncate).
    // INSERT...SELECT tak menghasilkan baris → cabang defensive INSERT OR IGNORE
    // (id) VALUES (1) wajib tetap menjamin row singleton ada dengan default 'id'.
    final raw = sqlite3.openInMemory();
    raw.execute('PRAGMA user_version = 9');
    raw.execute(
      "CREATE TABLE app_settings (id INTEGER PRIMARY KEY, locale TEXT NOT NULL DEFAULT 'id')",
    );
    raw.execute(_createCategoriesV9);
    // sengaja TIDAK INSERT row app_settings

    final db = AppDatabase(NativeDatabase.opened(raw));
    final row = await (db.select(db.preferences)..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    expect(row, isNotNull, reason: 'defensive seed wajib jamin singleton id=1');
    expect(row!.language, 'id'); // default, bukan dari app_settings (kosong)
    expect(row.baseCurrency, 'IDR');
    expect(row.profileCompleted, false);
    await db.close();
  });

  test('fresh install (onCreate): row preferences ter-SEED otomatis (C2)', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final row = await (db.select(db.preferences)..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    expect(row, isNotNull, reason: 'onCreate wajib seed singleton row id=1');
    expect(row!.language, 'id');
    expect(row.baseCurrency, 'IDR');
    expect(row.profileCompleted, false);
    await db.close();
  });

  test('clearAllLocalData: PERTAHANKAN language, reset sisanya (logout UX)', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.into(db.preferences).insertOnConflictUpdate(PreferencesCompanion(
          id: const Value(1),
          language: const Value('en'),
          displayName: const Value('Devano'),
          currentCountry: const Value('RU'),
          profileCompleted: const Value(true),
        ));
    await db.clearAllLocalData();
    final row = await (db.select(db.preferences)..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    expect(row, isNotNull);
    expect(row!.language, 'en');
    expect(row.displayName, isNull);
    expect(row.profileCompleted, false);
    expect(row.currentCountry, 'ID');
    await db.close();
  });
}
