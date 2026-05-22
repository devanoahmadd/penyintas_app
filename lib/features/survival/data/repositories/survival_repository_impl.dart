import 'package:dartz/dartz.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:penyintas_app/features/survival/data/datasources/survival_local_datasource.dart';
import 'package:penyintas_app/features/survival/data/datasources/survival_remote_datasource.dart';
import 'package:penyintas_app/features/survival/domain/entities/survival_mode_entity.dart';
import 'package:penyintas_app/features/survival/domain/entities/survival_tip_entity.dart';
import 'package:penyintas_app/features/survival/domain/repositories/survival_repository.dart';

class SurvivalRepositoryImpl implements SurvivalRepository {
  const SurvivalRepositoryImpl({
    required SurvivalLocalDatasource local,
    required SurvivalRemoteDatasource remote,
  })  : _local = local,
        _remote = remote;

  final SurvivalLocalDatasource _local;
  final SurvivalRemoteDatasource _remote;

  @override
  Future<Either<Failure, SurvivalModeEntity>> getSurvivalMode(
      DashboardEntity dashboard) async {
    try {
      final activatedAt = await _local.getSurvivalActivatedAt();
      final isActive = dashboard.status == BudgetStatus.danger;
      final suggestedDaily = dashboard.remainingDays > 0
          ? dashboard.totalRemaining ~/ dashboard.remainingDays
          : 0;
      return Right(SurvivalModeEntity(
        isActive: isActive,
        remainingAmount: dashboard.totalRemaining,
        remainingDays: dashboard.remainingDays,
        suggestedDailyBudget: suggestedDaily,
        tips: const [],
        activatedAt: activatedAt,
      ));
    } catch (e, s) {
      FirebaseCrashlytics.instance
          .recordError(e, s, reason: 'getSurvivalMode');
      return Left(CacheFailure('Gagal memuat status survival mode.'));
    }
  }

  @override
  Future<Either<Failure, List<SurvivalTip>>> getSurvivalTips({
    required int remainingAmount,
    required int remainingDays,
    required String language,
  }) async {
    try {
      final tips = await _remote.getSurvivalTips(
        remainingAmount: remainingAmount,
        remainingDays: remainingDays,
        language: language,
      );
      return Right(tips);
    } catch (e, s) {
      FirebaseCrashlytics.instance
          .recordError(e, s, reason: 'getSurvivalTips');
      return Left(ServerFailure('Gagal mengambil tips hemat. Coba lagi.'));
    }
  }

  @override
  Future<Either<Failure, void>> recordSurvivalActivated() async {
    try {
      await _local.setSurvivalActivatedAt(DateTime.now());
      return const Right(null);
    } catch (e, s) {
      FirebaseCrashlytics.instance
          .recordError(e, s, reason: 'recordSurvivalActivated');
      return Left(CacheFailure('Gagal menyimpan timestamp aktivasi.'));
    }
  }

  @override
  Future<Either<Failure, void>> clearSurvivalActivated() async {
    try {
      await _local.clearSurvivalActivatedAt();
      return const Right(null);
    } catch (e, s) {
      FirebaseCrashlytics.instance
          .recordError(e, s, reason: 'clearSurvivalActivated');
      return Left(CacheFailure('Gagal menghapus catatan aktivasi.'));
    }
  }
}
