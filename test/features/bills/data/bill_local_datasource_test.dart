import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/bills/data/datasources/bill_local_datasource.dart';
import 'package:penyintas_app/features/bills/data/models/bill_model.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';

final _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

/// Builder model bill untuk fixture test. Semua field wajib entity diisi
/// nilai default masuk akal, dapat di-override lewat parameter.
BillModel _billModel({
  String? cloudId,
  String name = 'Kos Bu Tini',
  int estimatedAmount = 750000,
  String category = 'kos',
  bool isFixedNeed = true,
  String? notes,
  DateTime? dueDate,
  Recurrence recurrence = Recurrence.monthly,
  int? installmentTotal,
  int installmentsPaid = 0,
  DateTime? recurrenceEndDate,
  int? dueDayOfMonth,
  int? reminderDaysBefore,
  bool reminderEnabled = true,
  BillStatus status = BillStatus.active,
  DateTime? createdAt,
  DateTime? updatedAt,
}) => BillModel(
  cloudId: cloudId,
  name: name,
  estimatedAmount: estimatedAmount,
  category: category,
  isFixedNeed: isFixedNeed,
  notes: notes,
  dueDate: dueDate ?? DateTime(2026, 8, 5),
  recurrence: recurrence,
  installmentTotal: installmentTotal,
  installmentsPaid: installmentsPaid,
  recurrenceEndDate: recurrenceEndDate,
  dueDayOfMonth: dueDayOfMonth,
  reminderDaysBefore: reminderDaysBefore,
  reminderEnabled: reminderEnabled,
  status: status,
  createdAt: createdAt ?? DateTime(2026, 7, 1),
  updatedAt: updatedAt ?? DateTime(2026, 7, 1),
);

void main() {
  late AppDatabase db;
  late BillLocalDatasourceImpl ds;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    ds = BillLocalDatasourceImpl(db);
  });
  tearDown(() => db.close());

  group('createBill', () {
    test(
      '(a) insert lalu watchActive().first → 1 baris, field benar',
      () async {
        await ds.createBill(
          _billModel(name: 'Kos Bu Tini', estimatedAmount: 750000),
        );

        final rows = await ds.watchActive().first;
        expect(rows, hasLength(1));
        expect(rows.first.name, 'Kos Bu Tini');
        expect(rows.first.estimatedAmount, 750000);
        expect(rows.first.dueDate, DateTime(2026, 8, 5));
        expect(rows.first.status, BillStatus.active);
      },
    );

    test('(f) cloudId non-kosong (uuid v4) & id lokal > 0', () async {
      final id = await ds.createBill(_billModel());

      expect(id, greaterThan(0));
      final found = await ds.findById(id);
      expect(found, isNotNull);
      expect(found!.cloudId, isNotNull);
      expect(found.cloudId, isNotEmpty);
      expect(
        _uuidV4.hasMatch(found.cloudId!),
        isTrue,
        reason: 'cloudId harus UUID v4, dapat: ${found.cloudId}',
      );
    });

    test(
      'cloudId model yang sudah ada dipakai apa adanya (tidak digenerate ulang)',
      () async {
        final id = await ds.createBill(_billModel(cloudId: 'cloud-fixed-1'));
        final found = await ds.findById(id);
        expect(found!.cloudId, 'cloud-fixed-1');
      },
    );
  });

  group('watchActive', () {
    test('(b) bill status=completed TIDAK muncul di watchActive', () async {
      await ds.createBill(_billModel(name: 'Aktif', status: BillStatus.active));
      await ds.createBill(
        _billModel(name: 'Selesai', status: BillStatus.completed),
      );

      final rows = await ds.watchActive().first;
      expect(rows, hasLength(1));
      expect(rows.first.name, 'Aktif');
    });

    test(
      '(c) urut dueDate ASC — jatuh tempo lebih awal keluar duluan',
      () async {
        await ds.createBill(
          _billModel(name: 'Belakangan', dueDate: DateTime(2026, 9, 20)),
        );
        await ds.createBill(
          _billModel(name: 'Duluan', dueDate: DateTime(2026, 8, 1)),
        );

        final rows = await ds.watchActive().first;
        expect(rows, hasLength(2));
        expect(rows[0].name, 'Duluan');
        expect(rows[1].name, 'Belakangan');
      },
    );
  });

  group('findById', () {
    test('null untuk id tak dikenal', () async {
      expect(await ds.findById(999), isNull);
    });
  });

  group('updateBill', () {
    test('match by cloudId — hanya baris bersangkutan yang berubah', () async {
      final idA = await ds.createBill(_billModel(name: 'A'));
      final idB = await ds.createBill(_billModel(name: 'B'));
      final foundA = await ds.findById(idA);
      final foundB = await ds.findById(idB);

      final updatedA = _billModel(
        cloudId: foundA!.cloudId,
        name: 'A - diubah',
        estimatedAmount: foundA.estimatedAmount,
        dueDate: foundA.dueDate,
        createdAt: foundA.createdAt,
        updatedAt: foundA.updatedAt,
      );
      await ds.updateBill(updatedA);

      final refetchedA = await ds.findById(idA);
      final refetchedB = await ds.findById(idB);
      expect(refetchedA!.name, 'A - diubah');
      expect(
        refetchedB!.name,
        foundB!.name,
        reason: 'baris lain tidak boleh ikut ter-update',
      );
    });
  });

  group('deleteBill', () {
    test('menghapus baris by id lokal', () async {
      final id = await ds.createBill(_billModel());
      await ds.deleteBill(id);
      expect(await ds.findById(id), isNull);
    });
  });

  group('applyPayment / restorePayment', () {
    test(
      '(d) applyPayment mengubah 3 field; restorePayment mengembalikan persis',
      () async {
        final id = await ds.createBill(
          _billModel(
            dueDate: DateTime(2026, 8, 5),
            installmentsPaid: 2,
            status: BillStatus.active,
          ),
        );

        // Simpan nilai SEBELUM payment untuk dibandingkan setelah restore.
        final before = await ds.findById(id);
        final dueDateBefore = before!.dueDate;
        final installmentsPaidBefore = before.installmentsPaid;
        final statusBefore = before.status;

        await ds.applyPayment(
          id: id,
          newDueDate: DateTime(2026, 9, 5),
          newInstallmentsPaid: 3,
          newStatus: BillStatus.completed,
        );

        final afterPayment = await ds.findById(id);
        expect(afterPayment!.dueDate, DateTime(2026, 9, 5));
        expect(afterPayment.installmentsPaid, 3);
        expect(afterPayment.status, BillStatus.completed);

        await ds.restorePayment(
          id: id,
          dueDate: dueDateBefore,
          installmentsPaid: installmentsPaidBefore,
          status: statusBefore,
        );

        final afterRestore = await ds.findById(id);
        expect(afterRestore!.dueDate, dueDateBefore);
        expect(afterRestore.installmentsPaid, installmentsPaidBefore);
        expect(afterRestore.status, statusBefore);
      },
    );
  });

  group('upsertFromRemote', () {
    test('hydrate list remote → row lokal lengkap', () async {
      await ds.upsertFromRemote([
        _billModel(cloudId: 'cloud-1', name: 'Bill 1'),
        _billModel(cloudId: 'cloud-2', name: 'Bill 2'),
      ]);
      final rows = await db.select(db.bills).get();
      expect(rows, hasLength(2));
      expect(rows.map((r) => r.cloudId), containsAll(['cloud-1', 'cloud-2']));
      expect(rows.map((r) => r.name), containsAll(['Bill 1', 'Bill 2']));
    });

    test(
      '(e) idempoten: panggil 2x dgn cloudId sama → tetap 1 baris',
      () async {
        await ds.upsertFromRemote([_billModel(cloudId: 'cloud-dup')]);
        await ds.upsertFromRemote([_billModel(cloudId: 'cloud-dup')]);
        expect(await db.select(db.bills).get(), hasLength(1));
      },
    );

    test('model tanpa cloudId di-skip (guard)', () async {
      await ds.upsertFromRemote([_billModel(cloudId: null)]);
      expect(await db.select(db.bills).get(), isEmpty);
    });
  });

  group('addToSyncQueue', () {
    test('menulis item dengan data ter-encode JSON', () async {
      await ds.addToSyncQueue(
        itemId: 'cloud-1',
        collectionPath: 'users/u1/bills/cloud-1',
        data: {'name': 'X'},
        operation: SyncOperation.create,
      );
      final items = await db.select(db.syncQueue).get();
      expect(items, hasLength(1));
      expect(items.first.itemId, 'cloud-1');
      expect(items.first.collectionPath, 'users/u1/bills/cloud-1');
      expect(jsonDecode(items.first.data), {'name': 'X'});
      expect(items.first.operation, SyncOperation.create);
    });
  });

  group('hasAnyBills', () {
    test('false saat kosong, true setelah create', () async {
      expect(await ds.hasAnyBills(), isFalse);
      await ds.createBill(_billModel());
      expect(await ds.hasAnyBills(), isTrue);
    });
  });
}
