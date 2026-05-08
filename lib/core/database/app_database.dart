import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

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
  RealColumn get emergencyFundPct =>
      real().withDefault(const Constant(0.10))();
  // Set once on first onboarding completion — jangan overwrite
  DateTimeColumn get onboardingCreatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Queue untuk operasi yang belum tersync ke Firestore.
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get itemId => text()();
  TextColumn get collectionPath => text()();
  TextColumn get data => text()();
  TextColumn get operation =>
      text().map(const SyncOperationConverter())();
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

  @override
  Set<Column> get primaryKey => {txId};
}

// ─── Database ──────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [AppSettings, SyncQueue, Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (m) => m.createAll());
}

QueryExecutor _openConnection() => driftDatabase(name: 'penyintas_db');
