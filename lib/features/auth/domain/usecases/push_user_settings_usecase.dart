import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/auth/domain/repositories/user_settings_repository.dart';

class PushUserSettingsUseCase extends UseCase<Unit, NoParams> {
  PushUserSettingsUseCase(this._repository);
  final UserSettingsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      _repository.pushToRemote();
}
