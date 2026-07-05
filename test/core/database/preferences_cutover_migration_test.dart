// test/core/database/preferences_cutover_migration_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

// Skema v10: app_settings (minimal — hanya kolom yg dibaca migrasi) + preferences (penuh,
// agar SELECT Drift pasca-buka tak gagal). Kita simulasikan DRIFT: app_settings.locale='en'
// tapi preferences.language='id' (user ganti bahasa via SettingsBloc lama sebelum cutover).
void _seedV10(Database raw, {required String appLocale, required String prefsLang}) {
  raw.execute('PRAGMA user_version = 10');
  raw.execute(
    "CREATE TABLE app_settings (id INTEGER PRIMARY KEY, locale TEXT NOT NULL DEFAULT 'id')",
  );
  // DB v10 nyata punya tabel categories (dibuat di from<7). Wajib ada agar
  // migrasi 10→12 (yang kini re-seed categories di from<12) tak gagal
  // "no such table: categories".
  raw.execute('''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT, slug TEXT NOT NULL,
      label_key TEXT, label_override TEXT,
      is_built_in INTEGER NOT NULL DEFAULT 1,
      is_limitable INTEGER NOT NULL DEFAULT 0,
      type TEXT NOT NULL DEFAULT 'expense',
      sort_order INTEGER NOT NULL DEFAULT 0, icon_slug TEXT,
      UNIQUE(slug)
    )
  ''');
  // DB v10 nyata punya tabel goals (dibuat di from<4). Wajib ada agar migrasi
  // 10→13 (yang kini ALTER goals di from<13) tak gagal "no such table: goals".
  raw.execute('''
    CREATE TABLE goals (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      target_amount INTEGER NOT NULL,
      target_date INTEGER NOT NULL,
      is_completed INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
  raw.execute(
    "INSERT INTO app_settings (id, locale) VALUES (1, '$appLocale')",
  );
  raw.execute('''
    CREATE TABLE preferences (
      id INTEGER NOT NULL PRIMARY KEY,
      timezone TEXT NOT NULL DEFAULT 'Asia/Jakarta',
      base_currency TEXT NOT NULL DEFAULT 'IDR',
      home_currency TEXT NOT NULL DEFAULT 'IDR',
      language TEXT NOT NULL DEFAULT 'id',
      display_name TEXT, status TEXT,
      current_country TEXT NOT NULL DEFAULT 'ID', current_city TEXT,
      home_country TEXT NOT NULL DEFAULT 'ID', home_city TEXT,
      is_perantau INTEGER NOT NULL DEFAULT 0,
      profile_completed INTEGER NOT NULL DEFAULT 0,
      schema_version INTEGER NOT NULL DEFAULT 1,
      last_synced_at_ms INTEGER
    )
  ''');
  raw.execute("INSERT INTO preferences (id, language) VALUES (1, '$prefsLang')");
}

void main() {
  test('migrasi 10→11: re-seed preferences.language dari app_settings.locale (cutover)', () async {
    final raw = sqlite3.openInMemory();
    _seedV10(raw, appLocale: 'en', prefsLang: 'id'); // DRIFT: app=en, prefs=id

    final db = AppDatabase(NativeDatabase.opened(raw)); // buka v11 → 10→11 jalan
    final row = await (db.select(db.preferences)..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    expect(row!.language, 'en', reason: 'language ter-re-seed dari app_settings.locale terbaru');
    await db.close();
  });

  test('migrasi 10→11: locale liar di app_settings di-CLAMP ke id', () async {
    final raw = sqlite3.openInMemory();
    _seedV10(raw, appLocale: 'fr', prefsLang: 'en'); // app_settings korup 'fr'

    final db = AppDatabase(NativeDatabase.opened(raw));
    final row = await (db.select(db.preferences)..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    expect(row!.language, 'id', reason: 'nilai liar tak boleh tersalin verbatim');
    await db.close();
  });

  test('migrasi 10→11: tanpa row app_settings → language preferences TAK berubah', () async {
    final raw = sqlite3.openInMemory();
    _seedV10(raw, appLocale: 'en', prefsLang: 'en');
    raw.execute('DELETE FROM app_settings'); // app_settings kosong (edge)

    final db = AppDatabase(NativeDatabase.opened(raw));
    final row = await (db.select(db.preferences)..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    expect(row!.language, 'en', reason: 'EXISTS-guard: tak meng-UPDATE jadi null/default');
    await db.close();
  });
}
