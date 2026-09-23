import 'package:drift/drift.dart';
import 'package:penyintas_app/core/database/app_database.dart';

/// Sakelar fitur Tantangan Mingguan.
///
/// Datasource kecil milik fitur, bukan `SettingsLocalDatasource` bersama —
/// kelas itu tidak pernah ada di repo ini. Pola yang dipakai fitur lain adalah
/// satu datasource per fitur yang hanya mengurus kolom `app_settings` miliknya
/// sendiri; `BillReminderSettingsDatasource` adalah preseden persisnya.
abstract class ChallengeSettingsDatasource {
  Future<bool> isEnabled();

  /// S-B — sakelar WAJIB reaktif. Tanpa stream ini, menyalakan sakelar di
  /// Pengaturan tidak merefresh tile maupun halaman sampai ada perubahan tabel
  /// lain yang kebetulan memicu emit.
  Stream<bool> watchEnabled();

  Future<void> setEnabled(bool value);
}

class ChallengeSettingsDatasourceImpl implements ChallengeSettingsDatasource {
  ChallengeSettingsDatasourceImpl(this._db);
  final AppDatabase _db;

  /// Baris id=1 belum tentu ada (instalasi baru, atau sesudah
  /// `clearAllLocalData`). Fitur yang MATI adalah fallback yang benar: D3
  /// menuntut sakelar tak pernah menyala tanpa user menyalakannya.
  static const bool _fallback = false;

  SimpleSelectStatement<$AppSettingsTable, AppSetting> get _baris =>
      _db.select(_db.appSettings)..where((t) => t.id.equals(1));

  @override
  Future<bool> isEnabled() async =>
      (await _baris.getSingleOrNull())?.challengeEnabled ?? _fallback;

  @override
  Stream<bool> watchEnabled() => _baris
      .watchSingleOrNull()
      .map((r) => r?.challengeEnabled ?? _fallback)
      .distinct();

  @override
  Future<void> setEnabled(bool value) => _db
      .into(_db.appSettings)
      .insertOnConflictUpdate(
        // HANYA kolom ini yang disebut: companion yang absen tidak menimpa,
        // jadi penghasilan dan seluruh setelan lain selamat.
        AppSettingsCompanion(
          id: const Value(1),
          challengeEnabled: Value(value),
        ),
      );
}
