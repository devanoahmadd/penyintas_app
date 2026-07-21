import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/sync/firestore_op.dart';
import 'package:penyintas_app/core/sync/sync_dispatcher.dart';

AppDatabase _openTestDb() => AppDatabase(NativeDatabase.memory());

SyncQueueData _makeItem({
  required SyncOperation operation,
  String collectionPath = 'users/uid/transactions/txn1',
  Map<String, dynamic>? data,
}) {
  return SyncQueueData(
    id: 1,
    itemId: 'item-1',
    collectionPath: collectionPath,
    operation: operation,
    data: jsonEncode(data ?? {'amount': 5000, 'note': 'test'}),
    createdAt: DateTime(2026, 5, 20),
  );
}

void main() {
  late AppDatabase db;

  setUp(() => db = _openTestDb());
  tearDown(() => db.close());

  group('toFirestoreOp', () {
    test('create operation → SetOp with merge=false', () {
      final item = _makeItem(operation: SyncOperation.create);
      final op = toFirestoreOp(item);

      expect(op, isA<SetOp>());
      final setOp = op as SetOp;
      expect(setOp.merge, isFalse);
      expect(setOp.data['amount'], 5000);
    });

    test('update operation → SetOp with merge=true', () {
      final item = _makeItem(operation: SyncOperation.update);
      final op = toFirestoreOp(item);

      expect(op, isA<SetOp>());
      final setOp = op as SetOp;
      expect(setOp.merge, isTrue);
      expect(setOp.data['note'], 'test');
    });

    test('delete operation → DeleteOp', () {
      final item = _makeItem(operation: SyncOperation.delete);
      final op = toFirestoreOp(item);

      expect(op, isA<DeleteOp>());
    });

    test('path is preserved in SetOp', () {
      const path = 'users/uid123/transactions/abc';
      final item = _makeItem(
        operation: SyncOperation.create,
        collectionPath: path,
      );
      final op = toFirestoreOp(item) as SetOp;

      expect(op.path, path);
    });

    test('path is preserved in DeleteOp', () {
      const path = 'users/uid123/transactions/xyz';
      final item = _makeItem(
        operation: SyncOperation.delete,
        collectionPath: path,
      );
      final op = toFirestoreOp(item) as DeleteOp;

      expect(op.path, path);
    });

    test('invalid JSON in data field throws FormatException', () {
      final item = SyncQueueData(
        id: 2,
        itemId: 'item-2',
        collectionPath: 'users/uid/transactions/bad',
        operation: SyncOperation.create,
        data: 'NOT_VALID_JSON',
        createdAt: DateTime(2026, 5, 20),
      );

      expect(() => toFirestoreOp(item), throwsA(isA<FormatException>()));
    });

    test('path mengandung placeholder { → ArgumentError (guard #252)', () {
      final item = _makeItem(
        operation: SyncOperation.update,
        collectionPath: 'users/{uid}/budget_settings',
      );
      expect(() => toFirestoreOp(item), throwsArgumentError);
    });

    test('path collection (segmen ganjil) → ArgumentError (guard #252)', () {
      final item = _makeItem(
        operation: SyncOperation.create,
        collectionPath: 'users/uid-1/transactions',
      );
      expect(() => toFirestoreOp(item), throwsArgumentError);
    });

    test(
      'path dengan segmen kosong (trailing slash) → ArgumentError (guard #252)',
      () {
        final item = _makeItem(
          operation: SyncOperation.update,
          collectionPath: 'users/uid-1/budget_limits/',
        );
        expect(() => toFirestoreOp(item), throwsArgumentError);
      },
    );

    test('doc path penuh valid → tidak throw', () {
      final item = _makeItem(
        operation: SyncOperation.delete,
        collectionPath: 'users/uid-1/budget_limits/makan',
      );
      expect(() => toFirestoreOp(item), returnsNormally);
    });
  });
}
