import 'package:drift/drift.dart';
import 'package:penyintas_app/core/database/app_database.dart';

abstract class SurvivalLocalDatasource {
  Future<DateTime?> getSurvivalActivatedAt();
  Future<void> setSurvivalActivatedAt(DateTime value);
  Future<void> clearSurvivalActivatedAt();
}

class SurvivalLocalDatasourceImpl implements SurvivalLocalDatasource {
  const SurvivalLocalDatasourceImpl(this._db);
  final AppDatabase _db;

  @override
  Future<DateTime?> getSurvivalActivatedAt() async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((s) => s.id.equals(1))).getSingleOrNull();
    return row?.survivalModeActivatedAt;
  }

  @override
  Future<void> setSurvivalActivatedAt(DateTime value) async {
    await (_db.update(_db.appSettings)..where((s) => s.id.equals(1))).write(
      AppSettingsCompanion(survivalModeActivatedAt: Value(value)),
    );
  }

  @override
  Future<void> clearSurvivalActivatedAt() async {
    await (_db.update(_db.appSettings)..where((s) => s.id.equals(1))).write(
      const AppSettingsCompanion(survivalModeActivatedAt: Value(null)),
    );
  }
}
