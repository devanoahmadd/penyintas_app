import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/transaction/data/models/transaction_model.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';

void main() {
  final tModel = TransactionModel(
    id: 'tx-1',
    amount: 850000,
    category: 'housing',
    type: TransactionType.expense,
    note: 'Bayar kos',
    date: DateTime(2026, 7, 1),
    isFixed: true,
    isSynced: false,
    createdAt: DateTime(2026, 7, 1),
    updatedAt: DateTime(2026, 7, 1),
    sourceBillId: 7,
  );

  test(
    'toFirestore TIDAK mengandung key sourceBillId (K1 — link lokal murni)',
    () {
      final map = tModel.toFirestore();
      expect(map.containsKey('sourceBillId'), isFalse);
    },
  );

  test('toDriftCompanion: sourceBillId terbawa ke companion', () {
    final c = tModel.toDriftCompanion();
    expect(c.sourceBillId, const Value(7));
  });

  test('fromDrift: sourceBillId terbaca dari row', () {
    final row = Transaction(
      txId: 'tx-2',
      amount: 50000,
      category: 'food',
      type: 'expense',
      note: null,
      date: DateTime(2026, 7, 2),
      isFixed: false,
      isSynced: false,
      syncedAt: null,
      createdAt: DateTime(2026, 7, 2),
      updatedAt: DateTime(2026, 7, 2),
      goalId: null,
      sourceBillId: 7,
    );
    final model = TransactionModel.fromDrift(row);
    expect(model.sourceBillId, 7);
  });

  test(
    'roundtrip jalur tulis: fromEntity -> toDriftCompanion -> insert DB -> fromDrift membawa sourceBillId',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final entity = TransactionEntity(
        id: 'tx-3',
        amount: 850000,
        category: 'housing',
        type: TransactionType.expense,
        date: DateTime(2026, 7, 1),
        isFixed: true,
        isSynced: false,
        createdAt: DateTime(2026, 7, 1),
        updatedAt: DateTime(2026, 7, 1),
        sourceBillId: 7,
      );

      final model = TransactionModel.fromEntity(entity);
      await db.into(db.transactions).insert(model.toDriftCompanion());

      final row = await (db.select(
        db.transactions,
      )..where((t) => t.txId.equals('tx-3'))).getSingle();
      final back = TransactionModel.fromDrift(row);

      expect(back.sourceBillId, 7);
    },
  );

  test('copyWith(isSynced: true) tidak men-drop sourceBillId', () {
    final updated = tModel.copyWith(isSynced: true);
    expect(updated.isSynced, isTrue);
    expect(updated.sourceBillId, 7);
  });
}
