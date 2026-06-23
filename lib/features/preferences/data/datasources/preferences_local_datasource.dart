import 'package:drift/drift.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/preferences/domain/entities/preferences_entity.dart';

abstract class PreferencesLocalDatasource {
  Future<PreferencesEntity?> read();
  Future<void> write(PreferencesEntity prefs);

  /// T-1: penanda sinkronisasi (pakai kolom `lastSyncedAtMs`).
  /// `true` = ada perubahan lokal yg mirror-nya belum terkonfirmasi sukses (dirty).
  Future<bool> hasPendingMirror();

  /// T-1: tandai local sudah ter-mirror sukses pada [atMs] (epoch ms) → clean.
  Future<void> markMirrored(int atMs);
}

class PreferencesLocalDatasourceImpl implements PreferencesLocalDatasource {
  PreferencesLocalDatasourceImpl(this._db);
  final AppDatabase _db;

  @override
  Future<PreferencesEntity?> read() async {
    final row = await (_db.select(_db.preferences)..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    if (row == null) return null;
    return PreferencesEntity(
      timezone: row.timezone,
      baseCurrency: row.baseCurrency,
      homeCurrency: row.homeCurrency,
      language: row.language,
      displayName: row.displayName,
      status: row.status,
      currentCountry: row.currentCountry,
      currentCity: row.currentCity,
      homeCountry: row.homeCountry,
      homeCity: row.homeCity,
      isPerantau: row.isPerantau,
      profileCompleted: row.profileCompleted,
      schemaVersion: row.schemaVersion,
    );
  }

  @override
  Future<void> write(PreferencesEntity p) async {
    await _db.into(_db.preferences).insertOnConflictUpdate(PreferencesCompanion(
          id: const Value(1),
          timezone: Value(p.timezone),
          baseCurrency: Value(p.baseCurrency),
          homeCurrency: Value(p.homeCurrency),
          language: Value(p.language),
          displayName: Value(p.displayName),
          status: Value(p.status),
          currentCountry: Value(p.currentCountry),
          currentCity: Value(p.currentCity),
          homeCountry: Value(p.homeCountry),
          homeCity: Value(p.homeCity),
          isPerantau: Value(p.isPerantau),
          profileCompleted: Value(p.profileCompleted),
          schemaVersion: Value(p.schemaVersion),
          // T-1: tiap tulis lokal = "dirty" sampai mirror sukses (markMirrored).
          lastSyncedAtMs: const Value<int?>(null),
        ));
  }

  @override
  Future<bool> hasPendingMirror() async {
    final row = await (_db.select(_db.preferences)..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    return row == null || row.lastSyncedAtMs == null;
  }

  @override
  Future<void> markMirrored(int atMs) async {
    await (_db.update(_db.preferences)..where((t) => t.id.equals(1)))
        .write(PreferencesCompanion(lastSyncedAtMs: Value(atMs)));
  }
}
