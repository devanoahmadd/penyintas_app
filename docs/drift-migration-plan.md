# Drift Migration Plan
## Penyintas App · Isar 3.x → Drift 2.x

> **Status:** ✅ Selesai — 2026-05-08
> **Estimasi:** 1 sesi penuh (~5–6 jam)
> **Tujuan:** Hapus konflik `isar_generator` ↔ `bloc_test` secara permanen, aktifkan built-in schema migration.

---

## Mengapa Sekarang

| Alasan | Detail |
|--------|--------|
| **Konflik build_runner hilang** | `drift_dev ^2.x` kompatibel dengan `analyzer ^6.x` — sama dengan `bloc_test ^10`. Tidak perlu swap `pubspec.yaml` lagi |
| **Schema masih kecil** | 3 tabel, belum ada user data nyata. Biaya migrasi paling murah di titik ini |
| **Enum safe rename** | Isar menyimpan enum sebagai integer index; rename enum value = data korup. Drift menyimpan sebagai string (`.name`) |
| **Built-in migration** | Phase 5+ akan butuh schema change (`retryCount`, pisah `AppSettings`). Drift punya `MigrationStrategy`; Isar 3 tidak |

---

## Scope Perubahan

### File dihapus
```
lib/core/local/app_settings_isar_model.dart
lib/core/local/app_settings_isar_model.g.dart
lib/core/local/sync_queue_isar_model.dart
lib/core/local/sync_queue_isar_model.g.dart
lib/features/transaction/data/models/transaction_isar_model.dart
lib/features/transaction/data/models/transaction_isar_model.g.dart
```

### File dibuat (baru)
```
lib/core/database/app_database.dart         ← @DriftDatabase + semua Table class + TypeConverter
lib/core/database/app_database.g.dart       ← generated (build_runner)
```

### File dimodifikasi
```
pubspec.yaml
lib/main.dart
lib/core/di/injection_container.dart
lib/core/routing/app_router.dart
lib/features/settings/presentation/bloc/settings_bloc.dart
lib/features/onboarding/data/datasources/onboarding_local_datasource.dart
lib/features/transaction/data/datasources/transaction_local_datasource.dart
lib/features/transaction/data/models/transaction_model.dart
lib/core/sync/sync_service.dart
```

---

## Bagian 1 — pubspec.yaml

### Hapus
```yaml
  isar: ^3.1.0
  isar_flutter_libs: ^3.1.0
```
```yaml
  # isar_generator: ^3.1.0   ← sudah dicomment, hapus sekalian
```

### Tambah
```yaml
dependencies:
  drift: ^2.21.0
  drift_flutter: ^0.2.1        # SQLite integration + path setup otomatis

dev_dependencies:
  drift_dev: ^2.21.0           # code generator — tidak konflik dengan bloc_test
```

> `path_provider` tetap dipertahankan (dipakai tempat lain). `build_runner` sudah ada.
> Setelah migrasi: `dart run build_runner build` bisa dijalankan kapan saja tanpa swap pubspec.

---

## Bagian 2 — Schema Baru (`lib/core/database/app_database.dart`)

File ini menggantikan ketiga model Isar dan menjadi single source of truth untuk local DB.

```dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

// ─── Enum ─────────────────────────────────────────────────────────────────────

enum SyncOperation { create, update, delete }

// ─── Type Converters ──────────────────────────────────────────────────────────

class SyncOperationConverter extends TypeConverter<SyncOperation, String> {
  const SyncOperationConverter();
  @override
  SyncOperation fromSql(String s) => SyncOperation.values.byName(s);
  @override
  String toSql(SyncOperation v) => v.name;
}

// ─── Tables ───────────────────────────────────────────────────────────────────

/// Singleton (id selalu = 1). Gabungan preferences + budget settings.
/// Kandidat untuk dipecah di Phase 6 (issue #17).
class AppSettings extends Table {
  IntColumn get id => integer()();
  TextColumn get locale =>
      text().withDefault(const Constant('id'))();
  TextColumn get themeMode =>
      text().withDefault(const Constant('system'))();
  BoolColumn get onboardingCompleted =>
      boolean().withDefault(const Constant(false))();
  IntColumn get monthlyIncome =>
      integer().withDefault(const Constant(0))();
  IntColumn get paymentDate =>
      integer().withDefault(const Constant(1))();
  IntColumn get fixedExpenses =>
      integer().withDefault(const Constant(0))();
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
  TextColumn get data => text()(); // JSON string
  TextColumn get operation =>
      text().map(const SyncOperationConverter())();
  DateTimeColumn get createdAt => dateTime()();
}

/// Tabel transaksi. UUID sebagai primary key langsung (tidak perlu integer id).
class Transactions extends Table {
  TextColumn get txId => text()();
  IntColumn get amount => integer()();
  TextColumn get category => text()(); // stored as enum.name
  TextColumn get type => text()();    // stored as enum.name
  TextColumn get note => text().nullable()();
  DateTimeColumn get date => dateTime()();
  BoolColumn get isFixed =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {txId};
}

// ─── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [AppSettings, SyncQueue, Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  // Migration strategy — diisi saat schema version naik
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
      );
}

QueryExecutor _openConnection() =>
    driftDatabase(name: 'penyintas_db');
```

> **Catatan enum storage:** Category dan type transaksi disimpan sebagai `.name` string.
> Konversi dilakukan di `TransactionModel.fromDrift()` / `toDriftCompanion()`.

---

## Bagian 3 — `TransactionModel` (update method)

Hapus `fromIsar()` dan `toIsar()`. Tambah `fromDrift()` dan `toDriftCompanion()`.

```dart
// HAPUS:
// factory TransactionModel.fromIsar(TransactionIsarModel m) { ... }
// TransactionIsarModel toIsar() { ... }

// TAMBAH:
factory TransactionModel.fromDrift(Transaction row) {
  return TransactionModel(
    id: row.txId,
    amount: row.amount,
    category: TransactionCategory.values.byName(row.category),
    type: TransactionType.values.byName(row.type),
    note: row.note,
    date: row.date,
    isFixed: row.isFixed,
    isSynced: row.isSynced,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

TransactionsCompanion toDriftCompanion() {
  return TransactionsCompanion(
    txId: Value(id),
    amount: Value(amount),
    category: Value(category.name),
    type: Value(type.name),
    note: Value(note),
    date: Value(date),
    isFixed: Value(isFixed),
    isSynced: Value(isSynced),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
  );
}
```

> Import `TransactionModel` juga berubah: hapus `transaction_isar_model.dart`,
> tambah `app_database.dart`.

---

## Bagian 4 — `TransactionLocalDataSource` (full rewrite)

```dart
import 'package:drift/drift.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/transaction/data/models/transaction_model.dart';

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  TransactionLocalDataSourceImpl(this._db);
  final AppDatabase _db;

  @override
  Future<void> saveTransaction(TransactionModel model) =>
      _db.into(_db.transactions).insertOnConflictUpdate(model.toDriftCompanion());

  @override
  Future<void> updateTransaction(TransactionModel model) =>
      _db.into(_db.transactions).insertOnConflictUpdate(model.toDriftCompanion());

  @override
  Future<void> deleteTransaction(String txId) =>
      (_db.delete(_db.transactions)..where((t) => t.txId.equals(txId))).go();

  @override
  Future<List<TransactionModel>> getTodayTransactions() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    final rows = await (_db.select(_db.transactions)
          ..where((t) => t.date.isBiggerOrEqualValue(start) & t.date.isSmallerOrEqualValue(end))
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .get();
    return rows.map(TransactionModel.fromDrift).toList();
  }

  @override
  Future<List<TransactionModel>> getTransactionsByDateRange(DateTime from, DateTime to) async {
    final rows = await (_db.select(_db.transactions)
          ..where((t) => t.date.isBiggerOrEqualValue(from) & t.date.isSmallerOrEqualValue(to))
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .get();
    return rows.map(TransactionModel.fromDrift).toList();
  }

  /// Drift reactive query — jauh lebih bersih dari Isar watchLazy pattern.
  @override
  Stream<List<TransactionModel>> watchTodayTransactions() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return (_db.select(_db.transactions)
          ..where((t) => t.date.isBiggerOrEqualValue(start) & t.date.isSmallerOrEqualValue(end))
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .watch()
        .map((rows) => rows.map(TransactionModel.fromDrift).toList());
  }

  @override
  Future<void> markSynced(String txId) async {
    await (_db.update(_db.transactions)..where((t) => t.txId.equals(txId)))
        .write(TransactionsCompanion(
          isSynced: const Value(true),
          syncedAt: Value(DateTime.now()),
        ));
  }

  @override
  Future<List<TransactionModel>> getUnsyncedTransactions() async {
    final rows = await (_db.select(_db.transactions)
          ..where((t) => t.isSynced.equals(false)))
        .get();
    return rows.map(TransactionModel.fromDrift).toList();
  }

  @override
  Future<void> addToSyncQueue({
    required String itemId,
    required String collectionPath,
    required Map<String, dynamic> data,
    required SyncOperation operation,
  }) =>
      _db.into(_db.syncQueue).insert(SyncQueueCompanion(
            itemId: Value(itemId),
            collectionPath: Value(collectionPath),
            data: Value(jsonEncode(data)),
            operation: Value(operation),
            createdAt: Value(DateTime.now()),
          ));
}
```

---

## Bagian 5 — `OnboardingLocalDataSource` (update)

```dart
// SEBELUM: final Isar _isar;
// SESUDAH:
final AppDatabase _db;

// saveBudgetSettings():
// SEBELUM:
final existing = await _isar.appSettingsIsarModels.get(1);
final model = AppSettingsIsarModel()
  ..id = 1
  ..locale = existing?.locale ?? 'id'
  // ...
await _isar.writeTxn(() => _isar.appSettingsIsarModels.put(model));

// SESUDAH:
final existing = await (_db.select(_db.appSettings)
    ..where((t) => t.id.equals(1))).getSingleOrNull();
await _db.into(_db.appSettings).insertOnConflictUpdate(AppSettingsCompanion(
  id: const Value(1),
  locale: Value(existing?.locale ?? 'id'),
  themeMode: Value(existing?.themeMode ?? 'system'),
  onboardingCompleted: const Value(true),
  monthlyIncome: Value(settings.monthlyIncome),
  paymentDate: Value(settings.paymentDate),
  fixedExpenses: Value(settings.fixedExpenses),
  emergencyFundPct: Value(settings.emergencyFundPct),
  onboardingCreatedAt: Value(existing?.onboardingCreatedAt ?? settings.createdAt),
));

// getBudgetSettings():
// SEBELUM:
final saved = await _isar.appSettingsIsarModels.get(1);

// SESUDAH:
final saved = await (_db.select(_db.appSettings)
    ..where((t) => t.id.equals(1))).getSingleOrNull();

// addToSyncQueue():
// SEBELUM:
final item = SyncQueueIsarModel()..itemId = itemId ...
await _isar.writeTxn(() => _isar.syncQueueIsarModels.put(item));

// SESUDAH:
await _db.into(_db.syncQueue).insert(SyncQueueCompanion(
  itemId: Value(itemId),
  collectionPath: Value(collectionPath),
  data: Value(jsonEncode(data)),
  operation: Value(existing?.onboardingCompleted == true
      ? SyncOperation.update
      : SyncOperation.create),
  createdAt: Value(DateTime.now()),
));
```

---

## Bagian 6 — `SettingsBloc` (update)

```dart
// SEBELUM:
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc(this._isar) ...
  final Isar _isar;

// SESUDAH:
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc(this._db) ...
  final AppDatabase _db;

// _onLoaded():
// SEBELUM:
final saved = await _isar.appSettingsIsarModels.get(1);

// SESUDAH:
final saved = await (_db.select(_db.appSettings)
    ..where((t) => t.id.equals(1))).getSingleOrNull();

// _persist():
// SEBELUM:
final existing = await _isar.appSettingsIsarModels.get(1);
final model = AppSettingsIsarModel()..id = 1 ...
await _isar.writeTxn(() => _isar.appSettingsIsarModels.put(model));

// SESUDAH:
final existing = await (_db.select(_db.appSettings)
    ..where((t) => t.id.equals(1))).getSingleOrNull();
await _db.into(_db.appSettings).insertOnConflictUpdate(AppSettingsCompanion(
  id: const Value(1),
  themeMode: Value(AppSettingsEntity.themeModeToString(s.themeMode)),
  locale: Value(s.locale),
  onboardingCompleted: Value(existing?.onboardingCompleted ?? false),
  monthlyIncome: Value(existing?.monthlyIncome ?? 0),
  paymentDate: Value(existing?.paymentDate ?? 1),
  fixedExpenses: Value(existing?.fixedExpenses ?? 0),
  emergencyFundPct: Value(existing?.emergencyFundPct ?? 0.10),
  onboardingCreatedAt: Value(existing?.onboardingCreatedAt),
));
```

---

## Bagian 7 — `SyncService` (update)

```dart
// SEBELUM:
class SyncService {
  SyncService({required Isar isar, ...}) : _isar = isar, ...
  final Isar _isar;

// SESUDAH:
class SyncService {
  SyncService({required AppDatabase db, ...}) : _db = db, ...
  final AppDatabase _db;

// _processQueue():
// SEBELUM:
final items = await _isar.syncQueueIsarModels
    .where().sortByCreatedAt().findAll();
// ...
await _isar.writeTxn(() => _isar.syncQueueIsarModels.delete(item.id));

// SESUDAH:
final items = await (_db.select(_db.syncQueue)
    ..orderBy([(t) => OrderingTerm(expression: t.createdAt)])).get();
// ...
await (_db.delete(_db.syncQueue)..where((t) => t.id.equals(item.id))).go();
```

> Import: hapus `package:isar/isar.dart` dan `sync_queue_isar_model.dart`.
> Tambah `package:penyintas_app/core/database/app_database.dart`.

---

## Bagian 8 — `app_router.dart` (update)

```dart
// SEBELUM:
final isar = sl<Isar>();
final settings = await isar.appSettingsIsarModels.get(1);
final onboardingDone = settings?.onboardingCompleted ?? false;

// SESUDAH:
final db = sl<AppDatabase>();
final settings = await (db.select(db.appSettings)
    ..where((t) => t.id.equals(1))).getSingleOrNull();
final onboardingDone = settings?.onboardingCompleted ?? false;
```

---

## Bagian 9 — `main.dart` (update)

```dart
// HAPUS:
import 'package:isar/isar.dart';
import 'package:penyintas_app/core/local/app_settings_isar_model.dart';
import 'package:penyintas_app/core/local/sync_queue_isar_model.dart';
import 'package:penyintas_app/features/transaction/data/models/transaction_isar_model.dart';

// TAMBAH:
import 'package:penyintas_app/core/database/app_database.dart';

// SEBELUM (di dalam main()):
try {
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [TransactionIsarModelSchema, AppSettingsIsarModelSchema, SyncQueueIsarModelSchema],
    directory: dir.path,
  );
  await di.init(isar: isar);
  // ...
}

// SESUDAH:
try {
  final db = AppDatabase();          // driftDatabase() sudah handle path via drift_flutter
  await di.init(db: db);
  // ...
}
```

> `getApplicationDocumentsDirectory()` dan `path_provider` tidak lagi dibutuhkan
> di `main.dart` (drift_flutter menangani path secara internal).
> Hapus import `path_provider` dari `main.dart` jika tidak dipakai di tempat lain.

---

## Bagian 10 — `injection_container.dart` (update)

```dart
// SEBELUM:
Future<void> init({required Isar isar}) async {
  _registerExternal(isar);
  ...
}

void _registerExternal(Isar isar) {
  sl.registerLazySingleton<Isar>(() => isar);
  ...
}

// SESUDAH:
Future<void> init({required AppDatabase db}) async {
  _registerExternal(db);
  ...
}

void _registerExternal(AppDatabase db) {
  sl.registerLazySingleton<AppDatabase>(() => db);
  // Firebase, Connectivity tetap sama
  ...
}

// SettingsBloc — ganti Isar → AppDatabase:
void _registerSettings() {
  sl.registerFactory(() => SettingsBloc(sl<AppDatabase>()));
}
```

Semua tempat yang sebelumnya `sl<Isar>()` ganti ke `sl<AppDatabase>()`.

---

## Bagian 11 — Perubahan Import di Setiap File

| File | Hapus | Tambah |
|------|-------|--------|
| `settings_bloc.dart` | `isar/isar.dart`, `app_settings_isar_model.dart` | `app_database.dart` |
| `onboarding_local_datasource.dart` | `isar/isar.dart`, `app_settings_isar_model.dart`, `sync_queue_isar_model.dart` | `app_database.dart` |
| `transaction_local_datasource.dart` | `isar/isar.dart`, `sync_queue_isar_model.dart`, `transaction_isar_model.dart` | `app_database.dart`, `drift/drift.dart` |
| `transaction_model.dart` | `transaction_isar_model.dart` | `app_database.dart` |
| `sync_service.dart` | `isar/isar.dart`, `sync_queue_isar_model.dart` | `app_database.dart` |
| `app_router.dart` | `isar/isar.dart`, `app_settings_isar_model.dart` | `app_database.dart` |
| `injection_container.dart` | `isar/isar.dart` | `app_database.dart` |
| `main.dart` | `isar/isar.dart`, `*_isar_model.dart` x3 | `app_database.dart` |

---

## Bagian 12 — Testing: Perubahan yang Diperlukan

### Mock di test files
```dart
// SEBELUM:
class MockIsar extends Mock implements Isar {}

// SESUDAH: Drift punya in-memory database untuk testing
import 'package:drift/native.dart';

AppDatabase openTestDb() => AppDatabase(NativeDatabase.memory());
```

**Keuntungan besar:** Tidak perlu mock Isar yang kompleks. Drift `NativeDatabase.memory()` membuat SQLite in-memory yang fully functional — test bisa menulis dan membaca data nyata tanpa mock.

### File test yang perlu diupdate
```
test/features/transaction/data/repositories/transaction_repository_impl_test.dart
  → Mock TransactionLocalDataSource tetap sama (interface tidak berubah)
  → Hanya perlu hapus import Isar

test/features/onboarding/data/repositories/onboarding_repository_impl_test.dart
  → Sama — mock datasource interface, bukan DB langsung
```

### Test baru yang bisa dibuat setelah migrasi (issue #32)
```
test/core/sync/sync_dispatcher_test.dart    ← mock Firestore, test 3 operations
test/core/sync/sync_service_test.dart       ← pakai NativeDatabase.memory()
test/features/onboarding/data/datasources/onboarding_local_datasource_test.dart
test/features/transaction/data/datasources/transaction_local_datasource_test.dart
```
> Test datasource sekarang bisa ditulis tanpa mock Isar yang kompleks — ini langsung menyelesaikan issue #32.

---

## Bagian 13 — Urutan Kerja

```
Step 1 — pubspec.yaml
  ├── Hapus isar, isar_flutter_libs, isar_generator (sudah dicomment)
  ├── Tambah drift, drift_flutter, drift_dev
  └── flutter pub get

Step 2 — Buat lib/core/database/app_database.dart
  ├── Definisi 3 Table class (AppSettings, SyncQueue, Transactions)
  ├── SyncOperation enum + SyncOperationConverter
  └── AppDatabase class

Step 3 — Regenerasi
  └── dart run build_runner build
      (tidak perlu swap pubspec — drift_dev kompatibel dengan bloc_test)

Step 4 — Update TransactionModel
  ├── Hapus fromIsar() + toIsar()
  └── Tambah fromDrift() + toDriftCompanion()

Step 5 — Update semua datasource (3 file)
  ├── transaction_local_datasource.dart
  ├── onboarding_local_datasource.dart
  └── (sync queue ada di kedua datasource atas)

Step 6 — Update SettingsBloc
  └── Isar → AppDatabase, semua query

Step 7 — Update SyncService
  └── Isar → AppDatabase, queue query

Step 8 — Update infrastructure
  ├── injection_container.dart — Isar → AppDatabase
  ├── app_router.dart — query settings
  └── main.dart — Isar.open() → AppDatabase()

Step 9 — Hapus file Isar lama
  └── rm lib/core/local/*_isar_model.dart + *.g.dart
      rm lib/features/transaction/data/models/transaction_isar_model.dart + .g.dart

Step 10 — flutter analyze
  └── Target: 0 issues

Step 11 — flutter test
  └── Target: 56/56 pass (tidak ada test yang harus ditulis ulang — interface tidak berubah)

Step 12 — Tambah datasource test (bonus, menyelesaikan issue #32)
  ├── sync_service_test.dart
  └── onboarding_local_datasource_test.dart
```

---

## Bagian 14 — Kriteria Selesai

**Wajib sebelum lanjut ke Phase 5:**
- [x] `flutter pub get` sukses tanpa error konflik
- [x] `dart run build_runner build` berjalan langsung (tanpa swap pubspec)
- [x] `lib/core/database/app_database.dart` + `.g.dart` ada dan valid
- [x] Semua file Isar lama dihapus
- [x] `flutter analyze` → 0 issues
- [x] `flutter test` → 70/70 passed (56 lama + 14 baru)
- [ ] App bisa launch di emulator/device (data fresh — tidak ada migrasi dari Isar)

**Bonus (menyelesaikan issue #32):**
- [x] `test/core/sync/sync_service_test.dart` — queue processing + mutex (7 tests)
- [x] `test/features/onboarding/data/datasources/onboarding_local_datasource_test.dart` (7 tests)

---

## Catatan Migrasi Data

**Tidak diperlukan.** Aplikasi masih dalam tahap development, belum ada user data nyata.
Saat pertama launch setelah migrasi, `AppDatabase` akan membuat database SQLite baru dari nol.
Data Isar lama (`penyintas.isar`) tetap ada di device tapi tidak dibaca — bisa diabaikan.

Jika di masa depan dibutuhkan: tambah `onUpgrade` di `MigrationStrategy` dengan `schemaVersion` dinaikkan.

---

*Dokumen ini adalah planning untuk migrasi Isar → Drift sebelum Phase 5.*
*Setelah migrasi selesai, update status di sini dan di PROMPT.md.*
