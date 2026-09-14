import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/challenge/domain/challenge_constants.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_environment.dart';
import 'package:penyintas_app/features/challenge/domain/ports/challenge_environment_port.dart';
import 'package:penyintas_app/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:penyintas_app/features/survival/domain/usecases/get_survival_mode_usecase.dart';

/// SATU-SATUNYA berkas di `lib/features/challenge/` yang boleh kenal fitur
/// dashboard. Tanpa port ini, domain challenge harus bergantung langsung
/// pada `DashboardEntity` milik fitur lain, dan setiap test di fitur ini
/// harus memalsukan seluruh dashboard demi dua boolean (S2).
class ChallengeEnvironmentPortImpl implements ChallengeEnvironmentPort {
  ChallengeEnvironmentPortImpl({
    required DashboardRepository dashboardRepo,
    required GetSurvivalModeUseCase getSurvivalMode,
  }) : _dashboardRepo = dashboardRepo,
       _getSurvivalMode = getSurvivalMode;

  final DashboardRepository _dashboardRepo;
  final GetSurvivalModeUseCase _getSurvivalMode;

  @override
  Future<Either<Failure, ChallengeEnvironment>> read() async {
    try {
      final either = await _dashboardRepo
          .watchDashboard()
          .first
          .timeout(kEnvReadTimeout);

      // KEDUA cabang `async`. Mencampur cabang sinkron dan Future dalam satu
      // `fold` membuat tipe hasilnya tak menyatu dan berkas ini tidak compile.
      return either.fold((f) async => Left(f), (dash) async {
        // survivalActive TIDAK dihitung ulang di sini — dipinjam dari usecase
        // yang sudah jadi definisi tunggal Survival Mode di repo ini.
        final survival = await _getSurvivalMode(dash);
        return survival.map(
          (s) => ChallengeEnvironment(
            // Field ini BERISI nilai ter-clamp:
            // dashboard_repository_impl.dart:297 mengisinya dengan
            // safeMonthlyBudget. Jadi `> 0` = anggaran sudah diatur.
            budgetConfigured: dash.totalMonthlyBudget > 0,
            survivalActive: s.isActive,
          ),
        );
      });
    } on TimeoutException {
      return Left(CacheFailure('Lingkungan tantangan tak terbaca.'));
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'challengeEnv.read',
      );
      return Left(CacheFailure('Lingkungan tantangan tak terbaca.'));
    }
  }
}
