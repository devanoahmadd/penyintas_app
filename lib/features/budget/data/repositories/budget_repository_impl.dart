import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/network/network_info.dart';
import 'package:penyintas_app/features/budget/data/datasources/budget_local_datasource.dart';
import 'package:penyintas_app/features/budget/data/datasources/budget_remote_datasource.dart';
import 'package:penyintas_app/features/budget/data/models/budget_limit_model.dart';
import 'package:penyintas_app/features/budget/data/models/budget_settings_model.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_limit_entity.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';
import 'package:penyintas_app/features/budget/domain/repositories/budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl({
    required BudgetLocalDatasource local,
    required BudgetRemoteDatasource remote,
    required NetworkInfo networkInfo,
    required FirebaseAuth auth,
  }) : _local = local,
       _remote = remote,
       _network = networkInfo,
       _auth = auth;

  final BudgetLocalDatasource _local;
  final BudgetRemoteDatasource _remote;
  final NetworkInfo _network;
  final FirebaseAuth _auth;

  @override
  Future<Either<Failure, BudgetSettingsEntity>> getBudgetSettings() async {
    try {
      final settings = await _local.getBudgetSettings();
      if (settings == null) {
        return const Left(CacheFailure('Pengaturan anggaran belum diisi.'));
      }
      return Right(settings);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveBudgetSettings(
    BudgetSettingsEntity settings,
  ) async {
    try {
      await _local.saveBudgetSettings(settings);
      final model = BudgetSettingsModel.fromEntity(settings);
      if (await _network.isConnected) {
        await _remote.saveBudgetSettings(model);
      } else {
        // #252: doc path penuh ter-resolve — pola transaksi/goal.
        final uid = _auth.currentUser?.uid;
        if (uid != null) {
          await _local.addToSyncQueue(
            itemId: 'budget_settings_current',
            collectionPath: 'users/$uid/budget_settings/current',
            data: model.toFirestore(),
            operation: SyncOperation.update,
          );
        }
      }
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BudgetLimitEntity>>> getBudgetLimits() async {
    try {
      final limits = await _local.getBudgetLimits();
      return Right(limits);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> saveBudgetLimit(BudgetLimitEntity limit) async {
    try {
      final savedId = await _local.saveBudgetLimit(limit);
      final savedEntity = limit.copyWith(id: savedId);
      final model = BudgetLimitModel.fromEntity(savedEntity);
      if (await _network.isConnected) {
        await _remote.saveBudgetLimit(model);
      } else {
        final uid = _auth.currentUser?.uid;
        if (uid != null) {
          await _local.addToSyncQueue(
            itemId: 'budget_limit_${limit.category}',
            collectionPath: 'users/$uid/budget_limits/${limit.category}',
            data: model.toFirestore(),
            operation: SyncOperation.update,
          );
        }
      }
      return Right(savedId);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBudgetLimit(
    int id,
    String categoryName,
  ) async {
    try {
      await _local.deleteBudgetLimit(id);
      if (await _network.isConnected) {
        await _remote.deleteBudgetLimit(categoryName);
      } else {
        final uid = _auth.currentUser?.uid;
        if (uid != null) {
          await _local.addToSyncQueue(
            itemId: 'budget_limit_$categoryName',
            collectionPath: 'users/$uid/budget_limits/$categoryName',
            data: const <String, dynamic>{},
            operation: SyncOperation.delete,
          );
        }
      }
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BudgetSettingsEntity?>> syncBudgetFromRemote() async {
    try {
      final localData = await _local.getBudgetSettings();
      if (localData != null) return Right(localData);

      if (await _network.isConnected) {
        final remoteData = await _remote.getBudgetSettings();
        if (remoteData != null) await _local.saveBudgetSettings(remoteData);
        return Right(remoteData);
      }
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
