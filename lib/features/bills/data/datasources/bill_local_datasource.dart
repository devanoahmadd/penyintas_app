import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/bills/data/models/bill_model.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:uuid/uuid.dart';

abstract class BillLocalDatasource {
  /// Stream bill aktif, terurut jatuh tempo terdekat dulu. Dipakai UI list
  /// & pengingat — F6: STREAM (bukan one-shot) supaya UI auto-update saat
  /// bill dibayar/dihapus/ditambah.
  Stream<List<BillEntity>> watchActive();

  /// Snapshot row → model untuk push remote (null bila id tak dikenal).
  Future<BillModel?> findById(int id);

  /// Ambil satu bill sebagai **entity domain** by id lokal (null bila tak
  /// dikenal). Beda dari [findById] yang mengembalikan BillModel tanpa id
  /// lokal — dipakai orkestrasi "tandai lunas" yang butuh id + progres.
  Future<BillEntity?> findEntityById(int id);

  /// Insert bill baru + generate UUID v4 sebagai cloudId bila model belum
  /// membawa satu. Return id lokal autoincrement — dipakai jadwal notif.
  Future<int> createBill(BillModel model);

  /// Update baris existing, dicocokkan **by cloudId** (BillModel tidak
  /// membawa id lokal). WAJIB dipanggil hanya untuk model yang cloudId-nya
  /// sudah terisi (mis. hasil createBill/findById).
  Future<void> updateBill(BillModel model);

  Future<void> deleteBill(int id);

  /// Mutasi pasca pembayaran (roll-forward): update dueDate + progres
  /// cicilan + status sekaligus.
  Future<void> applyPayment({
    required int id,
    required DateTime newDueDate,
    required int newInstallmentsPaid,
    required BillStatus newStatus,
  });

  /// Undo applyPayment — tulis balik nilai persis sebelum payment.
  Future<void> restorePayment({
    required int id,
    required DateTime dueDate,
    required int installmentsPaid,
    required BillStatus status,
  });

  /// Hydrate dari remote — idempoten by cloudId (skip yang sudah ada).
  Future<void> upsertFromRemote(List<BillModel> models);

  Future<void> addToSyncQueue({
    required String itemId,
    required String collectionPath,
    required Map<String, dynamic> data,
    required SyncOperation operation,
  });

  Future<bool> hasAnyBills();
}

class BillLocalDatasourceImpl implements BillLocalDatasource {
  BillLocalDatasourceImpl(this._db);
  final AppDatabase _db;

  static const _uuid = Uuid();

  /// Map baris Drift → entity domain. Tak bisa lewat BillModel karena
  /// BillModel sengaja tidak membawa `id` lokal (identitas lintas-device
  /// satu-satunya adalah cloudId).
  BillEntity _rowToEntity(Bill row) => BillEntity(
    id: row.id,
    cloudId: row.cloudId,
    name: row.name,
    estimatedAmount: row.estimatedAmount,
    category: row.category,
    isFixedNeed: row.isFixedNeed,
    notes: row.notes,
    dueDate: row.dueDate,
    recurrence: Recurrence.values.byName(row.recurrence),
    installmentTotal: row.installmentTotal,
    installmentsPaid: row.installmentsPaid,
    recurrenceEndDate: row.recurrenceEndDate,
    dueDayOfMonth: row.dueDayOfMonth,
    reminderDaysBefore: row.reminderDaysBefore,
    reminderEnabled: row.reminderEnabled,
    status: BillStatus.values.byName(row.status),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  @override
  Stream<List<BillEntity>> watchActive() =>
      (_db.select(_db.bills)
            ..where((b) => b.status.equals(BillStatus.active.name))
            ..orderBy([
              (b) =>
                  OrderingTerm(expression: b.dueDate, mode: OrderingMode.asc),
            ]))
          .watch()
          .map((rows) => rows.map(_rowToEntity).toList());

  @override
  Future<BillModel?> findById(int id) async {
    final row = await (_db.select(
      _db.bills,
    )..where((b) => b.id.equals(id))).getSingleOrNull();
    return row == null ? null : BillModel.fromRow(row);
  }

  @override
  Future<BillEntity?> findEntityById(int id) async {
    final row = await (_db.select(
      _db.bills,
    )..where((b) => b.id.equals(id))).getSingleOrNull();
    return row == null ? null : _rowToEntity(row);
  }

  @override
  Future<int> createBill(BillModel model) {
    final cloudId = model.cloudId ?? _uuid.v4();
    return _db
        .into(_db.bills)
        .insert(model.toCompanion().copyWith(cloudId: Value(cloudId)));
  }

  @override
  Future<void> updateBill(BillModel model) => (_db.update(
    _db.bills,
  )..where((b) => b.cloudId.equals(model.cloudId!))).write(model.toCompanion());

  @override
  Future<void> deleteBill(int id) =>
      (_db.delete(_db.bills)..where((b) => b.id.equals(id))).go();

  @override
  Future<void> applyPayment({
    required int id,
    required DateTime newDueDate,
    required int newInstallmentsPaid,
    required BillStatus newStatus,
  }) => (_db.update(_db.bills)..where((b) => b.id.equals(id))).write(
    BillsCompanion(
      dueDate: Value(newDueDate),
      installmentsPaid: Value(newInstallmentsPaid),
      status: Value(newStatus.name),
      updatedAt: Value(DateTime.now()),
    ),
  );

  @override
  Future<void> restorePayment({
    required int id,
    required DateTime dueDate,
    required int installmentsPaid,
    required BillStatus status,
  }) => (_db.update(_db.bills)..where((b) => b.id.equals(id))).write(
    BillsCompanion(
      dueDate: Value(dueDate),
      installmentsPaid: Value(installmentsPaid),
      status: Value(status.name),
      updatedAt: Value(DateTime.now()),
    ),
  );

  @override
  Future<void> upsertFromRemote(List<BillModel> models) async {
    await _db.transaction(() async {
      for (final model in models) {
        if (model.cloudId == null) continue;
        final existing = await (_db.select(
          _db.bills,
        )..where((b) => b.cloudId.equals(model.cloudId!))).getSingleOrNull();
        if (existing == null) {
          await _db.into(_db.bills).insert(model.toCompanion());
        }
      }
    });
  }

  @override
  Future<void> addToSyncQueue({
    required String itemId,
    required String collectionPath,
    required Map<String, dynamic> data,
    required SyncOperation operation,
  }) async {
    await _db
        .into(_db.syncQueue)
        .insert(
          SyncQueueCompanion(
            itemId: Value(itemId),
            collectionPath: Value(collectionPath),
            data: Value(jsonEncode(data)),
            operation: Value(operation),
            createdAt: Value(DateTime.now()),
          ),
        );
  }

  @override
  Future<bool> hasAnyBills() async {
    final row = await (_db.select(_db.bills)..limit(1)).getSingleOrNull();
    return row != null;
  }
}
