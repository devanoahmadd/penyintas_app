import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/network/network_info.dart';
import 'package:penyintas_app/features/onboarding/data/datasources/onboarding_local_datasource.dart';
import 'package:penyintas_app/features/onboarding/data/datasources/onboarding_remote_datasource.dart';
import 'package:penyintas_app/features/onboarding/domain/entities/budget_settings_entity.dart';
import 'package:penyintas_app/features/onboarding/domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
    required this.auth,
  });

  final OnboardingLocalDataSource localDataSource;
  final OnboardingRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final FirebaseAuth auth;

  @override
  Future<Either<Failure, void>> saveBudgetSettings(
    BudgetSettingsEntity settings,
  ) async {
    try {
      // Lokal dulu — dipakai router untuk cek onboardingCompleted
      await localDataSource.saveBudgetSettings(settings);

      final uid = auth.currentUser?.uid;
      if (uid == null) return const Right(null);

      final syncData = {
        'monthlyIncome': settings.monthlyIncome,
        'paymentDate': settings.paymentDate,
        'fixedExpenses': settings.fixedExpenses,
        'emergencyFundPct': settings.emergencyFundPct,
        'createdAt': settings.createdAt.toIso8601String(),
        'onboardingCompleted': true,
      };

      if (await networkInfo.isConnected) {
        try {
          await remoteDataSource.saveBudgetSettings(settings);
        } catch (_) {
          // Firestore gagal — antre untuk sync ulang saat online
          await localDataSource.addToSyncQueue(
            itemId: 'budget_settings_$uid',
            collectionPath: 'users/$uid/budget_settings/current',
            data: syncData,
          );
        }
      } else {
        // Offline — antre untuk sync saat koneksi kembali
        await localDataSource.addToSyncQueue(
          itemId: 'budget_settings_$uid',
          collectionPath: 'users/$uid/budget_settings/current',
          data: syncData,
        );
      }

      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, BudgetSettingsEntity?>> getBudgetSettings() async {
    try {
      final settings = await localDataSource.getBudgetSettings();
      return Right(settings);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
