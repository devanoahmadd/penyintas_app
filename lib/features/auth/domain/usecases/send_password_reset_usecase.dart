import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/auth/domain/repositories/auth_repository.dart';

class SendPasswordResetUseCase extends UseCase<void, SendPasswordResetParams> {
  SendPasswordResetUseCase(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, void>> call(SendPasswordResetParams params) =>
      _repository.sendPasswordResetEmail(params.email);
}

class SendPasswordResetParams extends Equatable {
  const SendPasswordResetParams({required this.email});
  final String email;

  @override
  List<Object> get props => [email];
}
