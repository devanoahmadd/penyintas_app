import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/goal/data/datasources/goal_local_datasource.dart';
import 'package:penyintas_app/features/goal/data/models/goal_model.dart';

final _uuidV4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

GoalModel _remoteModel(String fid, {String title = 'Dari remote'}) => GoalModel(
      firestoreId: fid,
      title: title,
      targetAmount: 2000000,
      targetDate: DateTime(2026, 12, 31),
      isCompleted: false,
      createdAt: DateTime(2026, 6, 1),
      updatedAt: DateTime(2026, 6, 1),
    );

void main() {
  late AppDatabase db;
  late GoalLocalDatasourceImpl ds;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    ds = GoalLocalDatasourceImpl(db);
  });
  tearDown(() => db.close());

  group('createGoal', () {
    test('insert row + generate firestoreId UUID v4 + return model', () async {
      final model = await ds.createGoal(
        title: 'Pulang kampung',
        targetAmount: 1500000,
        targetDate: DateTime(2026, 12, 31),
      );

      expect(_uuidV4.hasMatch(model.firestoreId), isTrue,
          reason: 'firestoreId harus UUID v4, dapat: ${model.firestoreId}');
      expect(model.title, 'Pulang kampung');
      expect(model.isCompleted, isFalse);

      final rows = await db.select(db.goals).get();
      expect(rows, hasLength(1));
      expect(rows.first.firestoreId, model.firestoreId);
      expect(rows.first.title, 'Pulang kampung');
    });

    test('dua goal → firestoreId berbeda', () async {
      final a = await ds.createGoal(
          title: 'A', targetAmount: 1, targetDate: DateTime(2027));
      final b = await ds.createGoal(
          title: 'B', targetAmount: 2, targetDate: DateTime(2027));
      expect(a.firestoreId, isNot(b.firestoreId));
    });
  });

  group('findById / firestoreIdOf', () {
    test('mengembalikan model & firestoreId untuk id valid', () async {
      final created = await ds.createGoal(
          title: 'X', targetAmount: 10, targetDate: DateTime(2027));
      final row = await db.select(db.goals).getSingle();

      final found = await ds.findById(row.id);
      expect(found, isNotNull);
      expect(found!.firestoreId, created.firestoreId);
      expect(await ds.firestoreIdOf(row.id), created.firestoreId);
    });

    test('null untuk id tak dikenal', () async {
      expect(await ds.findById(999), isNull);
      expect(await ds.firestoreIdOf(999), isNull);
    });
  });

  group('hasAnyGoals', () {
    test('false saat kosong, true setelah create', () async {
      expect(await ds.hasAnyGoals(), isFalse);
      await ds.createGoal(
          title: 'X', targetAmount: 10, targetDate: DateTime(2027));
      expect(await ds.hasAnyGoals(), isTrue);
    });
  });

  group('upsertFromRemote', () {
    test('hydrate list remote → row lokal lengkap', () async {
      await ds.upsertFromRemote([
        _remoteModel('fid-1', title: 'Goal 1'),
        _remoteModel('fid-2', title: 'Goal 2'),
      ]);
      final rows = await db.select(db.goals).get();
      expect(rows, hasLength(2));
      expect(rows.map((r) => r.firestoreId), containsAll(['fid-1', 'fid-2']));
      expect(rows.map((r) => r.title), containsAll(['Goal 1', 'Goal 2']));
    });

    test('idempoten: pull ganda tidak menduplikasi', () async {
      await ds.upsertFromRemote([_remoteModel('fid-1')]);
      await ds.upsertFromRemote([_remoteModel('fid-1')]);
      expect(await db.select(db.goals).get(), hasLength(1));
    });
  });

  group('addToSyncQueue', () {
    test('menulis item dengan data ter-encode JSON', () async {
      await ds.addToSyncQueue(
        itemId: 'fid-1',
        collectionPath: 'users/u1/goals/fid-1',
        data: {'title': 'X'},
        operation: SyncOperation.create,
      );
      final items = await db.select(db.syncQueue).get();
      expect(items, hasLength(1));
      expect(items.first.itemId, 'fid-1');
      expect(items.first.collectionPath, 'users/u1/goals/fid-1');
      expect(jsonDecode(items.first.data), {'title': 'X'});
      expect(items.first.operation, SyncOperation.create);
    });
  });

  group('loadGoals (regresi perilaku existing)', () {
    // Perilaku existing: SUM amount>0 dari SEMUA transaksi ter-link — TIDAK
    // ada filter type='income' (goal_local_datasource.dart:29-36). Jangan
    // "memperbaiki" jadi filter income di sprint ini.
    //
    // Fixture SENGAJA memakai type='expense': dengan implementasi existing
    // (tanpa filter type) hasilnya tetap 250; bila kelak ada yang menambah
    // filter income, test ini gagal (0 ≠ 250) — itulah regression guard-nya.
    test('savedAmount = SUM amount positif transaksi ter-link (tanpa filter type)',
        () async {
      await ds.createGoal(
          title: 'X', targetAmount: 1000, targetDate: DateTime(2027));
      final goalRow = await db.select(db.goals).getSingle();
      await db.into(db.transactions).insert(TransactionsCompanion.insert(
            txId: 'tx-1',
            amount: 250,
            category: 'makan',
            type: 'expense',
            date: DateTime(2026, 7, 1),
            createdAt: DateTime(2026, 7, 1),
            updatedAt: DateTime(2026, 7, 1),
            goalId: Value(goalRow.id),
          ));

      final goals = await ds.loadGoals();
      expect(goals.single.savedAmount, 250);
    });
  });
}
