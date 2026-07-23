import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/network/network_info.dart';
import 'package:penyintas_app/features/bills/data/datasources/bill_local_datasource.dart';
import 'package:penyintas_app/features/bills/data/datasources/bill_remote_datasource.dart';
import 'package:penyintas_app/features/bills/data/models/bill_model.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/domain/repositories/bill_repository.dart';

/// Local-first (pola GoalRepositoryImpl/TransactionRepositoryImpl): tulis
/// lokal dulu — sukses lokal = operasi sukses. Push remote saat online;
/// gagal/offline → SyncQueue (path doc PENUH `users/$uid/bills/$cloudId`,
/// uid di-resolve saat enqueue — BUKAN placeholder `{uid}` ala budget yang
/// tak di-resolve SyncDispatcher, lihat guard #252). Belum login → data
/// tetap lokal, tanpa queue.
///
/// Beda dari GoalRepositoryImpl: `_local.createBill` mengembalikan **int**
/// (id lokal autoincrement), BUKAN model — cloudId digenerate DI DALAM
/// BillLocalDatasource.createBill, jadi argumen `model` yang diterima
/// createBill di sini BELUM tentu bawa cloudId. WAJIB re-fetch via
/// `findById` sebelum push, atau `_pushUpsert` jadi no-op senyap dan bill
/// TAK PERNAH sync.
class BillRepositoryImpl implements BillRepository {
  BillRepositoryImpl({
    required BillLocalDatasource local,
    required BillRemoteDatasource remote,
    required NetworkInfo networkInfo,
    required FirebaseAuth auth,
  }) : _local = local,
       _remote = remote,
       _network = networkInfo,
       _auth = auth;

  final BillLocalDatasource _local;
  final BillRemoteDatasource _remote;
  final NetworkInfo _network;
  final FirebaseAuth _auth;

  // Wrapper aman-test (pola GoalRepositoryImpl._logError):
  // Crashlytics tanpa Firebase.initializeApp (unit test) tidak boleh crash.
  static void _logError(Object e, StackTrace s, String reason) {
    try {
      FirebaseCrashlytics.instance.recordError(e, s, reason: reason);
    } catch (_) {}
  }

  @override
  Stream<Either<Failure, List<BillEntity>>> watchActiveBills() => _local
      .watchActive()
      .map((list) => Right<Failure, List<BillEntity>>(list));

  @override
  Future<Either<Failure, int>> createBill(BillModel model) async {
    try {
      final id = await _local.createBill(model);
      // Re-fetch WAJIB: cloudId digenerate di dalam _local.createBill, jadi
      // `model` argumen belum tentu bawa cloudId — tanpa ini _pushUpsert
      // no-op dan tagihan tak pernah sync.
      final saved = await _local.findById(id);
      if (saved != null) {
        await _pushUpsert(saved, operation: SyncOperation.create);
      }
      return Right(id);
    } catch (e, s) {
      _logError(e, s, 'createBill');
      return Left(CacheFailure('Gagal menyimpan tagihan.'));
    }
  }

  @override
  Future<Either<Failure, void>> updateBill(BillModel model) async {
    try {
      await _local.updateBill(model);
      await _pushUpsert(model, operation: SyncOperation.update);
      return const Right(null);
    } catch (e, s) {
      _logError(e, s, 'updateBill');
      return Left(CacheFailure('Gagal memperbarui tagihan.'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBill(int id) async {
    try {
      // cloudId WAJIB diambil SEBELUM row lokal dihapus.
      final model = await _local.findById(id);
      final cloudId = model?.cloudId;
      await _local.deleteBill(id);

      final uid = _auth.currentUser?.uid;
      if (uid == null || cloudId == null || cloudId.isEmpty) {
        return const Right(null);
      }
      final path = 'users/$uid/bills/$cloudId';
      if (await _network.isConnected) {
        try {
          await _remote.deleteBill(cloudId);
        } catch (e, s) {
          _logError(e, s, 'deleteBill.push');
          await _local.addToSyncQueue(
            itemId: cloudId,
            collectionPath: path,
            data: const <String, dynamic>{},
            operation: SyncOperation.delete,
          );
        }
      } else {
        await _local.addToSyncQueue(
          itemId: cloudId,
          collectionPath: path,
          data: const <String, dynamic>{},
          operation: SyncOperation.delete,
        );
      }
      return const Right(null);
    } catch (e, s) {
      _logError(e, s, 'deleteBill');
      return Left(CacheFailure('Gagal menghapus tagihan.'));
    }
  }

  @override
  Future<Either<Failure, int>> syncBillsFromRemote() async {
    try {
      if (await _local.hasAnyBills()) return const Right(0);
      if (!await _network.isConnected) return const Right(0);

      final models = await _remote.getBills();
      if (models.isEmpty) return const Right(0);

      await _local.upsertFromRemote(models);
      return Right(models.length);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e, s) {
      _logError(e, s, 'syncBillsFromRemote');
      return Left(CacheFailure('Gagal memulihkan tagihan.'));
    }
  }

  /// Push create/update ke remote; offline atau remote gagal → SyncQueue.
  /// Belum login atau cloudId kosong → no-op (data tetap lokal, pola
  /// GoalRepositoryImpl._pushUpsert).
  Future<void> _pushUpsert(
    BillModel model, {
    required SyncOperation operation,
  }) async {
    final uid = _auth.currentUser?.uid;
    final cloudId = model.cloudId;
    if (uid == null || cloudId == null || cloudId.isEmpty) return;
    final path = 'users/$uid/bills/$cloudId';
    if (await _network.isConnected) {
      try {
        await _remote.saveBill(model);
      } catch (e, s) {
        _logError(e, s, 'pushBill');
        await _local.addToSyncQueue(
          itemId: cloudId,
          collectionPath: path,
          data: model.toFirestore(),
          operation: operation,
        );
      }
    } else {
      await _local.addToSyncQueue(
        itemId: cloudId,
        collectionPath: path,
        data: model.toFirestore(),
        operation: operation,
      );
    }
  }
}
