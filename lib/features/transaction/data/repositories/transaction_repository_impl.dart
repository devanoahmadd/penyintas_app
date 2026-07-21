import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/network/network_info.dart';
import 'package:penyintas_app/features/transaction/data/datasources/transaction_local_datasource.dart';
import 'package:penyintas_app/features/transaction/data/datasources/transaction_remote_datasource.dart';
import 'package:penyintas_app/features/transaction/data/models/transaction_model.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl({
    required TransactionLocalDataSource localDataSource,
    required TransactionRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
    required FirebaseAuth auth,
  }) : _local = localDataSource,
       _remote = remoteDataSource,
       _networkInfo = networkInfo,
       _auth = auth;

  final TransactionLocalDataSource _local;
  final TransactionRemoteDataSource _remote;
  final NetworkInfo _networkInfo;
  final FirebaseAuth _auth;

  static void _logError(Object e, StackTrace stack) {
    try {
      FirebaseCrashlytics.instance.recordError(e, stack);
    } catch (_) {}
  }

  @override
  Future<Either<Failure, void>> addTransaction(
    TransactionEntity transaction,
  ) async {
    try {
      final model = TransactionModel.fromEntity(transaction);
      await _local.saveTransaction(model);

      final uid = _auth.currentUser?.uid;
      if (uid == null) return const Right(null);

      final syncData = model.toFirestore();
      final path = 'users/$uid/transactions/${model.id}';

      if (await _networkInfo.isConnected) {
        try {
          await _remote.saveTransaction(model);
          await _local.markSynced(model.id);
        } catch (e, stack) {
          _logError(e, stack);
          await _local.addToSyncQueue(
            itemId: model.id,
            collectionPath: path,
            data: syncData,
            operation: SyncOperation.create,
          );
        }
      } else {
        await _local.addToSyncQueue(
          itemId: model.id,
          collectionPath: path,
          data: syncData,
          operation: SyncOperation.create,
        );
      }

      return const Right(null);
    } catch (e, stack) {
      _logError(e, stack);
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateTransaction(
    TransactionEntity transaction,
  ) async {
    try {
      final model = TransactionModel.fromEntity(transaction);
      await _local.updateTransaction(model);

      final uid = _auth.currentUser?.uid;
      if (uid == null) return const Right(null);

      final path = 'users/$uid/transactions/${model.id}';

      if (await _networkInfo.isConnected) {
        try {
          await _remote.updateTransaction(model);
          await _local.markSynced(model.id);
        } catch (e, stack) {
          _logError(e, stack);
          await _local.addToSyncQueue(
            itemId: model.id,
            collectionPath: path,
            data: model.toFirestore(),
            operation: SyncOperation.update,
          );
        }
      } else {
        await _local.addToSyncQueue(
          itemId: model.id,
          collectionPath: path,
          data: model.toFirestore(),
          operation: SyncOperation.update,
        );
      }

      return const Right(null);
    } catch (e, stack) {
      _logError(e, stack);
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteTransaction(String id) async {
    try {
      await _local.deleteTransaction(id);

      final uid = _auth.currentUser?.uid;
      if (uid == null) return const Right(null);

      final path = 'users/$uid/transactions/$id';

      if (await _networkInfo.isConnected) {
        try {
          await _remote.deleteTransaction(id);
        } catch (e, stack) {
          _logError(e, stack);
          await _local.addToSyncQueue(
            itemId: id,
            collectionPath: path,
            data: {},
            operation: SyncOperation.delete,
          );
        }
      } else {
        await _local.addToSyncQueue(
          itemId: id,
          collectionPath: path,
          data: {},
          operation: SyncOperation.delete,
        );
      }

      return const Right(null);
    } catch (e, stack) {
      _logError(e, stack);
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    required DateTime from,
    required DateTime to,
    String? categoryFilter,
  }) async {
    try {
      var models = await _local.getTransactionsByDateRange(from, to);
      if (categoryFilter != null) {
        models = models.where((m) => m.category == categoryFilter).toList();
      }
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e, stack) {
      _logError(e, stack);
      return const Left(CacheFailure());
    }
  }

  @override
  Stream<Either<Failure, List<TransactionEntity>>> watchTodayTransactions() {
    return _local.watchTodayTransactions().map(
      (models) => Right<Failure, List<TransactionEntity>>(
        models.map((m) => m.toEntity()).toList(),
      ),
    );
  }

  @override
  Stream<void> watchTransactionChanges() => _local.watchTransactionChanges();
}
