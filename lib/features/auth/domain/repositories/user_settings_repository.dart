import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';

abstract class UserSettingsRepository {
  Future<Either<Failure, Unit>> wipeLocalData();

  /// Pull identity settings dari Firestore lalu rekonsiliasi:
  /// - remote ada      → tulis ke lokal
  /// - remote null +
  ///   lokal completed → push lokal ke remote (self-heal push gagal)
  /// - remote null +
  ///   lokal belum     → no-op (user baru)
  /// Non-blocking: timeout/offline/error tetap return Right(unit).
  Future<Either<Failure, Unit>> syncFromRemote();

  Future<Either<Failure, Unit>> pushToRemote();
}
