import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';

abstract class NotificationRepository {
  Future<Either<Failure, bool>> requestPermission();
  Future<Either<Failure, void>> saveFcmToken(String uid, String token);
  Future<Either<Failure, void>> scheduleDailyReminder({
    required int hour,
    required int minute,
  });
  Future<Either<Failure, void>> cancelDailyReminder();
}
