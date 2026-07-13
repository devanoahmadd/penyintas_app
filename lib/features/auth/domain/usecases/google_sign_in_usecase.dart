import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/auth/domain/entities/user_entity.dart';
import 'package:penyintas_app/features/auth/domain/repositories/auth_repository.dart';

class GoogleSignInUseCase extends UseCase<UserEntity?, NoParams> {
  GoogleSignInUseCase(this._repository);
  final AuthRepository _repository;

  /// Right(null) = user membatalkan dialog — caller emit Unauthenticated.
  @override
  Future<Either<Failure, UserEntity?>> call(NoParams params) =>
      _repository.signInWithGoogle();
}
