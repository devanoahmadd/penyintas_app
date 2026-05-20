import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/notification/domain/repositories/notification_repository.dart';

class ScheduleDailyReminderUseCase {
  const ScheduleDailyReminderUseCase(this._repo);
  final NotificationRepository _repo;

  Future<Either<Failure, void>> call({required int hour, required int minute}) =>
      _repo.scheduleDailyReminder(hour: hour, minute: minute);
}
