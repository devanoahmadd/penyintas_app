import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/notification/domain/repositories/notification_repository.dart';

class RegisterFcmTokenUseCase {
  const RegisterFcmTokenUseCase(this._repo);
  final NotificationRepository _repo;

  Future<Either<Failure, void>> call(String uid) => _repo.registerToken(uid);
}
