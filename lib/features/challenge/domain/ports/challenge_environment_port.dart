import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_environment.dart';

/// Satu bacaan, tiga gerbang (S2). Sengaja sesempit ini: tanpa port, domain
/// bergantung pada `DashboardEntity` milik fitur lain, dan setiap test harus
/// memalsukan seluruh dashboard demi dua boolean.
abstract class ChallengeEnvironmentPort {
  Future<Either<Failure, ChallengeEnvironment>> read();
}
