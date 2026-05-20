import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/notification/domain/repositories/notification_repository.dart';

class CancelDailyReminderUseCase {
  const CancelDailyReminderUseCase(this._repo);
  final NotificationRepository _repo;

  Future<Either<Failure, void>> call() => _repo.cancelDailyReminder();
}
