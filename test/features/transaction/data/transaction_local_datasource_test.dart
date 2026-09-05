import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/transaction/data/datasources/transaction_local_datasource.dart';
import 'package:penyintas_app/features/transaction/data/models/transaction_model.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';

void main() {
  late AppDatabase db;
  late TransactionLocalDataSourceImpl datasource;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    datasource = TransactionLocalDataSourceImpl(db);
  });

  tearDown(() => db.close());

  group('getBySourceBillId', () {
    test('mengembalikan hanya transaksi dengan sourceBillId cocok', () async {
      // Arrange: Buat 2 transaksi — satu dengan sourceBillId=9, satu tanpa
      final tx1 = TransactionModel(
        id: 'tx-1',
        amount: 50000,
        category: 'food',
        type: TransactionType.expense,
        date: DateTime(2026, 5, 8),
        isFixed: false,
        isSynced: false,
        createdAt: DateTime(2026, 5, 8),
        updatedAt: DateTime(2026, 5, 8),
        sourceBillId: 9,
      );
      final tx2 = TransactionModel(
        id: 'tx-2',
        amount: 100000,
        category: 'transport',
        type: TransactionType.expense,
        date: DateTime(2026, 5, 9),
        isFixed: false,
        isSynced: false,
        createdAt: DateTime(2026, 5, 9),
        updatedAt: DateTime(2026, 5, 9),
        sourceBillId: null,
      );

      await datasource.saveTransaction(tx1);
      await datasource.saveTransaction(tx2);

      // Act
      final result = await datasource.getBySourceBillId(9);

      // Assert
      expect(result, hasLength(1));
      expect(result.first.id, equals('tx-1'));
      expect(result.first.sourceBillId, equals(9));
    });

    test(
      'mengembalikan list kosong jika tidak ada matching sourceBillId',
      () async {
        // Arrange
        final tx1 = TransactionModel(
          id: 'tx-1',
          amount: 50000,
          category: 'food',
          type: TransactionType.expense,
          date: DateTime(2026, 5, 8),
          isFixed: false,
          isSynced: false,
          createdAt: DateTime(2026, 5, 8),
          updatedAt: DateTime(2026, 5, 8),
          sourceBillId: 5,
        );
        await datasource.saveTransaction(tx1);

        // Act
        final result = await datasource.getBySourceBillId(9);

        // Assert
        expect(result, isEmpty);
      },
    );
  });

  group('deleteBySourceBillId', () {
    test('menghapus hanya transaksi dengan sourceBillId cocok', () async {
      // Arrange: Buat 2 transaksi
      final tx1 = TransactionModel(
        id: 'tx-1',
        amount: 50000,
        category: 'food',
        type: TransactionType.expense,
        date: DateTime(2026, 5, 8),
        isFixed: false,
        isSynced: false,
        createdAt: DateTime(2026, 5, 8),
        updatedAt: DateTime(2026, 5, 8),
        sourceBillId: 9,
      );
      final tx2 = TransactionModel(
        id: 'tx-2',
        amount: 100000,
        category: 'transport',
        type: TransactionType.expense,
        date: DateTime(2026, 5, 9),
        isFixed: false,
        isSynced: false,
        createdAt: DateTime(2026, 5, 9),
        updatedAt: DateTime(2026, 5, 9),
        sourceBillId: null,
      );

      await datasource.saveTransaction(tx1);
      await datasource.saveTransaction(tx2);

      // Verifikasi awal: 2 transaksi ada
      final beforeDelete = await (db.select(db.transactions).get());
      expect(beforeDelete, hasLength(2));

      // Act: Hapus transaksi dengan sourceBillId=9
      await datasource.deleteBySourceBillId(9);

      // Assert: Hanya 1 transaksi tersisa (yang sourceBillId==null)
      final afterDelete = await (db.select(db.transactions).get());
      expect(afterDelete, hasLength(1));
      expect(afterDelete.first.txId, equals('tx-2'));
    });

    test(
      'tidak menghapus apa pun jika tidak ada matching sourceBillId',
      () async {
        // Arrange
        final tx1 = TransactionModel(
          id: 'tx-1',
          amount: 50000,
          category: 'food',
          type: TransactionType.expense,
          date: DateTime(2026, 5, 8),
          isFixed: false,
          isSynced: false,
          createdAt: DateTime(2026, 5, 8),
          updatedAt: DateTime(2026, 5, 8),
          sourceBillId: 5,
        );
        await datasource.saveTransaction(tx1);

        // Act
        await datasource.deleteBySourceBillId(9);

        // Assert: Transaksi asli tetap ada
        final result = await (db.select(db.transactions).get());
        expect(result, hasLength(1));
        expect(result.first.txId, equals('tx-1'));
      },
    );
  });
}
